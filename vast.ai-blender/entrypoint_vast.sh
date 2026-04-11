#!/bin/bash

# 1. Restore Rclone config from Env Var
if [ -n "$RCLONE_CONF_BASE64" ]; then
    mkdir -p /root/.config/rclone/
    echo "$RCLONE_CONF_BASE64" | base64 -d > /root/.config/rclone/rclone.conf
    echo "✅ Rclone configured."
fi

# 2. Pull data immediately
/usr/local/bin/sync_data.sh pull

# 3. Setup background "Auto-Save" to cloud every 5 minutes
while true; do
    sleep 300
    /usr/local/bin/sync_data.sh push
done &

echo "🚀 System ready. Background sync active."
