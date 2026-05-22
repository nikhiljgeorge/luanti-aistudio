# luanti-voxelibre — Docker Server

Runs a headless Luanti + VoxeLibre dedicated server with the **miney** mod pre-installed so Python scripts can control the world.

## Files

| File | Purpose |
|---|---|
| `Dockerfile` | Builds the server image: base → VoxeLibre game → miney mod → config |
| `docker-compose.yml` | Orchestration: ports, volumes, health-check |
| `minetest.conf` | Server settings (name, mods, map gen, logging) |
| `world.mt` | World metadata — tells the server which game + mods to load |

## Ports

| Port | Protocol | Usage |
|---|---|---|
| 30000 | UDP | Game port — Luanti clients AND Python bots connect here |

## Build & Run

```bash
# From this directory:
docker compose up -d --build

# Tail the server log:
docker compose logs -f

# Stop:
docker compose down
```

## World data

World data is stored in the `luanti_world` Docker volume and persists across restarts. To wipe the world:

```bash
docker compose down -v
```

## Upgrading VoxeLibre

Change the `VOXELIBRE_VERSION` build arg in `docker-compose.yml` and rebuild:

```bash
docker compose build --no-cache
docker compose up -d
```
