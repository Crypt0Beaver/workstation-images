FROM docker.io/vastai/kvm:ubuntu_desktop_24.04-2025-11-24

ENV DEBIAN_FRONTEND=noninteractive

# 1. Install core tools
RUN apt-get update && apt-get install -y \
    nvtop htop rclone wget curl xz-utils libglu1-mesa jq \
    && apt-get clean

# 2. Dynamically Install Latest PrusaSlicer
RUN URL=$(curl -s https://api.github.com/repos/prusa3d/PrusaSlicer/releases/latest | grep -oP '"browser_download_url": "\Khttps://[^"]+linux-x64-GTK3[^"]+tar.bz2') \
    && wget -O prusaslicer.tar.bz2 "$URL" \
    && mkdir -p /opt/prusaslicer && tar -xf prusaslicer.tar.bz2 -C /opt/prusaslicer --strip-components=1 \
    && ln -s /opt/prusaslicer/prusa-slicer /usr/local/bin/prusa-slicer \
    && rm prusaslicer.tar.bz2

# 3. Dynamically Install Latest Blender
RUN VERSION=$(curl -s https://www.blender.org/download/ | grep -oP 'Blender \K[0-9]+\.[0-9]+' | head -1) \
    && SUBVERSION=$(curl -s https://www.blender.org/download/ | grep -oP 'Blender \K[0-9]+\.[0-9]+\.[0-9]+' | head -1) \
    && wget "https://download.blender.org/release/Blender${VERSION}/blender-${SUBVERSION}-linux-x64.tar.xz" \
    && mkdir -p /opt/blender && tar -xf blender-${SUBVERSION}-linux-x64.tar.xz -C /opt/blender --strip-components=1 \
    && ln -s /opt/blender/blender /usr/local/bin/blender \
    && rm blender-${SUBVERSION}-linux-x64.tar.xz

# 4. Setup the Sync Script and Systemd Service
COPY sync_data.sh /usr/local/bin/sync_data.sh
COPY vast-sync.service /etc/systemd/system/vast-sync.service
RUN chmod +x /usr/local/bin/sync_data.sh \
    && systemctl enable vast-sync.service

# Setup work directory
RUN mkdir -p /root/work
