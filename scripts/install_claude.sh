#!/bin/bash
# Install Claude Code on Kali Linux

set -e

if [ "$EUID" -eq 0 ]; then
    echo "[!] Don't run as root — run as your normal user"
    exit 1
fi

echo "[+] Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo bash -
sudo apt install -y nodejs
echo "[+] Node $(node -v) installed"
echo ""

echo "[+] Installing Claude Code..."
sudo npm install -g @anthropic-ai/claude-code
echo "[+] Claude Code installed"
echo ""

echo "[+] Done — run 'claude' to start"
echo "    It will show a URL — open it on your phone or Mac to log in"
