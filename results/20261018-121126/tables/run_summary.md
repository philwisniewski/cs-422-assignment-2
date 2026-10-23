### Per-run summary

| run_id | rep | destination | algorithm | algorithm_actual | status | duration_s | samples | goodput_mean_mbps | goodput_median_mbps | goodput_p95_mbps | min_rtt_ms | srtt_mean_ms | srtt_p95_ms | rtt_inflation_ms | cwnd_mean_seg | cwnd_mean_kB | retrans_total_seg | retrans_rate_pct | bdp_est_kB | cwnd_over_bdp | server_rx_MB | client_acked_MB |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| r01_d01_cubic | 1 | 154.81.51.4:5201 | cubic | cubic | ok | 60.00 | 300 | 62.74 | 64.68 | 90.77 | 232.95 | 238.32 | 248.50 | 5.37 | 1402.47 | 1918.58 | 2847.00 | 0.82 | 2866.60 | 0.67 | 472.35 | 470.57 |
| r01_d01_reno | 1 | 154.81.51.4:5201 | reno | reno | ok | 60.00 | 300 | 30.32 | 30.57 | 38.19 | 233.29 | 237.85 | 243.73 | 4.56 | 678.30 | 927.91 | 1616.00 | 0.96 | 2543.57 | 0.36 | 228.45 | 227.40 |
| r01_d01_bbr | 1 | 154.81.51.4:5201 | bbr | bbr | ok | 60.00 | 300 | 82.92 | 86.71 | 113.63 | 233.72 | 245.38 | 261.91 | 11.66 | 4886.05 | 6684.11 | 3402.00 | 0.74 | 3114.22 | 2.15 | 624.42 | 621.90 |
