#!/usr/bin/env python3
"""
demo.py — Luanti + VoxeLibre Python Showcase
═════════════════════════════════════════════
Connects to the local Luanti server as an invisible bot and runs a series of
visually impressive demos you can watch live in the Luanti client.

Run from the repo root:
    python python-code/tests/demo.py [--host HOST] [--port PORT]

Or via the one-shot launcher:
    ./launch.sh

Demos (in order):
  1. Greeting     — Chat announcement
  2. Rainbow Road — Flat strip of coloured wool stretching into the distance
  3. Spiral Tower — Rising spiral of coloured glass blocks
  4. Checkerboard — 16×16 floor of alternating stone and gold
  5. Fireworks    — TNT charges ignited in sequence
  6. Sign-off     — Farewell chat message
"""

import argparse
import math
import time
import sys

# ── miney import with friendly error ──────────────────────────────────────────
try:
    import miney
except ImportError:
    print("❌  miney is not installed.  Run:  pip install miney")
    sys.exit(1)

# ── VoxeLibre block palettes ───────────────────────────────────────────────────
RAINBOW = [
    "mcl_wool:red",
    "mcl_wool:orange",
    "mcl_wool:yellow",
    "mcl_wool:lime",
    "mcl_wool:cyan",
    "mcl_wool:blue",
    "mcl_wool:magenta",
    "mcl_wool:pink",
]

GLASS_COLOURS = [
    "mcl_core:glass",           # clear
    "mcl_core:glass_red",
    "mcl_core:glass_orange",
    "mcl_core:glass_yellow",
    "mcl_core:glass_lime",
    "mcl_core:glass_cyan",
    "mcl_core:glass_light_blue",
    "mcl_core:glass_magenta",
]

STONE = "mcl_core:stone"
GOLD  = "mcl_core:goldblock"
PLANK = "mcl_core:wood"
TNT   = "mcl_tnt:tnt"
AIR   = "air"

# ── Lua helpers ───────────────────────────────────────────────────────────────

def lua_place(mt: miney.Luanti, x: int, y: int, z: int, node: str) -> None:
    """Place a single node via raw Lua."""
    mt.lua.run(f'minetest.set_node({{x={x}, y={y}, z={z}}}, {{name="{node}"}})')


def lua_chat(mt: miney.Luanti, message: str) -> None:
    """Broadcast a chat message to all players."""
    safe = message.replace('"', '\\"')
    mt.lua.run(f'minetest.chat_send_all("{safe}")')
    print(f"  💬  {message}")


def pause(seconds: float, label: str = "") -> None:
    msg = f"  ⏳  {label}" if label else f"  ⏳  {seconds}s pause"
    print(msg)
    time.sleep(seconds)


# ── Demo acts ─────────────────────────────────────────────────────────────────

def demo_greeting(mt: miney.Luanti, ox: int, oy: int, oz: int) -> None:
    print("\n🎉  [1/5] Greeting + platform")
    lua_chat(mt, "=== Python Demo Starting — watch the world! ===")
    pause(1)
    lua_chat(mt, "Laying the stage platform...")

    # 44×44 wooden platform as our canvas
    for dx in range(44):
        for dz in range(44):
            lua_place(mt, ox + dx, oy, oz + dz, PLANK)
        if dx % 10 == 0:
            lua_chat(mt, f"  Platform {int(dx/44*100)}% done...")
        time.sleep(0.01)

    lua_chat(mt, "Stage ready — demos begin!")
    pause(1)


def demo_rainbow_road(mt: miney.Luanti, ox: int, oy: int, oz: int) -> None:
    print("\n🌈  [2/5] Rainbow Road")
    lua_chat(mt, "Demo 1: Rainbow Road! 🌈")

    road_length = 40
    for dz in range(road_length):
        for dx, colour in enumerate(RAINBOW):
            lua_place(mt, ox + dx, oy + 1, oz + dz, colour)
        if dz % 8 == 0:
            pct = int(dz / road_length * 100)
            lua_chat(mt, f"  Building road... {pct}%")
        time.sleep(0.03)

    lua_chat(mt, "🌈 Rainbow Road complete!")
    pause(2)


def demo_spiral_tower(mt: miney.Luanti, ox: int, oy: int, oz: int) -> None:
    print("\n🌀  [3/5] Spiral Tower")
    lua_chat(mt, "Demo 2: Glass Spiral Tower! 🌀")

    cx = ox + 22   # centre of the platform
    cz = oz + 22
    radius  = 5
    steps   = 100

    for step in range(steps):
        angle  = step * (2 * math.pi / 18)   # full revolution every 18 steps
        height = step // 3
        x = cx + int(radius * math.cos(angle))
        z = cz + int(radius * math.sin(angle))
        y = oy + 2 + height
        colour = GLASS_COLOURS[step % len(GLASS_COLOURS)]
        lua_place(mt, x, y, z, colour)
        time.sleep(0.06)

    lua_chat(mt, "🌀 Tower complete!")
    pause(2)


def demo_checkerboard(mt: miney.Luanti, ox: int, oy: int, oz: int) -> None:
    print("\n♟️   [4/5] Checkerboard Floor")
    lua_chat(mt, "Demo 3: Checkerboard Floor! ♟️")

    size = 16
    # Place checkerboard in the centre of the platform
    for dx in range(size):
        for dz in range(size):
            node = STONE if (dx + dz) % 2 == 0 else GOLD
            lua_place(mt, ox + dx + 14, oy + 1, oz + dz + 14, node)
        time.sleep(0.04)

    lua_chat(mt, "♟️  Checkerboard done!")
    pause(2)


def demo_fireworks(mt: miney.Luanti, ox: int, oy: int, oz: int) -> None:
    print("\n💥  [5/5] Fireworks")
    lua_chat(mt, "Demo 4: FIREWORKS! 💥 Stand back...")
    pause(1)

    # Place TNT high up and ignite it by removing and spawning the entity
    blasts = [
        (ox +  8, oy + 15, oz + 20),
        (ox + 36, oy + 17, oz + 20),
        (ox + 22, oy + 19, oz +  8),
        (ox + 22, oy + 19, oz + 36),
        (ox + 22, oy + 22, oz + 22),   # grand finale — centre
    ]
    for i, (bx, by, bz) in enumerate(blasts):
        lua_place(mt, bx, by, bz, TNT)
        time.sleep(0.1)
        # Ignite: remove the node, drop the primed TNT entity
        mt.lua.run(
            f"local p={{x={bx},y={by},z={bz}}}; "
            f"minetest.set_node(p, {{name='air'}}); "
            f"minetest.add_entity(p, 'mcl_tnt:tnt')"
        )
        pause(0.8, f"charge {i+1}/{len(blasts)} ignited")

    lua_chat(mt, "💥 Fireworks done!")
    pause(2)


def demo_signoff(mt: miney.Luanti) -> None:
    print("\n👋  Sign-off")
    lua_chat(mt, "=== Demo Complete! The world is yours to explore. ===")
    lua_chat(mt, "Powered by Python + miney + Luanti + VoxeLibre 🐍🎮")


# ── Connection helper ─────────────────────────────────────────────────────────

def connect(host: str, port: int, name: str, password: str) -> miney.Luanti:
    """Connect to the server, retrying a few times if it's still booting."""
    attempts = 5
    for i in range(attempts):
        try:
            print(f"  Connecting (attempt {i+1}/{attempts})...")
            mt = miney.Luanti(
                server=host,
                playername=name,
                password=password,
                port=port,
                invisible=True,   # bot won't disturb the view
            )
            return mt
        except Exception as e:
            if i < attempts - 1:
                print(f"  ⚠️   {e} — retrying in 5s...")
                time.sleep(5)
            else:
                raise
    raise RuntimeError("Could not connect after all retries")


# ── Main ──────────────────────────────────────────────────────────────────────

def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Luanti VoxeLibre Python Demo")
    p.add_argument("--host",     default="127.0.0.1", help="Server host (default: 127.0.0.1)")
    p.add_argument("--port",     default=30000, type=int)
    p.add_argument("--name",     default="pybot")
    p.add_argument("--password", default="")
    p.add_argument("--origin-x", default=0,  type=int, dest="ox")
    p.add_argument("--origin-y", default=5,  type=int, dest="oy")
    p.add_argument("--origin-z", default=0,  type=int, dest="oz")
    return p.parse_args()


def main() -> None:
    args = parse_args()

    print(f"""
╔══════════════════════════════════════════════╗
║   Luanti VoxeLibre — Python Demo             ║
╠══════════════════════════════════════════════╣
║  Server  : {args.host}:{args.port}
║  Bot     : {args.name}
║  Origin  : ({args.ox}, {args.oy}, {args.oz})
╚══════════════════════════════════════════════╝
Open the Luanti client → Join → {args.host}:30000 → name "viewer"
""")

    print("🔌  Connecting to Luanti server…")
    try:
        mt = connect(args.host, args.port, args.name, args.password)
    except Exception as e:
        print(f"\n❌  Could not connect: {e}")
        print("    Is the Docker container running?")
        print("    docker compose -f luanti-voxelibre/docker-compose.yml up -d")
        sys.exit(1)

    print("✅  Connected!\n")
    pause(1, "letting world settle…")

    try:
        demo_greeting(mt, args.ox, args.oy, args.oz)
        demo_rainbow_road(mt, args.ox, args.oy, args.oz)
        demo_spiral_tower(mt, args.ox, args.oy, args.oz)
        demo_checkerboard(mt, args.ox, args.oy, args.oz)
        demo_fireworks(mt, args.ox, args.oy, args.oz)
        demo_signoff(mt)
    except KeyboardInterrupt:
        print("\n\n⛔  Interrupted.")
        lua_chat(mt, "Demo interrupted. Goodbye!")
    except Exception as e:
        print(f"\n❌  Error: {e}")
        raise
    finally:
        print("\n✅  Demo script finished.")


if __name__ == "__main__":
    main()
