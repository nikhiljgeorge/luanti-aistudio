# Luanti VoxeLibre AI Studio

An open-source Minecraft-like environment (Luanti + VoxeLibre) controllable via Python, packaged for easy deployment anywhere via Docker.

## Structure

```
.
├── luanti-voxelibre/   # Docker server — game engine + VoxeLibre + Python API bridge
├── luanti-client/      # Luanti game client installer (watch the world visually)
├── python-code/
│   └── tests/          # Python scripts that control the game world
└── launch.sh           # One-shot script: starts server → client → runs demo
```

## Quick Start

```bash
# Start everything (server + client + demo)
./launch.sh

# Pass your own Python script instead of the default demo
./launch.sh /path/to/my_script.py
```

## Stack

| Component | Purpose |
|---|---|
| [Luanti](https://www.luanti.org/) | Open-source voxel game engine (formerly Minetest) |
| [VoxeLibre](https://github.com/VoxeLibre/VoxeLibre) | Minecraft-faithful game for Luanti |
| [miney](https://github.com/miney-py/miney) | Python ↔ Luanti bridge |
| Docker | Portable, reproducible server deployment |

## Requirements

- Docker + Docker Compose
- Python 3.8+
- Luanti client (installed via `luanti-client/install.sh`)

## Ports

| Port | Protocol | Purpose |
|---|---|---|
| 30000 | UDP | Luanti game server (players + Python bot) |

## Deploying to a Remote Server

```bash
git clone <this-repo>
cd <repo>
cd luanti-voxelibre
docker compose up -d --build
```

Then point your local Luanti client at `your-server-ip:30000`.
