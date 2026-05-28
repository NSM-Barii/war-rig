#!/bin/bash
# Restart the WarRig service — run from SSH after SSH MODE teardown

if [ "$EUID" -ne 0 ]; then
    echo "[!] Run as root: sudo bash restart.sh"
    exit 1
fi

echo "[+] Starting warrig service..."
systemctl start warrig.service

sleep 1
status=$(systemctl is-active warrig.service)

if [ "$status" = "active" ]; then
    echo "[+] warrig is up"
else
    echo "[!] warrig failed to start — check: journalctl -u warrig -n 30"
    exit 1
fi
