#!/bin/bash
exec > /var/log/vast_setup.log 2>&1
echo "Starting setup at $(date)"

export DEBIAN_FRONTEND=noninteractive

# --- 1. CORE TOOLS ---
apt-get update
apt-get install -y nvtop htop fuse3 wget curl xz-utils libglu1-mesa jq flatpak

# 1. Stop unattended-upgrades so it doesn't lock dpkg
systemctl stop unattended-upgrades
systemctl disable unattended-upgrades

# 2. Wait for any existing apt/dpkg locks to be released
echo "Waiting for apt/dpkg locks to release..."
while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
    sleep 2
done
echo "Locks cleared. Proceeding with setup."

echo "Setting up the provisioning service..."
curl https://raw.githubusercontent.com/Crypt0Beaver/workstation-images/vast.ai-blender/vast-init.service > /etc/systemd/system/vast-init.service
systemctl enable vast-init.service

if [ ! -f "/etc/profile.d/flatpak_path.sh" ]; then
    echo 'export XDG_DATA_DIRS="/var/lib/flatpak/exports/share:/usr/local/share:/usr/share"' >> /etc/profile.d/flatpak_path.sh
fi
export XDG_DATA_DIRS="/var/lib/flatpak/exports/share:$XDG_DATA_DIRS"

# --- 2. TAILSCALE (Version Independent) ---
if ! command -v tailscale &> /dev/null; then
    curl -fsSL https://tailscale.com/install.sh | sh
fi
if [[ $(tailscale status --json | jq -r .BackendState) != "Running" ]]; then
    tailscale up --auth-key=$TAILSCALE_AUTH_KEY --hostname=vast-blender --accept-routes
fi

# --- 3. RCLONE & MOUNT ---
if [ -f /etc/fuse.conf ]; then
    sed -i 's/#user_allow_other/user_allow_other/' /etc/fuse.conf
fi

echo "${RCLONECONFB64_1}${RCLONECONFB64_2}${RCLONECONFB64_3}${RCLONECONFB64_4}" | base64 -d | sudo -u user tee /var/tmp/rclone.conf > /dev/null
curl https://rclone.org/install.sh | sudo bash

if [ ! -f "/etc/systemd/system/rclone-mount.service" ]; then
cat <<EOF > /etc/systemd/system/rclone-mount.service
[Unit]
Description=RClone Mount Service
After=network-online.target
[Service]
Type=notify
User=user
ExecStart=/usr/bin/rclone mount GDriveCedrixm:vastai_rclone /workspace --config /var/tmp/rclone.conf --vfs-cache-mode full --allow-other --exclude "pulse/**" --exclude "dconf/**" --exclude "session/**" --exclude "*.lock"
ExecStop=/bin/fusermount3 -u /workspace
Restart=always
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable rclone-mount.service
systemctl start rclone-mount.service
fi

# Wait for mount
while [ ! -d "/workspace/userhome" ]; do sleep 1; done

# --- 4. KDE SYMLINKS ---
SYNC_FOLDERS=(".config" ".local/share" ".kde" ".mozilla" "Desktop" "Documents")
if [ -d "/workspace/userhome/.config" ]; then
    for FOLDER in "${SYNC_FOLDERS[@]}"; do
        sudo -u user mkdir -p "/workspace/userhome/$FOLDER"
        if [ ! -L "/home/user/$FOLDER" ]; then 
            rm -rf "/home/user/$FOLDER"
            sudo -u user ln -s "/workspace/userhome/$FOLDER" "/home/user/$FOLDER"
        fi
    done
fi

# --- 5. NOMACHINE (Version Check) ---
# Extracts the version from the download page and compares with installed
NX_URL="https://web9001.nomachine.com/download/9.4/Linux/nomachine_9.4.14_1_amd64.deb"
NX_LATEST_VER=$(echo $NX_URL | grep -oP 'nomachine_\K[0-9.]+(?=_1_amd64)')
NX_INSTALLED_VER=$(dpkg-query -W -f='${Version}' nomachine 2>/dev/null | cut -d'-' -f1)

if [ "$NX_INSTALLED_VER" != "$NX_LATEST_VER" ]; then
    echo "Updating NoMachine to $NX_LATEST_VER..."
    wget $NX_URL -O /tmp/nomachine.deb
    timeout 120s dpkg -i /tmp/nomachine.deb || true
    fuser -vki /var/lib/dpkg/lock-frontend || true
    dpkg --configure -a || true
    rm /tmp/nomachine.deb
    systemctl enable nxserver
else
    echo "NoMachine is up to date ($NX_INSTALLED_VER)."
fi

# --- 6. PRUSASLICER (Flatpak Update) ---
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
# flatpak install -y will skip if already installed, but not update.
# 'flatpak update' handles the versioning for us.
flatpak install -y flathub com.prusa3d.PrusaSlicer
flatpak update -y com.prusa3d.PrusaSlicer
if [ ! -f "/usr/local/bin/prusa-slicer" ]; then
    echo -e '#!/bin/bash\nflatpak run com.prusa3d.PrusaSlicer "$@"' > /usr/local/bin/prusa-slicer
    chmod +x /usr/local/bin/prusa-slicer
fi

# --- 7. BLENDER (Version Check) ---
B_BASE="https://mirrors.dotsrc.org/blender/release/"
B_VER_MAJOR=$(curl -s $B_BASE | grep -oP 'Blender\K[0-9]+\.[0-9]+' | sort -V | tail -1)
B_VER_FULL=$(curl -s "${B_BASE}Blender${B_VER_MAJOR}/" | grep -oP "blender-\K$B_VER_MAJOR\.[0-9]+" | sort -V | tail -1)

# Read the currently installed version if it exists
INSTALLED_B_VER=""
[ -f /opt/blender/version.txt ] && INSTALLED_B_VER=$(cat /opt/blender/version.txt)

if [ "$INSTALLED_B_VER" != "$B_VER_FULL" ]; then
    echo "Updating Blender to $B_VER_FULL..."
    wget -q "${B_BASE}Blender${B_VER_MAJOR}/blender-${B_VER_FULL}-linux-x64.tar.xz"
    rm -rf /opt/blender && mkdir -p /opt/blender
    tar -xf blender-*.tar.xz -C /opt/blender --strip-components=1
    echo "$B_VER_FULL" > /opt/blender/version.txt
    [ ! -L /usr/local/bin/blender ] && ln -s /opt/blender/blender /usr/local/bin/blender
    rm blender-*.tar.xz
else
    echo "Blender is up to date ($INSTALLED_B_VER)."
fi

# --- 8. SYNC SERVICE ---
wget -q -O /usr/local/bin/sync_data.sh https://raw.githubusercontent.com/Crypt0Beaver/workstation-images/refs/heads/main/vast.ai-blender/sync_data.sh
chmod +x /usr/local/bin/sync_data.sh

echo "Setup finished at $(date)" > /root/setup_done.txt
