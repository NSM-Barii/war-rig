#!/bin/bash
# Install Claude Code on Debian (headless)

set -e

if [ "$EUID" -ne 0 ]; then
    echo "[!] Run as root: sudo bash install_claude.sh"
    exit 1
fi


# ── NODE.JS ───────────────────────────────────────────────
echo "[+] Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt install -y nodejs
echo "[+] Node $(node -v) installed"
echo ""


# ── CLAUDE CODE ───────────────────────────────────────────
echo "[+] Installing Claude Code..."
npm install -g @anthropic-ai/claude-code
echo "[+] Claude Code installed"
echo ""


# ── DONE ──────────────────────────────────────────────────
echo "[+] Done — run 'claude' to start and follow the login URL on your phone"
