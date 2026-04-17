#!/bin/bash
exec > /var/log/vast_setup.log 2>&1  # Redirect all output to a log file
echo "Starting setup at $(date)"
# 1. Pre-configure debconf to be non-interactive
export DEBIAN_FRONTEND=noninteractive

# 1. Update and install core tools
apt-get update
apt-get install -y nvtop htop fuse3 wget curl xz-utils libglu1-mesa jq flatpak

# Add the Flatpak path to the system-wide environment variables
echo 'export XDG_DATA_DIRS="/var/lib/flatpak/exports/share:/usr/local/share:/usr/share"' >> /etc/profile.d/flatpak_path.sh

# Apply it to your current session immediately
export XDG_DATA_DIRS="/var/lib/flatpak/exports/share:$XDG_DATA_DIRS"

# Install NoMachine
wget https://web9001.nomachine.com/download/9.4/Linux/nomachine_9.4.14_1_amd64.deb
# 2. Run the installation in the background with a "safety" kill
# This ensures that even if it hangs at the very end (after files are copied), 
# your script can continue.
timeout 120s dpkg -i nomachine_9.4.14_1_amd64.deb || true
# dpkg -i nomachine_9.4.14_1_amd64.deb

# 3. Clean up the dpkg lock if it's still held
# NoMachine is usually functional even if the post-inst script hangs at the end.
fuser -vki /var/lib/dpkg/lock-frontend || true
dpkg --configure -a || true
rm nomachine_9.4.14_1_amd64.deb

# Ensure the desktop is ready for remote connections
systemctl enable nxserver

# Enable 'allow_other' in the system config so 'user' can share the mount
if [ -f /etc/fuse.conf ]; then
    sed -i 's/#user_allow_other/user_allow_other/' /etc/fuse.conf
fi

# if [ -z "$RCLONECONFB64_1" ]; then
#     echo "ERROR: RCLONECONFB64_1 is missing. Check Vast.ai Account Env Vars!"
# else
#     export RCLONE_CONFIG_BASE64="${RCLONECONFB64_1}${RCLONECONFB64_2}${RCLONECONFB64_3}${RCLONECONFB64_4}"
# fi

# Define the target user and their custom home
TARGET_USER="user"
CUSTOM_HOME="/workspace/homeuser"

# 1. Create the config directory as 'user'
sudo -u $TARGET_USER mkdir -p "~/.config/rclone"

# 2. Write the config file as 'user'
# We use 'sudo -u user tee' to write to a path the user owns
echo "${RCLONECONFB64_1}${RCLONECONFB64_2}${RCLONECONFB64_3}${RCLONECONFB64_4}" | base64 -d | sudo -u $TARGET_USER tee "~/.config/rclone/rclone.conf" > /dev/null

curl https://rclone.org/install.sh | sudo bash

# 3. Mount as 'user'
# We explicitly tell rclone where the config is since HOME might be weird during root execution
sudo -u $TARGET_USER rclone mount GDriveCedrixm:vastai_rclone /workspace \
    --vfs-cache-mode full \
    --allow-other \
    --daemon
    # --config "$CUSTOM_HOME/.config/rclone/rclone.conf" \

# 2. Mount the cloud folder to the workspace
# We add --dir-cache-time to make it feel snappier
# rclone mount $RCLONE_FOLDER /workspace \
#     --config <(echo "$RCLONE_CONFIG_BASE64" | base64 -d) \
#     --vfs-cache-mode full \
#     --allow-other \
#     --dir-cache-time 1000h \
#     --daemon
    
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
wget -q -O /usr/local/bin/sync_data.sh https://raw.githubusercontent.com/Crypt0Beaver/workstation-images/refs/heads/main/vast.ai-blender/sync_data.sh
chmod +x /usr/local/bin/sync_data.sh

# 5. Signal Completion
echo "Setup Complete" > /root/setup_done.txt
echo "Setup finished at $(date)"
