### Q3(b) Gentle Reno vs Reno (fluid simulation)

| scenario | algorithm | utilization_pct | mean_qdelay_ms | loss_pct | packets_lost | throughput_split_mbps | jain_index |
|---|---|---|---|---|---|---|---|
| 1 flow, buffer 0.10 x BDP, 50 Mbit/s, 40 ms | reno | 82.00 | 0.45 | 0.07 |  |  |  |
| 1 flow, buffer 0.25 x BDP, 50 Mbit/s, 40 ms | reno | 89.72 | 2.32 | 0.04 |  |  |  |
| 1 flow, buffer 0.43 x BDP, 50 Mbit/s, 40 ms | reno | 95.12 | 6.18 | 0.01 |  |  |  |
| 1 flow, buffer 0.50 x BDP, 50 Mbit/s, 40 ms | reno | 96.66 | 8.10 | 0.20 |  |  |  |
| 1 flow, buffer 1.00 x BDP, 50 Mbit/s, 40 ms | reno | 100.00 | 22.25 | 0.07 |  |  |  |
| 1 flow, buffer 2.00 x BDP, 50 Mbit/s, 40 ms | reno | 100.00 | 51.96 | 0.32 |  |  |  |
| 1 flow, buffer 0.10 x BDP, 50 Mbit/s, 40 ms | gentle-reno | 92.66 | 0.73 | 0.01 |  |  |  |
| 1 flow, buffer 0.25 x BDP, 50 Mbit/s, 40 ms | gentle-reno | 98.38 | 3.84 | 0.01 |  |  |  |
| 1 flow, buffer 0.43 x BDP, 50 Mbit/s, 40 ms | gentle-reno | 100.00 | 9.25 | 0.01 |  |  |  |
| 1 flow, buffer 0.50 x BDP, 50 Mbit/s, 40 ms | gentle-reno | 100.00 | 11.79 | 0.00 |  |  |  |
| 1 flow, buffer 1.00 x BDP, 50 Mbit/s, 40 ms | gentle-reno | 100.00 | 29.02 | 0.00 |  |  |  |
| 1 flow, buffer 2.00 x BDP, 50 Mbit/s, 40 ms | gentle-reno | 100.00 | 55.96 | 0.00 |  |  |  |
| startup (first 10 s), 1 flow, buffer 1 x BDP | reno |  |  |  | 172.02 |  |  |
| startup (first 10 s), 1 flow, buffer 1 x BDP | gentle-reno |  |  |  | 0.00 |  |  |
| 2 gentle-reno flows, 2nd joins at 10 s (40-60 s) | gentle-reno |  |  |  |  | 25.0 / 25.0 | 1.00 |
| gentle-reno vs reno, same path (20-60 s) | gentle-reno / reno |  |  |  |  | 24.6 / 25.4 | 1.00 |
