### Algorithm comparison: mean (std) over repetitions of per-run means

| destination | cubic_runs | cubic_goodput_mbps | cubic_goodput_std | cubic_srtt_ms | cubic_srtt_std | cubic_retrans_pct | reno_runs | reno_goodput_mbps | reno_goodput_std | reno_srtt_ms | reno_srtt_std | reno_retrans_pct | bbr_runs | bbr_goodput_mbps | bbr_goodput_std | bbr_srtt_ms | bbr_srtt_std | bbr_retrans_pct | best_goodput | lowest_rtt |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| speedtest.ams1.nl.leaseweb.net:5205 | 1 | 59.77 | 0.00 | 109.24 | 0.00 | 0.00 | 1 | 84.55 | 0.00 | 105.30 | 0.00 | 1.75 | 1 | 128.59 | 0.00 | 121.47 | 0.00 | 8.22 | bbr | reno |
| ping.online.net:5206 | 1 | 141.37 | 0.00 | 109.28 | 0.00 | 1.52 | 1 | 82.85 | 0.00 | 105.41 | 0.00 | 1.87 | 1 | 131.09 | 0.00 | 122.43 | 0.00 | 7.53 | cubic | reno |
| speedtest.netone.nl:5201 | 1 | 115.75 | 0.00 | 107.60 | 0.00 | 2.24 | 1 | 147.74 | 0.00 | 107.35 | 0.00 | 0.83 | 1 | 135.76 | 0.00 | 123.94 | 0.00 | 4.15 | reno | reno |
| ALL | 3 | 105.63 | 34.07 | 108.71 | 0.78 | 1.25 | 3 | 105.05 | 30.19 | 106.02 | 0.94 | 1.49 | 3 | 131.81 | 2.97 | 122.61 | 1.02 | 6.63 | bbr | reno |
