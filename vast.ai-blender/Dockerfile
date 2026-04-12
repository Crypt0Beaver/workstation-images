FROM ghcr.io/yourusername/vast-gpu-base:latest

# Setup the Sync Script and Systemd Service
COPY sync_data.sh /usr/local/bin/sync_data.sh
COPY vast-sync.service /etc/systemd/system/vast-sync.service

RUN chmod +x /usr/local/bin/sync_data.sh \
    && systemctl enable vast-sync.service

RUN mkdir -p /workspace
