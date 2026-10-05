FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive PYTHONUNBUFFERED=1 MPLBACKEND=Agg
RUN apt-get update \
 && apt-get install -y --no-install-recommends python3 python3-numpy python3-matplotlib ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY tcp_info.py iperf3_client.py servers.py analysis.py run_experiments.py /app/

# Results and the server list are exchanged through /data (bind-mount it).
VOLUME ["/data"]
ENTRYPOINT ["python3", "/app/run_experiments.py"]
CMD ["--servers", "/data/servers.csv", "--out", "/data/results"]
