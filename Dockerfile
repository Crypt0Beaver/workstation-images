# Dockerfile
ARG BASE_IMAGE=runpod/pytorch:1.0.2-cu1281-torch280-ubuntu2404
FROM ${BASE_IMAGE}

# ---- System & desktop basics ----
ENV DEBIAN_FRONTEND=noninteractive

# RUN set -eux; \
#   echo "=== ubuntu.sources ==="; \
#   test -f /etc/apt/sources.list.d/ubuntu.sources && cat /etc/apt/sources.list.d/ubuntu.sources || true; \
#   echo "=== apt update ==="; \
#   apt-get update || (echo "=== /var/log/apt/term.log ==="; cat /var/log/apt/term.log || true; exit 1)
  
# RUN set -eux; \
#     apt-get update || (cat /var/log/apt/term.log || true; exit 1); \
#     apt-get install -y --no-install-recommends xfce4 || (cat /var/log/apt/term.log || true; exit 1)
# Enable universe/multiverse on Noble (Deb822), use noninteractive APT, and install packages
RUN set -eux; \
    # 1) Make sure the Deb822 sources include universe/multiverse (Noble uses ubuntu.sources)
    if [ -f /etc/apt/sources.list.d/ubuntu.sources ]; then \
      if ! grep -q '^Components: .*universe' /etc/apt/sources.list.d/ubuntu.sources; then \
        sed -i 's/^Components: .*/Components: main universe restricted multiverse/' /etc/apt/sources.list.d/ubuntu.sources; \
      fi; \
    fi; \
    # 2) Update with retries (helps in CI)
    apt-get update -o Acquire::Retries=5 -o Acquire::http::Timeout="30" \
    || (cat /var/log/apt/term.log || true; exit 1); \
    # 3) Install (no apt-transport-https needed on modern Ubuntu)
    apt-get install -y --no-install-recommends \
        ca-certificates gnupg2 \
        xfce4 xfce4-goodies \
        xauth x11-xserver-utils dbus-x11 \
        openssh-server wget curl git sudo nano net-tools socat \
        libglib2.0-0 libx11-6 libxext6 libxrender1 libxtst6 libxi6 \
        libasound2t64 libgtk-3-0 tzdata; \
    rm -rf /var/lib/apt/lists/*


# RUN apt-get update && \
#     apt-get install -y --no-install-recommends \
#         xfce4 xfce4-goodies \
#         xauth x11-xserver-utils dbus-x11 \
#         openssh-server wget ca-certificates \
#         curl git sudo nano net-tools socat \
#         libglib2.0-0 libx11-6 libxext6 libxrender1 libxtst6 libxi6 \
#         libasound2 libgtk-3-0 \
#     && rm -rf /var/lib/apt/lists/*

# ----- Robust user/group creation that handles pre-existing UID/GID 1000 -----
ARG USERNAME=dev
ARG UID=1000
ARG GID=1000

RUN set -eux; \
  # Make sure sudo is available (no-op if already installed)
  apt-get update && apt-get install -y --no-install-recommends sudo && rm -rf /var/lib/apt/lists/*; \
  \
  # 1) Ensure group with GID=${GID} is named ${USERNAME}
  if getent group "${GID}" >/dev/null; then \
    EXISTING_GNAME="$(getent group "${GID}" | cut -d: -f1)"; \
    if [ "${EXISTING_GNAME}" != "${USERNAME}" ]; then \
      groupmod -n "${USERNAME}" "${EXISTING_GNAME}"; \
    fi; \
  else \
    groupadd -g "${GID}" "${USERNAME}"; \
  fi; \
  \
  # 2) Ensure user with UID=${UID} is named ${USERNAME} and home is /home/${USERNAME}
  if getent passwd "${UID}" >/dev/null; then \
    EXISTING_UNAME="$(getent passwd "${UID}" | cut -d: -f1)"; \
    if [ "${EXISTING_UNAME}" != "${USERNAME}" ]; then \
      usermod -l "${USERNAME}" -d "/home/${USERNAME}" -m "${EXISTING_UNAME}"; \
    fi; \
    # Also ensure primary group matches ${GID}
    if [ "$(id -g "${USERNAME}")" != "${GID}" ]; then usermod -g "${GID}" "${USERNAME}"; fi; \
  elif id -u "${USERNAME}" >/dev/null 2>&1; then \
    usermod -u "${UID}" -g "${GID}" -d "/home/${USERNAME}" -m "${USERNAME}"; \
  else \
    useradd -m -u "${UID}" -g "${GID}" -s /bin/bash "${USERNAME}"; \
  fi; \
  \
  # 3) Sudo access (idempotent)
  usermod -aG sudo "${USERNAME}"; \
  grep -qE '^[[:space:]]*%sudo[[:space:]]+ALL=\(ALL\)[[:space:]]+NOPASSWD:ALL' /etc/sudoers \
    || echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# ---- NoMachine (NX) ----
# We install a stable .deb and let it configure itself to /usr/NX and /etc/NX.
# NoMachine typically listens on TCP 4000 by default post-install. 
# (Install location and default port are widely documented in admin guides/tutorials.)
RUN wget -O /tmp/nomachine.deb \
      "https://download.nomachine.com/download/9.3/Linux/nomachine_9.3.7_1_amd64.deb" \
 && apt-get update -o Acquire::Retries=5 \
 && apt-get install -y /tmp/nomachine.deb \
 && rm -f /tmp/nomachine.deb
# (Refs show NoMachine Linux installs to /usr/NX and runs on TCP 4000 by default.) [5](https://kifarunix.com/install-nomachine-on-debian-12/)[6](https://tecadmin.net/install-nomachine-ubuntu/)

# ---- Blender (portable) ----
# Use Blender’s official Linux tarballs – self-contained & perfect for containers.
# You can bump BLENDER_URL to the exact version you want.
ARG BLENDER_URL=https://download.blender.org/release/Blender5.0/blender-5.0.1-linux-x64.tar.xz
RUN mkdir -p /opt/blender \
 && wget -O /opt/blender/blender.tar.xz "${BLENDER_URL}" \
 && tar -xf /opt/blender/blender.tar.xz -C /opt/blender \
 && rm /opt/blender/blender.tar.xz \
 && ln -s $(find /opt/blender -maxdepth 1 -type d -name "blender-*") /opt/blender/current
# (Blender portable tarballs are the official Linux distribution and can run from any folder.) [7](https://docs.blender.org/manual/en/latest/getting_started/installing/linux.html)[8](https://ubuntuhandbook.org/index.php/2021/12/blender-3-0-released-install-tarball/)

# ---- SSH server (optional but useful for SFTP / VS Code Remote) ----
RUN mkdir -p /var/run/sshd \
 && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config \
 && sed -i 's@session    required     pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd
EXPOSE 22

# ---- NoMachine default port ----
EXPOSE 4000

# (Optional) Expose a web port if you add a web UI later (e.g., 6901/http)
# EXPOSE 6901

# ---- Startup script ----
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Default command: start NoMachine + SSH + keep container running
CMD ["bash", "-c", "/usr/local/bin/start.sh && tail -f /dev/null"]
