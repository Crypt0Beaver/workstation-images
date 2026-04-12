FROM docker.io/vastai/kvm:ubuntu_desktop_24.04-2025-11-24

ENV DEBIAN_FRONTEND=noninteractive

# 1. Install core tools
RUN apt-get update && apt-get install -y \
    nvtop htop rclone wget curl xz-utils libglu1-mesa jq flatpak \
    && apt-get clean

# 2. Add the Flathub repository
RUN flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# 3. Install PrusaSlicer (Stable)
# Note: We use --system to install it for all users in the container
RUN flatpak install -y flathub com.prusa3d.PrusaSlicer
# Create a wrapper so 'prusa-slicer' command works like a normal app
RUN echo '#!/bin/bash\nflatpak run com.prusa3d.PrusaSlicer "$@"' > /usr/local/bin/prusa-slicer && \
    chmod +x /usr/local/bin/prusa-slicer

# 4. Install Blender (Stable)
# Note: We use --system to install it for all users in the container
# RUN flatpak install -y flathub org.blender.Blender
# RUN ln -s /var/lib/flatpak/exports/bin/org.blender.Blender /usr/local/bin/blender

# Direct Install Blender (Saves MASSIVE space)
# This uses the mirror logic to get the real latest without the Flatpak overhead
RUN B_BASE="https://mirrors.dotsrc.org/blender/release/" && \
    VERSION=$(curl -s $B_BASE | grep -oP 'Blender\K[0-9]+\.[0-9]+' | sort -V | tail -1) && \
    SUB=$(curl -s "${B_BASE}Blender${VERSION}/" | grep -oP "blender-\K$VERSION\.[0-9]+" | sort -V | tail -1) && \
    wget -q "https://mirrors.dotsrc.org/blender/release/Blender${VERSION}/blender-${SUB}-linux-x64.tar.xz" && \
    mkdir -p /opt/blender && tar -xf blender-*.tar.xz -C /opt/blender --strip-components=1 && \
    ln -s /opt/blender/blender /usr/local/bin/blender && \
    rm blender-*.tar.xz
    
# 2. Dynamically fetch latest PrusaSlicer (using jq for reliability)
# RUN export URL=$(curl -s https://api.github.com/repos/prusa3d/PrusaSlicer/releases/latest | jq -r '.assets[] | select(.name | contains("linux-x64-GTK3")) | .browser_download_url' | head -n 1) \
#     && echo "Downloading PrusaSlicer from: $URL" \
#     && if [ -z "$URL" ] || [ "$URL" = "null" ]; then echo "Error: PrusaSlicer URL not found"; exit 1; fi \
#     && wget -q -O prusaslicer.tar.bz2 "$URL" \
#     && mkdir -p /opt/prusaslicer \
#     && tar -xf prusaslicer.tar.bz2 -C /opt/prusaslicer --strip-components=1 \
#     && ln -s /opt/prusaslicer/prusa-slicer /usr/local/bin/prusa-slicer \
#     && rm prusaslicer.tar.bz2
# We use the GitHub API to find the GTK3 tarball. 
# Added 'arg GITHUB_TOKEN' to allow authenticated API calls if needed.
# ARG GITHUB_TOKEN
# RUN export URL=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" https://api.github.com/repos/prusa3d/PrusaSlicer/releases/latest | \
#     jq -r '.assets[] | select(.name | test("linux-x64-GTK3.*tar.bz2")) | .browser_download_url' | head -n 1) \
#     && echo "Downloading PrusaSlicer from: $URL" \
#     && if [ -z "$URL" ] || [ "$URL" = "null" ]; then \
#          echo "❌ Error: Could not find PrusaSlicer Linux GTK3 asset. Check naming on GitHub."; \
#          exit 1; \
#        fi \
#     && wget -q -O prusaslicer.tar.bz2 "$URL" \
#     && mkdir -p /opt/prusaslicer \
#     && tar -xf prusaslicer.tar.bz2 -C /opt/prusaslicer --strip-components=1 \
#     && ln -s /opt/prusaslicer/prusa-slicer /usr/local/bin/prusa-slicer \
#     && rm prusaslicer.tar.bz2

# 3. Dynamically fetch latest Blender
# RUN export VERSION=$(curl -s https://www.blender.org/download/ | grep -oP 'Blender \K[0-9]+\.[0-9]+' | head -n 1) \
#     && export SUBVERSION=$(curl -s https://www.blender.org/download/ | grep -oP 'Blender \K[0-9]+\.[0-9]+\.[0-9]+' | head -n 1) \
#     && export B_URL="https://download.blender.org/release/Blender${VERSION}/blender-${SUBVERSION}-linux-x64.tar.xz" \
#     && echo "Downloading Blender from: $B_URL" \
#     && wget -q "$B_URL" \
#     && mkdir -p /opt/blender \
#     && tar -xf blender-${SUBVERSION}-linux-x64.tar.xz -C /opt/blender --strip-components=1 \
#     && ln -s /opt/blender/blender /usr/local/bin/blender \
#     && rm blender-${SUBVERSION}-linux-x64.tar.xz

# 4. Setup the Sync Script and Systemd Service
COPY sync_data.sh /usr/local/bin/sync_data.sh
COPY vast-sync.service /etc/systemd/system/vast-sync.service
RUN chmod +x /usr/local/bin/sync_data.sh \
    && systemctl enable vast-sync.service

# Setup work directory
# WORKDIR /workspace
RUN mkdir -p /workspace


