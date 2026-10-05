# CS 422 Assignment 2: iPerf, TCP Statistics, and Congestion Control

A from-scratch Python iperf3 client (it never calls the `iperf3` binary). It traces `TCP_INFO` on the live data socket and runs the whole experiment pipeline: destination selection, CUBIC/Reno/BBR runs, raw logs, summary tables, and PDF plots.

Dependencies: Python ≥ 3.8, `numpy`, `matplotlib`. Linux only, because `TCP_INFO` and `TCP_CONGESTION` are Linux socket options.

## Quick start

```bash
# 1. Export the list from https://iperf3serverlist.net/ to servers.csv
#    (columns: IP/HOST, PORT, GB/S, CONTINENT, COUNTRY, SITE, PROVIDER; comma or tab separated)

# 2. Make sure the three algorithms are available on the host kernel
sudo modprobe tcp_bbr
cat /proc/sys/net/ipv4/tcp_available_congestion_control     # should list reno cubic bbr

# 3a. Native
pip install -r requirements.txt
sudo python3 run_experiments.py --servers servers.csv -n 10 -t 60 -i 0.2 -r 3

# 3b. Docker (FROM ubuntu:24.04)
docker build -t cs422-iperf .
mkdir -p data && cp servers.csv data/
docker run --rm --network host --cap-add NET_ADMIN -v "$PWD/data:/data" cs422-iperf \
    --servers /data/servers.csv --out /data/results -n 10 -t 60 -i 0.2 -r 3
```

**Why `sudo` / `--cap-add NET_ADMIN`:** an unprivileged process may only select algorithms listed in `net.ipv4.tcp_allowed_congestion_control`, which by default is just `reno cubic`. Choosing `bbr` with `setsockopt(TCP_CONGESTION)` needs `CAP_NET_ADMIN`. The other way to allow it is `sudo sysctl -w net.ipv4.tcp_allowed_congestion_control="reno cubic bbr"` on the host. The script runs a preflight check and stops with a clear message if any requested algorithm can't be selected. `--network host` isn't required, but it keeps the container's TCP stack and path identical to the host's.

The full default experiment is 10 destinations × 3 algorithms × 3 reps × 60 s, which takes about 1.7 h. For a smoke test, use `-n 3 -t 15 -r 1`.

To regenerate tables and plots from saved data without measuring again:

```bash
python3 run_experiments.py --plot-only results/<run-dir> [--rep-dest HOST] [--warmup 2]
```

## Command-line options

| Option | Default | Meaning |
|---|---|---|
| `--servers FILE` | (required) | Server list file (addresses and ports) |
| `-n, --num-dests` | 10 | Number of random destinations |
| `-t, --duration` | 60 | Transfer duration per run, in seconds |
| `-i, --interval` | 0.2 | Sampling interval for goodput and TCP_INFO, in seconds |
| `-r, --reps` | 3 | Repetitions per destination × algorithm |
| `-a, --algorithms` | `cubic,reno,bbr` | Algorithms to compare |
| `-o, --out` | `results/<timestamp>` | Output directory |
| `--seed` | random (recorded) | Seed for destination selection, for reproducibility |
| `--continent`, `--country` | – | Filter the server list |
| `--ipv4-only` | off | Skip IPv6 servers and addresses |
| `--max-attempts` | 3·n | Maximum servers tried while selecting destinations |
| `--probe-duration` | 3 | Length of the validation test during selection |
| `--ports-per-server` | 3 | Ports of a server's range to try when one is busy or refused |
| `--run-retries` | 2 | Extra attempts for a run that fails with a retryable error |
| `--retry-backoff` | 10 | Base backoff between retries (linear, plus random jitter) |
| `--pause` | 2 | Pause between consecutive tests |
| `--connect-timeout` / `--ctrl-timeout` / `--stall-timeout` | 5 / 15 / 15 | Robustness timeouts, in seconds |
| `--rep-dest` | auto | Force the representative destination used for the Q2/Q3 plots |
| `--warmup` | 0 | Exclude the first N seconds of each run from summary statistics and scatter plots |
| `--plot-only DIR` | – | Re-analyse an existing results directory |

## Where each requirement is implemented

| Requirement | Code |
|---|---|
| Q1(a)(i) control connection, cookie | `iperf3_client.py`: `Iperf3Client.run` (steps 1–2), `make_cookie` |
| Q1(a)(ii) JSON parameter exchange | `Iperf3Client.run` steps 3–4, `_send_json`, `_recv_json` |
| Q1(a)(iii) data connection | `Iperf3Client.run` step 5, `_connect` (CC is set before `connect()`) |
| Q1(a)(iv) continuous sending for a set duration | `Iperf3Client._transfer` |
| Q1(a)(v) iperf3 termination | `Iperf3Client.run` step 8 (TEST_END → EXCHANGE_RESULTS → results JSON → DISPLAY_RESULTS → IPERF_DONE), `_client_results`, `_abort` |
| Robustness (busy, rejection, timeouts, early close) | `Iperf3Error`, `RETRYABLE`, `_read_state`, `_check_ctrl_during_test`, stall detection in `_transfer` |
| Q1(b) random destinations, replacements, shortfall | `run_experiments.py`: `select_destinations`, `run_on_server` |
| Q1(c) goodput from Δbytes_acked / Δt | `Iperf3Client._sample` |
| Q1(c) plots and summary table | `analysis.py`: `plot_goodput_all`, `build_tables` |
| Q2(a) TCP_INFO decoding | `tcp_info.py`: `decode_tcp_info`, `_FIELDS` |
| Q2(b) time series and scatter plots | `analysis.py`: `plot_timeseries`, `plot_scatter`, `make_plots` |
| Q3(a) CUBIC/Reno/BBR comparison | `run_experiments.py`: `run_experiments`; `analysis.py`: `make_plots`, `plot_regimes`, `build_tables` |

## Protocol (reverse-engineered from iperf3 `src/iperf_api.c` / `iperf.h`)

```
client → server  connect TCP control socket; send 37-byte cookie (36 chars of [a-z2-7] + NUL)
server → client  1 byte state PARAM_EXCHANGE(9)       [busy server: ACCESS_DENIED(-1)]
client → server  4-byte big-endian length + JSON {"tcp":true,"time":T,"parallel":1,"len":131072,...}
server → client  CREATE_STREAMS(10)                   [rejection: SERVER_ERROR(-2) + int32 i_errno + int32 errno]
client → server  connect data socket to the SAME resolved address; send the same cookie
server → client  TEST_START(1), TEST_RUNNING(2)
client → server  bulk data for T seconds (data socket)
client → server  TEST_END(4)
server → client  EXCHANGE_RESULTS(13)
client → server  results JSON (cpu_util_*, sender_has_retransmits, streams[{id:1, bytes, retransmits, ...}])
server → client  server results JSON (includes the bytes the server received)
server → client  DISPLAY_RESULTS(14)
client → server  IPERF_DONE(16), close
```

On any failure after the control connection opens, the client sends `CLIENT_TERMINATE(12)`. That releases the public server right away instead of leaving it "busy" until its own timeout. The client deliberately does **not** send the `congestion` parameter. A stock server would apply it to its *receiving* socket and fail if its kernel lacks that algorithm, and only the sender's algorithm matters here. For each run, `runs.jsonl` stores the server's results JSON, the bytes it received, and the full state trace. Comparing `server_rx_MB` with `client_acked_MB` in `run_summary.csv` cross-checks the goodput measurement.

Failure kinds: `busy`, `connect_timeout`, `connect_refused`, `connect_error`, `dns`, `ctrl_timeout`, `premature_close`, `stall`, `server_error`, `server_terminate`, `param_rejected`, `protocol`, `cc_unavailable`. The `RETRYABLE` table decides whether a run is retried with backoff or a candidate is simply replaced. Every attempt during selection is logged in `selection_log.csv`. If fewer than `n` servers can be validated within `--max-attempts`, the shortfall goes into `metadata.json` and is printed.

## TCP_INFO decoding and measurement method

* `getsockopt(IPPROTO_TCP, TCP_INFO, 512)` on the **data** socket. The kernel returns `min(512, sizeof(struct tcp_info))` bytes (`tcp_info_len_B` records how many). Fields are decoded at fixed offsets from `include/uapi/linux/tcp.h` in host byte order. A field is decoded only if the returned buffer contains it, so older kernels just produce empty columns. The full field/offset/type table goes into `metadata.json → tcp_info_format`.
* `getsockopt(TCP_CONGESTION)` reads back the algorithm **actually used** on the data socket. It's recorded as `algorithm_actual` in every row and every table.
* Sampling: a single-threaded `select()` loop sends non-blocking 128 KiB writes and wakes at each sampling deadline. Sample 0 is a baseline taken right before the first write. Each row stores a monotonic timestamp `t_s`, and every interval quantity divides by the **measured** `dt_s` between two `getsockopt()` calls, not by the nominal interval.
* **Goodput:** `goodput_bps = (bytes_acked[k] − bytes_acked[k−1]) · 8 / (t[k] − t[k−1])`, using `tcpi_bytes_acked` (cumulative bytes cumulatively ACKed, RFC 4898 `HCThruOctetsAcked`).
* **Loss proxy:** `d_retrans_seg = Δ tcpi_total_retrans`, the segments retransmitted during the interval (fast retransmit and RTO). Also logged: `bytes_retrans_B` (giving the retransmission ratio `retrans_rate_pct = bytes_retrans / bytes_sent`), `lost_seg` (currently presumed lost), `total_rto` (RTO count, kernel ≥ 6.7), and `ca_state` (0 Open, 1 Disorder, 2 CWR, 3 Recovery, 4 Loss).
* **Other logged fields:** `snd_cwnd_seg` (segments; `cwnd_B = snd_cwnd × snd_mss`), `snd_ssthresh_seg` (2147483647 means "not yet set"), `srtt_us`, `rttvar_us`, `min_rtt_us`, `rto_us`, `pacing_rate_Bps`, `delivery_rate_Bps` (the kernel's per-ACK delivery-rate estimate), `bytes_sent_B`, `notsent_bytes_B`, `busy_time_us`, `rwnd_limited_us`, `sndbuf_limited_us`, and `snd_wnd_B`. A trailing `_us`/`_B`/`_Bps`/`_seg` in a column name gives its unit.
* **BDP estimate** (`run_summary`): `max(delivery_rate) × min_rtt`. `cwnd_over_bdp` compares the mean congestion window with it; a value above 1 means the window is building a standing queue.

## Outputs

```
results/<timestamp>/
  metadata.json            host kernel, default/available/allowed CC, args, seed, decoding table, destinations
  selection_log.csv        every candidate tried during selection, with outcome and error
  destinations.csv         the n chosen servers (address, port, location, provider)
  test_order.csv           exact order of all runs (seq, rep, destination, algorithm, attempts, status)
  runs.jsonl               one record per run: status, errors, actual CC, server results JSON, state trace
  samples/<run_id>.csv     raw per-interval measurements (run_id = r<rep>_d<dest>_<algorithm>)
  tables/goodput_summary.{csv,md}       Q1(c): min / median / mean / p95 goodput per destination × algorithm
  tables/run_summary.{csv,md}           per run: goodput, min/mean/p95 RTT, RTT inflation, cwnd, retrans %, BDP
  tables/algorithm_comparison.{csv,md}  Q3(a): mean ± std over repetitions, best-throughput / lowest-RTT algorithm
  plots/q1_goodput_timeseries.pdf       goodput over time, every destination (rows) × algorithm (columns), all reps
  plots/q2_timeseries_cubic.pdf         Q2(b)(i): cwnd, RTT, loss proxy, goodput (representative destination)
  plots/q2_scatter_cubic.pdf            Q2(b)(ii): cwnd / RTT / retransmits vs goodput
  plots/q2_{timeseries,scatter}_{reno,bbr}.pdf   the same figures for each algorithm (Q3a), same axes
  plots/q3_timeseries_compare.pdf       algorithms side by side, shared axes
  plots/q3_timeseries_overlay.pdf       algorithms overlaid on the same panels
  plots/q3_scatter_compare.pdf          scatter grid, metric × algorithm, shared axes
  plots/q3_regimes.pdf                  per-destination throughput/RTT across runs, goodput vs min RTT, goodput vs loss
```

**Representative destination:** chosen automatically as the destination with the most usable runs for *every* algorithm. Ties go to the most typical one (median goodput closest to the median across destinations). Override it with `--rep-dest`. The time-series plots use the first repetition in which all algorithms succeeded. The scatter plots pool every repetition.

**Experimental design (Q3):** every destination is tested with every algorithm in every repetition. The algorithm order rotates by `(rep + destination index)` so no algorithm always goes first, which reduces time-of-day and order bias. `test_order.csv` records the order, and the repetition count is in `metadata.json`. Partial or failed runs are saved but left out of the tables and plots.

Partial runs end with status `failed`, and they keep their samples. A run whose transfer finished but whose final results exchange failed gets status `incomplete_termination`. Its measurements are valid, so it is used.

## Reproducibility notes

* Record the host kernel (`uname -r`, saved in `metadata.json`). TCP behaviour and the available `TCP_INFO` fields depend on the host kernel even inside Docker, because containers share the host kernel.
* Supported hosts are Ubuntu 22.04+ or Windows WSL2. On WSL2, check `cat /proc/sys/net/ipv4/tcp_available_congestion_control`; most WSL2 kernels have BBR built in.
* Public servers often allow only one test at a time, and many rate-limit. That's why the defaults include retries, port fallback, and a pause between tests.
