#!/bin/bash

# ── CONFIG ────────────────────────────────────────────────
AP_IFACE="wlan0"
AP_IP="10.10.10.1/24"
HOSTAPD_CONF="$(dirname "$0")/../config/hostapd.conf"
FLOCK_DIR="/home/pi/flock-back/src"
SERVER_SCRIPT="$(dirname "$0")/../gui/server.py"
# ──────────────────────────────────────────────────────────

echo "[+] Unblocking RF..."
rfkill unblock all

# ── AP SETUP ──────────────────────────────────────────────
echo "[+] Bringing up AP on $AP_IFACE..."
nmcli dev set "$AP_IFACE" managed no 2>/dev/null || true

ip link set "$AP_IFACE" down
ip addr flush dev "$AP_IFACE"
ip addr add "$AP_IP" dev "$AP_IFACE"
ip link set "$AP_IFACE" up

systemctl restart dnsmasq
hostapd -B "$HOSTAPD_CONF"

if ! pgrep -x hostapd > /dev/null; then
    echo "[!] hostapd failed to start — check $HOSTAPD_CONF"
    exit 1
fi

echo "[+] AP live — SSID: WarRig @ 10.10.10.1"

# ── FLOCK-BACK ────────────────────────────────────────────
cd "$FLOCK_DIR" || { echo "[!] flock-back not found at $FLOCK_DIR"; exit 1; }

echo "[+] Launching flock-back in wardriver mode..."
venv/bin/python main.py -w &

FLOCK_PID=$!
echo "[+] flock-back running (PID $FLOCK_PID)"

# ── DASHBOARD ─────────────────────────────────────────────
echo "[+] Starting dashboard at http://10.10.10.1:5000"
python3 "$SERVER_SCRIPT"

kill "$FLOCK_PID" 2>/dev/null
