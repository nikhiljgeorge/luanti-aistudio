#!/bin/sh
# ─────────────────────────────────────────────────────────────────────────────
# entrypoint.sh — Luanti AI Studio server init
#
# Design rules (no more docker cp hacks):
#   • minetest.conf   → ALWAYS overwritten from the image on every start.
#                        Edit it in the repo; rebuild to apply.
#   • world.mt        → Written once (new world bootstrap only).
#   • VoxeLibre game  → Copied once (large; doesn't change between runs).
#   • miney mod       → Copied once (same reason).
#   • worlds/ data    → Never touched (player DB, map — persistent).
# ─────────────────────────────────────────────────────────────────────────────
set -e

CFG="/config/.minetest"

echo "[entrypoint] ── Luanti AI Studio ─────────────────────────────"

# ── Ensure directory tree exists ─────────────────────────────────────────────
mkdir -p "$CFG/games" "$CFG/mods" "$CFG/worlds/world"

# ── VoxeLibre: install once ───────────────────────────────────────────────────
if [ ! -d "$CFG/games/voxelibre" ]; then
    echo "[entrypoint] First run — installing VoxeLibre..."
    cp -r /defaults/.minetest/games/voxelibre "$CFG/games/"
    echo "[entrypoint] VoxeLibre installed."
else
    echo "[entrypoint] VoxeLibre already present — skipping."
fi

# ── miney mod: install once ───────────────────────────────────────────────────
if [ ! -d "$CFG/mods/miney" ]; then
    echo "[entrypoint] First run — installing miney mod..."
    cp -r /defaults/.minetest/mods/miney "$CFG/mods/"
    echo "[entrypoint] miney installed."
else
    echo "[entrypoint] miney mod already present — skipping."
fi

# ── world.mt: bootstrap once (preserves existing world data) ─────────────────
if [ ! -f "$CFG/worlds/world/world.mt" ]; then
    echo "[entrypoint] Creating world bootstrap..."
    cp /defaults/.minetest/worlds/world/world.mt "$CFG/worlds/world/"
fi

# ── minetest.conf: ALWAYS apply from image ───────────────────────────────────
# This is the source of truth. Edit in the repo → rebuild → auto-applied.
echo "[entrypoint] Applying minetest.conf from image (always up to date)..."
cp /defaults/.minetest/minetest.conf "$CFG/minetest.conf"

echo "[entrypoint] ── Launching server ──────────────────────────────"
exec /usr/bin/luantiserver \
    --gameid    voxelibre \
    --worldname world \
    --config    "$CFG/minetest.conf"
