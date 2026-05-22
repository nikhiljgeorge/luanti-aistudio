# luanti-client — Game Client Installer

Installs the **Luanti game client** so you can connect to the server and watch your Python scripts control the world in real time.

## Install

```bash
chmod +x install.sh
./install.sh
```

The script auto-detects your OS and installs via the appropriate method:

| OS | Method |
|---|---|
| Ubuntu / Debian | `apt-get install luanti` (falls back to `minetest`) |
| Fedora / RHEL | `dnf install minetest` |
| Arch Linux | `pacman -S luanti` |
| macOS | `brew install --cask luanti` |
| Windows | `winget install Luanti.Luanti` |
| Any Linux (fallback) | Flatpak from Flathub |

After install, the resolved binary path is saved to `.luanti_bin` — the root `launch.sh` reads this to auto-launch the client.

## Connecting Manually

If you want to connect yourself (without `launch.sh`):

1. Open the Luanti client
2. Click **Join Game**
3. Enter:
   - **Address:** `localhost` (or your server IP)
   - **Port:** `30000`
   - **Name:** anything (e.g. `viewer`)
   - **Password:** *(leave blank for local dev)*

## What You'll See

When the Python demo runs, you'll watch the bot:
- Chat in real time
- Place and remove blocks
- Build structures
- Trigger game events

The Python bot appears as a player named `pybot` in the server's player list.
