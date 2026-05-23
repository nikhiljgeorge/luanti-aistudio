# luanti-voxelibre — Docker Server: Lessons Learned

Learnings from building and debugging this Docker setup. Read this before making changes.

## Base Image

- Uses `lscr.io/linuxserver/luanti:latest` — **Alpine-based**, not Debian/Ubuntu
- Use `apk add`, never `apt-get`
- Luanti server binary: `/usr/bin/luantiserver`
- Do **not** use linuxserver's s6 init/UID machinery — it requires `CAP_SETUID`/`CAP_SETGID`
  which are unavailable in standard Docker. We bypass it entirely with a custom `ENTRYPOINT`.

## Volume / File Staging Pattern

The linuxserver image mounts a volume at `/config`. Any files written there during `docker build`
are **invisible at runtime** — the volume mount overlays them.

**Solution:** stage all files to `/defaults/` during build; copy into `/config/` at container start.

```
Build time:  COPY → /defaults/.minetest/...   (baked into image)
Runtime:     entrypoint.sh copies → /config/.minetest/...
```

## entrypoint.sh Rules (do not break these)

| What | Behaviour | Reason |
|---|---|---|
| `minetest.conf` | **Always overwritten** from image | Source of truth is git; changes must flow from repo → rebuild → auto-applied |
| `games/voxelibre` | Copy once (skip if present) | 57 MB tarball; no need to re-copy every restart |
| `mods/miney` | Copy once (skip if present) | Same reason |
| `worlds/world/world.mt` | Write once (bootstrap only) | Never overwrite — world data (map, player DBs) lives here |
| `worlds/**/*.sqlite` | Never touched | Player auth, inventory, map — persistent data |

## The Clean Workflow (no hacks)

```bash
# Change a server setting:
nano luanti-voxelibre/minetest.conf

# Apply it:
docker compose up -d --build   # entrypoint always writes latest minetest.conf
git add -A && git commit -m "..."
```

**Never use `docker cp` to push config changes** — it bypasses the image and drifts from git.  
**Never use `docker exec sqlite3`** to grant privileges — fix `default_privs` in `minetest.conf` instead.

## minetest.conf — Key Settings for This Dev Server

```ini
default_privs = interact, shout, miney, fly, fast, noclip, settime
creative_mode = true          # VoxeLibre requires this for fly to work (see below)
disallow_empty_password = false
enable_damage = false
```

Lock down `default_privs` and remove `creative_mode` before exposing to the internet.

## VoxeLibre-Specific Gotchas

### Flying requires `creative_mode = true`, not just the `fly` privilege
VoxeLibre uses its own `mcl_gamemode` mod (Minecraft-style Creative/Survival system).
The bare Luanti `fly` privilege alone is not enough — VoxeLibre overrides physics
based on gamemode. Setting `creative_mode = true` in `minetest.conf` puts all players
in Creative, which enables flying.

### Stained glass node names
VoxeLibre uses `mcl_core:glass_red`, **not** `mcl_stained_glass:red`.
Full pattern: `mcl_core:glass_<colour>` (red, orange, yellow, lime, cyan, light_blue, magenta, etc.)

### Wool node names
`mcl_wool:red`, `mcl_wool:lime`, etc. — these are correct as-is.

### VoxeLibre version
As of 2026-01, VoxeLibre 0.91.2 requires **Luanti ≥ 5.7.0**.
Debian bookworm ships `minetest-server` 5.6.1 — **too old**. Always use the
`lscr.io/linuxserver/luanti` image (5.16.1+) as the base.

## miney Mod

- Repo: `github.com/miney-py/miney`
- Server-side mod path inside the repo: **`mod/miney/`** (not `miney_mod/`)
- Requires Luanti ≥ 5.7.0 (`mod.conf` enforces this)
- Players need the `miney` privilege to execute Lua — include it in `default_privs`
- The `miney` privilege is checked live; granting via DB surgery only works until next restart wipes the cache. Use `default_privs` instead.

## miney Python Library (client side)

- Package: `pip install miney` (v0.5.8 as of 2026)
- Main class: `miney.Luanti(server, playername, password, port)` — **not** `miney.Minetest` (renamed in v0.5)
- Connects on port **30000** (game port), not a separate API port
- Bot is invisible by default (`invisible=True`)
- New players auto-register on first connect; they get whatever `default_privs` says

## Wipe and Restart (nuclear option)

```bash
docker compose down -v     # stops container AND deletes the world volume
docker rmi luanti-voxelibre:local
docker compose up -d --build
```

⚠️ `down -v` destroys the world — all player accounts, map data, and builds are gone.

## Checking What's Running

```bash
docker logs luanti-voxelibre          # full server log
docker logs luanti-voxelibre | tail -20  # recent activity
docker exec luanti-voxelibre ps aux   # processes inside container
```
