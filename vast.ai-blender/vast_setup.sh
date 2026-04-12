#!/bin/bash
# 1. Update and install core tools
apt-get update && apt-get install -y nvtop htop rclone wget curl xz-utils libglu1-mesa jq flatpak

# 2. Install PrusaSlicer via Flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub com.prusa3d.PrusaSlicer
echo -e '#!/bin/bash\nflatpak run com.prusa3d.PrusaSlicer "$@"' > /usr/local/bin/prusa-slicer
chmod +x /usr/local/bin/prusa-slicer

# 3. Install Blender via Tarball
B_BASE="https://mirrors.dotsrc.org/blender/release/"
VERSION=$(curl -s $B_BASE | grep -oP 'Blender\K[0-9]+\.[0-9]+' | sort -V | tail -1)
SUB=$(curl -s "${B_BASE}Blender${VERSION}/" | grep -oP "blender-\K$VERSION\.[0-9]+" | sort -V | tail -1)
wget -q "https://mirrors.dotsrc.org/blender/release/Blender${VERSION}/blender-${SUB}-linux-x64.tar.xz"
mkdir -p /opt/blender && tar -xf blender-*.tar.xz -C /opt/blender --strip-components=1
ln -s /opt/blender/blender /usr/local/bin/blender
rm blender-*.tar.xz

# 4. Setup your Sync Service
# Note: You can also download your sync_data.sh and .service file here via wget
wget -q -O /usr/local/bin/sync_data.sh https://raw.githubusercontent.com/crypt0beaver/workstation-images/main/vast.ai-blender/sync_data.sh
chmod +x /usr/local/bin/sync_data.sh

# 5. Signal Completion
echo "Setup Complete" > /root/setup_done.txt
