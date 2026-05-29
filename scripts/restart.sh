#!/bin/bash
# Restart the WarRig service — run from SSH after SSH MODE teardown

if [ "$EUID" -ne 0 ]; then
    echo "[!] Run as root: sudo bash restart.sh"
    exit 1
fi

echo "[+] Starting dooku service..."
systemctl start dooku.service

sleep 1
status=$(systemctl is-active dooku.service)

if [ "$status" = "active" ]; then
    echo "[+] Dooku is up"
else
    echo "[!] Dooku failed to start — check: journalctl -u dooku -n 30"
    exit 1
fi
