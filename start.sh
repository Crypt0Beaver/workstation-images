#!/usr/bin/env bash
set -eux

# Start SSH (optional; comment out if you don’t want it)
service ssh start || true


# 1) Start system D‑Bus if not running
mkdir -p /run/dbus
if ! test -S /run/dbus/system_bus_socket; then
  rm -f /run/dbus/pid || true
  dbus-daemon --system --fork
fi

# 2) Start a physical headless display with Xvfb (DISPLAY :100)
if ! pgrep -f "Xvfb :100" >/dev/null 2>&1; then
  Xvfb :100 -screen 0 1920x1080x24 -nolisten tcp &
  sleep 1
fi

# 3) Start XFCE on :100 (launch under D‑Bus)
export DISPLAY=:100
if ! pgrep -u "$(id -u dev)" -f startxfce4 >/dev/null 2>&1; then
  # run as your desktop user; adjust if you use 'ubuntu'
  sudo -u dev dbus-run-session startxfce4 >/tmp/xfce.log 2>&1 &
  sleep 1
fi

# 4) Make NX attach to :100
sed -i 's/^#\?PhysicalDisplays.*/PhysicalDisplays :100/' /usr/NX/etc/node.cfg
sed -i 's|^#\?DefaultDesktopCommand .*|DefaultDesktopCommand "dbus-run-session startxfce4"|' /usr/NX/etc/node.cfg

# 5) Restart NoMachine
# Start NoMachine (NX)
/usr/NX/bin/nxserver --startup || /usr/NX/bin/nxserver --restart || true


# 6) keep container alive
tail -f /dev/null

# Optional: launch XFCE session in headless mode only if you add a supported display server.
# For NoMachine, you don’t need to run a VNC server; NX creates the desktop session.

# Optional: add Blender alias for convenience
echo 'export PATH=/opt/blender/current:$PATH' >> /etc/profile.d/blender.sh
