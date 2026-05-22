#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# install.sh — Install the Luanti game client
#
# Detects the OS and installs via the appropriate package manager or Flatpak.
# After install, prints the command the launch.sh script uses to auto-connect.
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

LUANTI_BIN=""

echo "🎮  Luanti client installer"
echo "────────────────────────────"

# ── Detect OS ─────────────────────────────────────────────────────────────────
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "→ macOS detected"
    if command -v brew &>/dev/null; then
        echo "→ Installing via Homebrew…"
        brew install --cask luanti
        LUANTI_BIN="/Applications/luanti.app/Contents/MacOS/luanti"
    else
        echo "❌  Homebrew not found. Install it first: https://brew.sh"
        echo "   Or download Luanti manually: https://www.luanti.org/downloads/"
        exit 1
    fi

elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "→ Linux detected"

    if command -v apt-get &>/dev/null; then
        echo "→ Installing via apt (Ubuntu/Debian)…"
        sudo apt-get update -qq
        # Try 'luanti' first (new name), fall back to 'minetest' (old name in older repos)
        if apt-cache show luanti &>/dev/null 2>&1; then
            sudo apt-get install -y luanti
            LUANTI_BIN=$(command -v luanti 2>/dev/null || command -v minetest)
        else
            echo "   'luanti' package not found, installing 'minetest' (same software, older package name)…"
            sudo apt-get install -y minetest
            LUANTI_BIN=$(command -v minetest)
        fi

    elif command -v dnf &>/dev/null; then
        echo "→ Installing via dnf (Fedora/RHEL)…"
        sudo dnf install -y minetest
        LUANTI_BIN=$(command -v minetest)

    elif command -v pacman &>/dev/null; then
        echo "→ Installing via pacman (Arch)…"
        sudo pacman -S --noconfirm luanti
        LUANTI_BIN=$(command -v luanti 2>/dev/null || command -v minetest)

    elif command -v flatpak &>/dev/null; then
        echo "→ Falling back to Flatpak…"
        flatpak install -y flathub net.minetest.Minetest
        LUANTI_BIN="flatpak run net.minetest.Minetest"

    else
        echo "❌  No supported package manager found."
        echo "   Install Luanti manually: https://www.luanti.org/downloads/"
        exit 1
    fi

elif [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin"* ]]; then
    echo "→ Windows detected"
    if command -v winget &>/dev/null; then
        echo "→ Installing via winget…"
        winget install --id Luanti.Luanti -e
        LUANTI_BIN="luanti"
    else
        echo "❌  winget not found."
        echo "   Download Luanti from: https://www.luanti.org/downloads/"
        exit 1
    fi

else
    echo "❌  Unknown OS: $OSTYPE"
    echo "   Download Luanti from: https://www.luanti.org/downloads/"
    exit 1
fi

# ── Verify install ─────────────────────────────────────────────────────────────
echo ""
if [[ -n "$LUANTI_BIN" ]] && command -v ${LUANTI_BIN%% *} &>/dev/null 2>&1; then
    echo "✅  Luanti installed successfully!"
    echo "   Binary: $LUANTI_BIN"
else
    echo "⚠️   Install appeared to succeed but binary not found at expected path."
    echo "   You may need to restart your shell or check PATH."
fi

# ── Write the resolved binary path for launch.sh ──────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "$LUANTI_BIN" > "$SCRIPT_DIR/.luanti_bin"
echo ""
echo "   Binary path saved to luanti-client/.luanti_bin"
echo "   The launch.sh script reads this file to start the client."
echo ""
echo "🚀  To start everything now, run from the repo root:"
echo "       ./launch.sh"
