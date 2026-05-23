#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# launch.sh — One-shot launcher for the Luanti AI Studio
#
# Usage:
#   ./launch.sh                        # start server + client + default demo
#   ./launch.sh /path/to/my_script.py  # use a custom Python script instead
#
# What this script does (in order):
#   1. Starts the Luanti+VoxeLibre Docker server (if not already running)
#   2. Waits until the server is accepting connections
#   3. Launches the Luanti game client so you can watch
#   4. Waits a moment for the client to open
#   5. Runs the Python demo (or your custom script if one is passed)
#
# Requirements:
#   - Docker + Docker Compose
#   - Luanti client (run luanti-client/install.sh first)
#   - Python 3.8+ with miney installed (pip install miney)
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_DIR="$REPO_ROOT/luanti-voxelibre"
CLIENT_DIR="$REPO_ROOT/luanti-client"
DEFAULT_SCRIPT="$REPO_ROOT/python-code/tests/demo.py"
LUANTI_BIN_FILE="$CLIENT_DIR/.luanti_bin"

SERVER_HOST="localhost"
SERVER_PORT=30000
BOT_NAME="pybot"

# ── Colour helpers ────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}${BOLD}[launch]${RESET} $*"; }
success() { echo -e "${GREEN}${BOLD}[launch]${RESET} $*"; }
warn()    { echo -e "${YELLOW}${BOLD}[launch]${RESET} $*"; }
error()   { echo -e "${RED}${BOLD}[launch]${RESET} $*" >&2; }

# ── Parse arguments ───────────────────────────────────────────────────────────
PYTHON_SCRIPT=""
if [[ $# -ge 1 ]]; then
    PYTHON_SCRIPT="$1"
    if [[ ! -f "$PYTHON_SCRIPT" ]]; then
        error "Custom script not found: $PYTHON_SCRIPT"
        exit 1
    fi
    info "Custom Python script: $PYTHON_SCRIPT"
else
    PYTHON_SCRIPT="$DEFAULT_SCRIPT"
    info "Using default demo: python-code/tests/demo.py"
fi

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║   Luanti AI Studio — Launcher                ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════════╝${RESET}"
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# STEP 1 — Docker server
# ─────────────────────────────────────────────────────────────────────────────
info "Step 1/3 — Starting Luanti+VoxeLibre server…"

if ! command -v docker &>/dev/null; then
    error "Docker not found. Install Docker Desktop: https://www.docker.com/products/docker-desktop/"
    exit 1
fi

cd "$SERVER_DIR"

# If the container is already running, skip the build
RUNNING=$(docker compose ps -q luanti 2>/dev/null | head -1)
if [[ -n "$RUNNING" ]]; then
    warn "Server container already running (skipping build/start)"
else
    info "Building image and starting container…"
    docker compose up -d --build
fi

# ── Wait for the server to be ready ──────────────────────────────────────────
info "Waiting for server to accept connections on port $SERVER_PORT…"
MAX_WAIT=90
ELAPSED=0
READY=0
while [[ $ELAPSED -lt $MAX_WAIT ]]; do
    # Test UDP reachability via netcat (nc) — -u flag for UDP, -z for scan only
    if nc -zu "$SERVER_HOST" "$SERVER_PORT" 2>/dev/null; then
        READY=1
        break
    fi
    # Fallback: check docker logs for the "startup complete" line
    if docker compose logs luanti 2>/dev/null | grep -q "startup complete"; then
        READY=1
        break
    fi
    printf "  ."
    sleep 2
    ELAPSED=$((ELAPSED + 2))
done
echo ""

if [[ $READY -eq 0 ]]; then
    warn "Server didn't respond within ${MAX_WAIT}s — it may still be loading."
    warn "Continuing anyway; the Python script will retry the connection."
else
    success "Server is up! (took ~${ELAPSED}s)"
fi

cd "$REPO_ROOT"

# ─────────────────────────────────────────────────────────────────────────────
# STEP 2 — Luanti client
# ─────────────────────────────────────────────────────────────────────────────
info "Step 2/3 — Launching Luanti client…"

# Resolve the client binary
LUANTI_BIN=""

# 1. Check the saved path from install.sh
if [[ -f "$LUANTI_BIN_FILE" ]]; then
    LUANTI_BIN=$(cat "$LUANTI_BIN_FILE")
fi

# 2. Fall back to searching PATH
if [[ -z "$LUANTI_BIN" ]] || ! command -v ${LUANTI_BIN%% *} &>/dev/null 2>&1; then
    for candidate in luanti minetest flatpak; do
        if command -v "$candidate" &>/dev/null; then
            if [[ "$candidate" == "flatpak" ]]; then
                LUANTI_BIN="flatpak run net.minetest.Minetest"
            else
                LUANTI_BIN="$candidate"
            fi
            break
        fi
    done
fi

# ── Apply Minecraft-matching keybindings to the client config ─────────────────
# Detected automatically: snap install → ~/snap/luanti/common/.minetest/minetest.conf
#                         apt/brew    → ~/.minetest/minetest.conf
#                         flatpak     → ~/.var/app/net.minetest.Minetest/.minetest/minetest.conf
apply_client_setting() {
    local key="$1" val="$2" conf="$3"
    [[ -z "$conf" ]] && return
    if grep -q "^${key} " "$conf" 2>/dev/null; then
        # Replace existing line
        sed -i "s|^${key} .*|${key} = ${val}|" "$conf"
    else
        # Append new line
        echo "${key} = ${val}" >> "$conf"
    fi
}

# Detect client config path
CLIENT_CONF=""
if [[ -n "$LUANTI_BIN" ]]; then
    if [[ "$LUANTI_BIN" == *snap* ]] || [[ -d "$HOME/snap/luanti" ]]; then
        CLIENT_CONF="$HOME/snap/luanti/common/.minetest/minetest.conf"
    elif [[ "$LUANTI_BIN" == *flatpak* ]]; then
        CLIENT_CONF="$HOME/.var/app/net.minetest.Minetest/.minetest/minetest.conf"
    else
        CLIENT_CONF="$HOME/.minetest/minetest.conf"
    fi
fi

if [[ -n "$CLIENT_CONF" ]]; then
    mkdir -p "$(dirname "$CLIENT_CONF")"
    info "Applying Minecraft keybindings to client config…"
    # Read overrides from the reference file in the repo
    while IFS= read -r line; do
        # Skip blank lines and comments
        [[ "$line" =~ ^[[:space:]]*$ ]] && continue
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        key="${line%%=*}"
        val="${line#*=}"
        key="${key%"${key##*[![:space:]]}"}"   # rtrim key
        val="${val#"${val%%[![:space:]]*}"}"   # ltrim val
        apply_client_setting "$key" "$val" "$CLIENT_CONF"
    done < "$CLIENT_DIR/minecraft-keybindings.conf"
    success "Keybindings applied (E=inventory, C=zoom, F3=debug, F5=3rd-person, F2=screenshot)"
else
    warn "Could not detect client config path — keybindings not applied."
fi

if [[ -z "$LUANTI_BIN" ]]; then
    warn "Luanti client not found — skipping client launch."
    warn "Run  luanti-client/install.sh  to install it, then re-run launch.sh"
    warn "You can still watch by opening the client manually and connecting to $SERVER_HOST:$SERVER_PORT"
else
    # Check if the client is already running — match on the binary name
    CLIENT_BINARY_NAME="$(basename "${LUANTI_BIN%% *}")"
    if pgrep -x "$CLIENT_BINARY_NAME" &>/dev/null; then
        warn "Luanti client already running (skipping launch)"
        warn "Switch to the existing window to connect/watch"
    else
        success "Found client: $LUANTI_BIN"
        $LUANTI_BIN \
            --address "$SERVER_HOST" \
            --port "$SERVER_PORT" \
            --name "viewer" \
            &>/dev/null &
        CLIENT_PID=$!
        success "Client launched (PID $CLIENT_PID) — Register as 'viewer' (no password)"
        info "Giving the client 5s to open before starting the demo…"
        sleep 5
    fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# STEP 3 — Python (venv) + script
# ─────────────────────────────────────────────────────────────────────────────
info "Step 3/3 — Running Python script…"
echo ""

VENV_DIR="$REPO_ROOT/.venv"
REQUIREMENTS="$REPO_ROOT/python-code/requirements.txt"

# ── Create venv if it doesn't exist ──────────────────────────────────────────
if [[ ! -f "$VENV_DIR/bin/activate" ]]; then
    info "Creating project venv at .venv/ …"
    python3 -m venv "$VENV_DIR"
    success "venv created."
fi

# ── Activate it ───────────────────────────────────────────────────────────────
# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"
success "venv activated: $(python3 --version) at $(which python3)"

# ── Sync dependencies from requirements.txt ───────────────────────────────────
# --quiet suppresses noise; only prints if something actually changes
info "Syncing dependencies from python-code/requirements.txt …"
pip install --quiet --upgrade pip
pip install --quiet -r "$REQUIREMENTS"
success "Dependencies up to date."

success "Starting: $PYTHON_SCRIPT"
echo "────────────────────────────────────────────────"
python3 "$PYTHON_SCRIPT" \
    --host "$SERVER_HOST" \
    --port "$SERVER_PORT" \
    --name "$BOT_NAME"
echo "────────────────────────────────────────────────"
success "Python script finished."
echo ""

# ── Offer to stop the server ──────────────────────────────────────────────────
echo -e "${YELLOW}Server is still running.${RESET}"
echo "  • Keep it running:   just close this terminal"
echo "  • Stop the server:   docker compose -f luanti-voxelibre/docker-compose.yml down"
echo "  • Wipe the world:    docker compose -f luanti-voxelibre/docker-compose.yml down -v"
