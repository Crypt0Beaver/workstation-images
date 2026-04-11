FROM docker.io/vastai/kvm:ubuntu_desktop_24.04-2025-11-24

ENV DEBIAN_FRONTEND=noninteractive

# 1. Install Dependencies & Monitoring
RUN apt-get update && apt-get install -y \
    nvtop htop rclone wget curl xz-utils libglu1-mesa libxcursor1 libxinerama1 \
    && apt-get clean

# 2. Install Latest Blender (Direct Download)
# Note: In 2026, adjust the version number if a newer one is out
RUN wget https://download.blender.org/release/Blender4.3/blender-4.3.0-linux-x64.tar.xz \
    && tar -xf blender-4.3.0-linux-x64.tar.xz -C /opt/ \
    && ln -s /opt/blender-4.3.0-linux-x64/blender /usr/local/bin/blender \
    && rm blender-4.3.0-linux-x64.tar.xz

# 3. Install Latest PrusaSlicer (Direct Download)
RUN wget https://github.com/prusa3d/PrusaSlicer/releases/download/version_2.8.0/PrusaSlicer-2.8.0+linux-x64-GTK3-202501011200.tar.bz2 \
    && tar -xf PrusaSlicer-2.8.0+linux-x64-GTK3-202501011200.tar.bz2 -C /opt/ \
    && ln -s /opt/PrusaSlicer-2.8.0+linux-x64-GTK3/prusa-slicer /usr/local/bin/prusa-slicer \
    && rm PrusaSlicer-2.8.0+linux-x64-GTK3-202501011200.tar.bz2

# 4. Integrate the Auto-Sync Script
COPY sync_data.sh /usr/local/bin/sync_data.sh
RUN chmod +x /usr/local/bin/sync_data.sh

# This script will be our internal "master" start script
COPY entrypoint_vast.sh /usr/local/bin/entrypoint_vast.sh
RUN chmod +x /usr/local/bin/entrypoint_vast.sh
