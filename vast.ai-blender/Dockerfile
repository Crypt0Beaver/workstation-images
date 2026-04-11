FROM docker.io/vastai/kvm:ubuntu_desktop_24.04-2025-11-24

ENV DEBIAN_FRONTEND=noninteractive

# 1. Install core tools
RUN apt-get update && apt-get install -y \
    nvtop htop rclone wget curl xz-utils libglu1-mesa jq \
    && apt-get clean

# 2. Dynamically fetch latest PrusaSlicer (using jq for reliability)
RUN export URL=$(curl -s https://api.github.com/repos/prusa3d/PrusaSlicer/releases/latest | jq -r '.assets[] | select(.name | contains("linux-x64-GTK3")) | .browser_download_url' | head -n 1) \
    && echo "Downloading PrusaSlicer from: $URL" \
    && if [ -z "$URL" ] || [ "$URL" = "null" ]; then echo "Error: PrusaSlicer URL not found"; exit 1; fi \
    && wget -q -O prusaslicer.tar.bz2 "$URL" \
    && mkdir -p /opt/prusaslicer \
    && tar -xf prusaslicer.tar.bz2 -C /opt/prusaslicer --strip-components=1 \
    && ln -s /opt/prusaslicer/prusa-slicer /usr/local/bin/prusa-slicer \
    && rm prusaslicer.tar.bz2

# 3. Dynamically fetch latest Blender
RUN export VERSION=$(curl -s https://www.blender.org/download/ | grep -oP 'Blender \K[0-9]+\.[0-9]+' | head -n 1) \
    && export SUBVERSION=$(curl -s https://www.blender.org/download/ | grep -oP 'Blender \K[0-9]+\.[0-9]+\.[0-9]+' | head -n 1) \
    && export B_URL="https://download.blender.org/release/Blender${VERSION}/blender-${SUBVERSION}-linux-x64.tar.xz" \
    && echo "Downloading Blender from: $B_URL" \
    && wget -q "$B_URL" \
    && mkdir -p /opt/blender \
    && tar -xf blender-${SUBVERSION}-linux-x64.tar.xz -C /opt/blender --strip-components=1 \
    && ln -s /opt/blender/blender /usr/local/bin/blender \
    && rm blender-${SUBVERSION}-linux-x64.tar.xz

# 4. Setup the Sync Script and Systemd Service
COPY sync_data.sh /usr/local/bin/sync_data.sh
COPY vast-sync.service /etc/systemd/system/vast-sync.service
RUN chmod +x /usr/local/bin/sync_data.sh \
    && systemctl enable vast-sync.service

# Setup work directory
WORKDIR /workspace
RUN mkdir -p /workspace
