#!/usr/bin/env bash
set -e

# Start SSH (optional; comment out if you don’t want it)
service ssh start || true

# Start NoMachine (NX)
/usr/NX/bin/nxserver --startup || /usr/NX/bin/nxserver --restart || true

# Optional: launch XFCE session in headless mode only if you add a supported display server.
# For NoMachine, you don’t need to run a VNC server; NX creates the desktop session.

# Optional: add Blender alias for convenience
echo 'export PATH=/opt/blender/current:$PATH' >> /etc/profile.d/blender.sh
