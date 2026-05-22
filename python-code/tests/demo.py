#!/usr/bin/env python3
"""
demo.py — Luanti + VoxeLibre Python Showcase
═════════════════════════════════════════════
Connects to the local Luanti server as 'pybot' and runs a series of
visually impressive demos you can watch live in the Luanti client.

Run from the repo root via launch.sh, or directly:
    pip install miney
    python python-code/tests/demo.py [--host HOST] [--port PORT]

Demos (in order):
  1. Greeting     — Chat announcement + clear the stage
  2. Rainbow Road — A flat strip of coloured wool stretching into the distance
  3. Spiral Tower — A rising spiral of coloured glass blocks
  4. Checkerboard — 16×16 floor of alternating stone and gold
  5. Fireworks    — TNT bursts lit in sequence (light show)
  6. Countdown    — Signs placed in the air counting 3…2…1…GO
  7. Sign-off     — Clean farewell message in chat
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

# ── Block palettes ─────────────────────────────────────────────────────────────
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
    "mcl_core:glass",
    "mcl_stained_glass:red",
    "mcl_stained_glass:orange",
    "mcl_stained_glass:yellow",
    "mcl_stained_glass:lime",
    "mcl_stained_glass:cyan",
    "mcl_stained_glass:light_blue",
    "mcl_stained_glass:magenta",
]

AIR   = "air"
STONE = "mcl_core:stone"
GOLD  = "mcl_core:goldblock"
PLANK = "mcl_core:wood"
TNT   = "mcl_tnt:tnt"

# ── Helpers ───────────────────────────────────────────────────────────────────

def pos(x, y, z) -> dict:
    """Return a position dict."""
    return {"x": x, "y": y, "z": z}


def place(mt: miney.Minetest, x: int, y: int, z: int, node: str) -> None:
    """Place a single node via Lua so it works even without full miney node API."""
    mt.lua.run(
        f'minetest.set_node({{x={x}, y={y}, z={z}}}, {{name="{node}"}})'
    )


def clear_box(mt: miney.Minetest,
              x1: int, y1: int, z1: int,
              x2: int, y2: int, z2: int) -> None:
    """Fill a bounding box with air."""
    mt.lua.run(
        f"minetest.bulk_set_node("
        f"  minetest.find_nodes_in_area("
        f"    {{x={x1},y={y1},z={z1}}}, {{x={x2},y={y2},z={z2}}}, "
        f"    minetest.registered_nodes and (function() "
        f"      local t={{}} for k in pairs(minetest.registered_nodes) do t[#t+1]=k end return t end)()"
        f"    or {{'air'}}),"
        f"  {{name='air'}})"
    )


def chat(mt: miney.Minetest, message: str) -> None:
    """Broadcast a chat message from the server."""
    mt.lua.run(f'minetest.chat_send_all("{message}")')
    print(f"  💬  {message}")


def sleep(seconds: float, label: str = "") -> None:
    label_str = f"  ⏳  {label}" if label else f"  ⏳  sleeping {seconds}s"
    print(label_str)
    time.sleep(seconds)


# ── Demo routines ─────────────────────────────────────────────────────────────

def demo_greeting(mt: miney.Minetest, ox: int, oy: int, oz: int) -> None:
    """Announce the demo and clear the stage."""
    print("\n🎉  [1/6] Greeting + stage clear")
    chat(mt, "=== Python Demo Starting! Watch closely... ===")
    sleep(1)
    chat(mt, "Clearing the stage...")

    # Wipe a 48×20×48 area above the origin so we have a blank canvas
    for dy in range(0, 20):
        for dx in range(-2, 46):
            for dz in range(-2, 46):
                mt.lua.run(
                    f'minetest.set_node({{x={ox+dx},y={oy+dy},z={oz+dz}}}, {{name="air"}})'
                )

    # Lay a flat wooden platform as our stage floor
    for dx in range(0, 44):
        for dz in range(0, 44):
            place(mt, ox + dx, oy, oz + dz, PLANK)

    chat(mt, "Stage ready!")
    sleep(1)


def demo_rainbow_road(mt: miney.Minetest, ox: int, oy: int, oz: int) -> None:
    """Place a rainbow-striped road stretching away from spawn."""
    print("\n🌈  [2/6] Rainbow Road")
    chat(mt, "Demo 1: Rainbow Road!")

    road_length = 40
    stripe_width = len(RAINBOW)  # 8 blocks wide, one colour per lane

    for dz in range(road_length):
        for dx, colour in enumerate(RAINBOW):
            place(mt, ox + dx, oy + 1, oz + dz, colour)
        if dz % 8 == 0:
            pct = int(dz / road_length * 100)
            chat(mt, f"  Building rainbow road... {pct}%")
        time.sleep(0.02)   # tiny delay so you can watch it grow in the client

    chat(mt, "🌈 Rainbow Road complete!")
    sleep(2)


def demo_spiral_tower(mt: miney.Minetest, ox: int, oy: int, oz: int) -> None:
    """Build a rising spiral of coloured glass blocks."""
    print("\n🌀  [3/6] Spiral Tower")
    chat(mt, "Demo 2: Spiral Glass Tower!")

    cx = ox + 22   # centre of our stage
    cz = oz + 22
    radius = 5
    total_steps = 120

    for step in range(total_steps):
        angle  = step * (2 * math.pi / 20)   # one full revolution every 20 steps
        height = step // 4                    # rise every 4 steps
        x = cx + int(radius * math.cos(angle))
        z = cz + int(radius * math.sin(angle))
        y = oy + 2 + height
        colour = GLASS_COLOURS[step % len(GLASS_COLOURS)]
        place(mt, x, y, z, colour)
        time.sleep(0.05)

    chat(mt, "🌀 Spiral tower done!")
    sleep(2)


def demo_checkerboard(mt: miney.Minetest, ox: int, oy: int, oz: int) -> None:
    """Lay a 16×16 checkerboard of stone and gold block on the platform."""
    print("\n♟️   [4/6] Checkerboard Floor")
    chat(mt, "Demo 3: Checkerboard Floor!")

    size = 16
    for dx in range(size):
        for dz in range(size):
            node = STONE if (dx + dz) % 2 == 0 else GOLD
            place(mt, ox + dx + 14, oy + 1, oz + dz + 14, node)
        time.sleep(0.03)

    chat(mt, "♟️  Checkerboard laid!")
    sleep(2)


def demo_fireworks(mt: miney.Minetest, ox: int, oy: int, oz: int) -> None:
    """Light a sequence of TNT blocks high in the air for a fireworks effect."""
    print("\n💥  [5/6] Fireworks (TNT light show)")
    chat(mt, "Demo 4: Fireworks! Stand back...")
    sleep(1)

    blast_spots = [
        (ox +  8, oy + 14, oz + 20),
        (ox + 36, oy + 16, oz + 20),
        (ox + 22, oy + 18, oz +  8),
        (ox + 22, oy + 18, oz + 36),
        (ox + 22, oy + 20, oz + 22),
    ]

    for bx, by, bz in blast_spots:
        place(mt, bx, by, bz, TNT)
        time.sleep(0.1)
        # Punch the TNT via Lua to ignite it
        mt.lua.run(
            f'local pos = {{x={bx},y={by},z={bz}}}; '
            f'minetest.set_node(pos, {{name="air"}}); '
            f'minetest.add_entity(pos, "mcl_tnt:tnt")'
        )
        sleep(0.6, "igniting next charge…")

    chat(mt, "💥 Boom! Fireworks done!")
    sleep(2)


def demo_countdown(mt: miney.Minetest, ox: int, oy: int, oz: int) -> None:
    """Place floating signs counting 3 → 2 → 1 → GO in the air."""
    print("\n🔢  [6/6] Countdown")
    chat(mt, "Demo 5: Countdown!")

    labels = ["3", "2", "1", "GO!"]
    sign_node = "mcl_signs:wall_sign"

    for i, label in enumerate(labels):
        sx = ox + 20
        sy = oy + 12
        sz = oz + 10 + i * 3

        # Place a sign-like block (we use gold as a stand-in since sign
        # metadata requires more complex Lua; this is visually clear)
        colour_map = {"3": GOLD, "2": "mcl_wool:orange", "1": "mcl_wool:red", "GO!": "mcl_wool:lime"}
        place(mt, sx, sy, sz, colour_map[label])

        chat(mt, f"  ⏱  {label}")
        sleep(0.9)

    chat(mt, "🚀  GO! Python controls the world!")
    sleep(1)


def demo_signoff(mt: miney.Minetest) -> None:
    """Farewell message."""
    print("\n👋  Sign-off")
    chat(mt, "=== Demo Complete! The world is yours. ===")
    chat(mt, "Built with Python + miney + Luanti + VoxeLibre 🐍🎮")


# ── Main ──────────────────────────────────────────────────────────────────────

def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Luanti VoxeLibre Python Demo")
    p.add_argument("--host",     default="localhost", help="Server host (default: localhost)")
    p.add_argument("--port",     default=30000, type=int, help="Server port (default: 30000)")
    p.add_argument("--name",     default="pybot",     help="Bot player name (default: pybot)")
    p.add_argument("--password", default="",          help="Bot password (default: empty)")
    p.add_argument("--origin-x", default=0,   type=int, help="X origin for builds (default: 0)")
    p.add_argument("--origin-y", default=5,   type=int, help="Y origin for builds (default: 5)")
    p.add_argument("--origin-z", default=0,   type=int, help="Z origin for builds (default: 0)")
    return p.parse_args()


def main() -> None:
    args = parse_args()
    ox, oy, oz = args.origin_x, args.origin_y, args.origin_z

    print(f"""
╔══════════════════════════════════════════════╗
║   Luanti VoxeLibre — Python Demo             ║
╠══════════════════════════════════════════════╣
║  Server : {args.host}:{args.port:<27}  ║
║  Bot    : {args.name:<37}  ║
║  Origin : ({ox}, {oy}, {oz})
╚══════════════════════════════════════════════╝
Open the Luanti client and connect to {args.host}:30000 to watch live!
""")

    # ── Connect ────────────────────────────────────────────────────────────────
    print("🔌  Connecting to server…")
    try:
        mt = miney.Minetest(
            server=args.host,
            playername=args.name,
            password=args.password,
            port=args.port,
        )
    except Exception as e:
        print(f"\n❌  Could not connect: {e}")
        print("    Is the Docker container running?  Try:  docker compose -f luanti-voxelibre/docker-compose.yml up -d")
        sys.exit(1)

    print("✅  Connected!\n")
    sleep(1, "waiting for world to settle…")

    # ── Run demos ──────────────────────────────────────────────────────────────
    try:
        demo_greeting(mt, ox, oy, oz)
        demo_rainbow_road(mt, ox, oy, oz)
        demo_spiral_tower(mt, ox, oy, oz)
        demo_checkerboard(mt, ox, oy, oz)
        demo_fireworks(mt, ox, oy, oz)
        demo_countdown(mt, ox, oy, oz)
        demo_signoff(mt)
    except KeyboardInterrupt:
        print("\n\n⛔  Demo interrupted by user.")
        chat(mt, "Demo interrupted. Goodbye!")
    except Exception as e:
        print(f"\n❌  Error during demo: {e}")
        raise
    finally:
        print("\n✅  Demo script finished.")


if __name__ == "__main__":
    main()
