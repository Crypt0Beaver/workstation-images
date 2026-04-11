# Start from your preferred Vast.ai KVM image
FROM docker.io/vastai/kvm:ubuntu_desktop_24.04-2025-11-24

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# 1. Update and Install Tools
RUN apt-get update && apt-get install -y \
    blender \
    prusaslicer \
    nvtop \
    htop \
    rclone \
    wget \
    && apt-get clean

# 2. Create a workspace directory
RUN mkdir -p /root/cloud_sync

# 3. Add the Sync Script
COPY sync_script.sh /usr/local/bin/sync_data.sh
RUN chmod +x /usr/local/bin/sync_data.sh

# 4. Optional: Setup a cron job or systemd service to sync every 10 mins
RUN echo "*/10 * * * * root /usr/local/bin/sync_data.sh push" >> /etc/crontab

# The KVM image already handles the entrypoint for the desktop, 
# so we don't want to override the CMD unless necessary.
