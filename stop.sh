#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# stop.sh — Reset the Luanti AI Studio environment
#
# Usage:
#   ./stop.sh           # wipe world + restart server (default)
#   ./stop.sh --down    # wipe world + stop server entirely (don't restart)
#   ./stop.sh --full    # wipe world + stop server + kill client
#
# What this script does (in order):
#   1. Kills any running Python demo/bot processes
#   2. Stops the Docker container and deletes the world volume (down -v)
#   3. Restarts with a clean world  [unless --down or --full]
#   4. Kills the Luanti client      [only with --full]
#
# After this script:
#   • The world is completely blank (all builds gone, all accounts wiped)
#   • The server is running and ready to accept connections [default / --full]
#     OR stopped entirely [--down]
#   • Re-open the Luanti client and register as "viewer" (no password)
#   • Run ./launch.sh (or your script) to start fresh
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_DIR="$REPO_ROOT/luanti-voxelibre"
CLIENT_DIR="$REPO_ROOT/luanti-client"
LUANTI_BIN_FILE="$CLIENT_DIR/.luanti_bin"

# ── Colour helpers ────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}${BOLD}[stop]${RESET} $*"; }
success() { echo -e "${GREEN}${BOLD}[stop]${RESET} $*"; }
warn()    { echo -e "${YELLOW}${BOLD}[stop]${RESET} $*"; }
error()   { echo -e "${RED}${BOLD}[stop]${RESET} $*" >&2; }

# ── Parse flags ───────────────────────────────────────────────────────────────
RESTART_SERVER=true
KILL_CLIENT=false

for arg in "$@"; do
    case "$arg" in
        --down)  RESTART_SERVER=false ;;
        --full)  RESTART_SERVER=true; KILL_CLIENT=true ;;
        --help|-h)
            sed -n '2,28p' "$0"   # print the header comment
            exit 0
            ;;
        *)
            error "Unknown flag: $arg  (use --down, --full, or --help)"
            exit 1
            ;;
    esac
done

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║   Luanti AI Studio — Reset                   ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════════╝${RESET}"
echo ""

if [[ "$RESTART_SERVER" == "false" ]]; then
    warn "Mode: wipe world + stop server (--down)"
elif [[ "$KILL_CLIENT" == "true" ]]; then
    warn "Mode: wipe world + restart server + kill client (--full)"
else
    info "Mode: wipe world + restart server (default)"
fi
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# STEP 1 — Kill any running Python demo / bot processes
# ─────────────────────────────────────────────────────────────────────────────
info "Step 1 — Stopping Python demo/bot processes…"

KILLED=0
# Match on scripts inside this repo's python-code/ directory
while IFS= read -r pid; do
    if [[ -n "$pid" ]]; then
        kill "$pid" 2>/dev/null && KILLED=$((KILLED + 1)) && warn "  Killed PID $pid"
    fi
done < <(pgrep -f "${REPO_ROOT}/python-code" 2>/dev/null || true)

# Also catch any loose 'pybot' miney connections
while IFS= read -r pid; do
    if [[ -n "$pid" ]]; then
        kill "$pid" 2>/dev/null && KILLED=$((KILLED + 1)) && warn "  Killed PID $pid (miney bot)"
    fi
done < <(pgrep -f "miney" 2>/dev/null || true)

if [[ $KILLED -eq 0 ]]; then
    info "  No Python demo processes were running."
else
    success "  Stopped $KILLED process(es)."
fi

# ─────────────────────────────────────────────────────────────────────────────
# STEP 2 — Wipe the world volume
# ─────────────────────────────────────────────────────────────────────────────
info "Step 2 — Wiping world (docker compose down -v)…"

cd "$SERVER_DIR"

if ! command -v docker &>/dev/null; then
    error "Docker not found — cannot wipe world."
    exit 1
fi

# down -v removes the named volume (luanti_data), wiping the entire world
docker compose down -v
success "World volume deleted — map, builds, and player accounts are gone."

cd "$REPO_ROOT"

# ─────────────────────────────────────────────────────────────────────────────
# STEP 3 — Restart server (or leave stopped)
# ─────────────────────────────────────────────────────────────────────────────
if [[ "$RESTART_SERVER" == "true" ]]; then
    info "Step 3 — Starting fresh server…"
    cd "$SERVER_DIR"
    # No --build needed: image hasn't changed, just the world volume was wiped
    docker compose up -d

    # Wait for the server to report it's listening
    info "Waiting for server to be ready…"
    MAX_WAIT=60
    ELAPSED=0
    READY=0
    while [[ $ELAPSED -lt $MAX_WAIT ]]; do
        if docker logs luanti-voxelibre 2>&1 | grep -q "listening on"; then
            READY=1
            break
        fi
        printf "  ."
        sleep 2
        ELAPSED=$((ELAPSED + 2))
    done
    echo ""

    if [[ $READY -eq 1 ]]; then
        success "Server is up with a clean world! (took ~${ELAPSED}s)"
    else
        warn "Server didn't confirm ready within ${MAX_WAIT}s — it may still be loading."
        warn "Check: docker logs luanti-voxelibre"
    fi

    cd "$REPO_ROOT"
else
    info "Step 3 — Server left stopped (--down mode)."
    info "To restart later: docker compose -f luanti-voxelibre/docker-compose.yml up -d"
fi

# ─────────────────────────────────────────────────────────────────────────────
# STEP 4 — Kill client (--full only)
# ─────────────────────────────────────────────────────────────────────────────
if [[ "$KILL_CLIENT" == "true" ]]; then
    info "Step 4 — Closing Luanti client…"

    LUANTI_BIN=""
    if [[ -f "$LUANTI_BIN_FILE" ]]; then
        LUANTI_BIN=$(cat "$LUANTI_BIN_FILE")
    fi
    if [[ -z "$LUANTI_BIN" ]]; then
        for candidate in luanti minetest; do
            if command -v "$candidate" &>/dev/null; then
                LUANTI_BIN="$candidate"
                break
            fi
        done
    fi

    if [[ -n "$LUANTI_BIN" ]]; then
        CLIENT_BINARY_NAME="$(basename "${LUANTI_BIN%% *}")"
        if pkill -x "$CLIENT_BINARY_NAME" 2>/dev/null; then
            success "  Luanti client ($CLIENT_BINARY_NAME) closed."
        else
            info "  Luanti client was not running."
        fi
    else
        warn "  Could not determine client binary name — skipping."
    fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}Reset complete.${RESET}"
echo ""

if [[ "$RESTART_SERVER" == "true" ]]; then
    echo "  • Server is running with a blank world on localhost:30000"
    echo "  • Open the Luanti client → connect → Register as 'viewer' (no password)"
    echo "  • Then run:  ./launch.sh"
else
    echo "  • Server is stopped."
    echo "  • To start fresh:  ./launch.sh"
fi
echo ""
