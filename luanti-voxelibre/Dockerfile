FROM lscr.io/linuxserver/luanti:latest

# Run as root during build to install tools and stage files
USER root

# Alpine-based image — use apk
RUN apk add --no-cache git wget

# ── Stage files to /defaults (NOT under /config which is the volume mount) ───
# On first container start our entrypoint copies these into /config.
RUN mkdir -p /defaults/.minetest/games \
             /defaults/.minetest/mods \
             /defaults/.minetest/worlds/world

# VoxeLibre game
RUN wget -q -O /tmp/voxelibre.tar.gz \
        "https://github.com/VoxeLibre/VoxeLibre/archive/refs/heads/master.tar.gz" && \
    tar -xzf /tmp/voxelibre.tar.gz -C /defaults/.minetest/games/ && \
    mv /defaults/.minetest/games/VoxeLibre-master \
       /defaults/.minetest/games/voxelibre && \
    rm /tmp/voxelibre.tar.gz

# miney mod (mod lives at mod/miney/ inside the repo)
RUN git clone --depth 1 https://github.com/miney-py/miney.git /tmp/miney_repo && \
    cp -r /tmp/miney_repo/mod/miney /defaults/.minetest/mods/miney && \
    rm -rf /tmp/miney_repo

# Config files
COPY minetest.conf /defaults/.minetest/minetest.conf
COPY world.mt      /defaults/.minetest/worlds/world/world.mt

# ── Custom entrypoint ─────────────────────────────────────────────────────────
# Bypasses linuxserver's s6/UID-switching machinery (which needs CAP_SETGID).
# Handles first-run initialisation then runs the server directly.
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

# 30000/udp — game port (clients AND Python bot connect here)
EXPOSE 30000/udp
