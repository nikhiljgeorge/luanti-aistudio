#!/bin/sh
# ─────────────────────────────────────────────────────────────────────────────
# entrypoint.sh — First-run init + Luanti server launcher
#
# On first start (empty volume) this copies the baked-in defaults into /config.
# On subsequent starts it skips the copy and goes straight to the server.
# ─────────────────────────────────────────────────────────────────────────────
set -e

CONFIG_DIR="/config/.minetest"

echo "[entrypoint] Luanti AI Studio — starting up"

# ── First-run: copy defaults into the persistent volume ──────────────────────
if [ ! -d "$CONFIG_DIR/games/voxelibre" ]; then
    echo "[entrypoint] First run — initialising world from defaults..."
    mkdir -p "$CONFIG_DIR/games" \
             "$CONFIG_DIR/mods" \
             "$CONFIG_DIR/worlds/world"

    cp -r /defaults/.minetest/games/voxelibre  "$CONFIG_DIR/games/"
    cp -r /defaults/.minetest/mods/miney       "$CONFIG_DIR/mods/"
    cp    /defaults/.minetest/minetest.conf    "$CONFIG_DIR/"
    cp    /defaults/.minetest/worlds/world/world.mt \
                                               "$CONFIG_DIR/worlds/world/"

    echo "[entrypoint] World initialised."
else
    echo "[entrypoint] Existing world found — skipping first-run copy."
fi

echo "[entrypoint] Launching Luanti server (VoxeLibre + miney)..."
exec /usr/bin/luantiserver \
    --gameid    voxelibre \
    --worldname world \
    --config    "$CONFIG_DIR/minetest.conf"
