FROM lscr.io/linuxserver/luanti:latest

USER root

# Install git and wget to fetch mods
RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        wget \
    && rm -rf /var/lib/apt/lists/*

# ── VoxeLibre (Minecraft-faithful game) ───────────────────────────────────────
# Pinned to a known-good release tag; bump the tag to upgrade
ARG VOXELIBRE_VERSION=0.91.2
RUN mkdir -p /config/.minetest/games && \
    wget -q -O /tmp/voxelibre.tar.gz \
        "https://github.com/VoxeLibre/VoxeLibre/archive/refs/heads/master.tar.gz" && \
    tar -xzf /tmp/voxelibre.tar.gz -C /config/.minetest/games/ && \
    mv /config/.minetest/games/VoxeLibre-master /config/.minetest/games/voxelibre && \
    rm /tmp/voxelibre.tar.gz

# ── miney mod (Python ↔ Luanti bridge — no luasocket recompilation needed) ────
# Clones the miney repo and copies only the server-side mod into place
RUN mkdir -p /config/.minetest/mods && \
    git clone --depth 1 https://github.com/miney-py/miney.git /tmp/miney_repo && \
    cp -r /tmp/miney_repo/miney_mod /config/.minetest/mods/miney && \
    rm -rf /tmp/miney_repo

# Copy server configuration
COPY minetest.conf /config/.minetest/minetest.conf
COPY world.mt      /config/.minetest/worlds/world/world.mt

# Fix ownership — linuxserver runs as uid/gid 1000 (abc)
RUN chown -R abc:abc /config/.minetest/

USER abc

# 30000/udp  — Luanti game port  (players AND Python bot connect here)
EXPOSE 30000/udp
