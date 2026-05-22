#!/bin/bash

# ── CONFIG ────────────────────────────────────────────────
AP_IFACE="wlan0"
AP_IP="10.10.10.1/24"
HOSTAPD_CONF="$(dirname "$0")/hostapd.conf"
FLOCK_DIR="/home/pi/flock-back/src"
SERVER_SCRIPT="$(dirname "$0")/server.py"
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
echo "[+] AP live — SSID: WarRig @ 10.10.10.1"

# ── MONITOR MODE ──────────────────────────────────────────
echo "[+] Setting adapters to monitor mode..."
MONITOR_IFACE=""

for iface in $(iw dev | awk '$1=="Interface"{print $2}'); do

    if [ "$iface" = "$AP_IFACE" ]; then
        echo "[!] Skipping $iface (AP)"
        continue
    fi

    ip link set "$iface" down
    iw dev "$iface" set type monitor
    ip link set "$iface" up
    echo "[+] $iface -> monitor mode"

    if [ -z "$MONITOR_IFACE" ]; then
        MONITOR_IFACE="$iface"
    fi

done

# ── FLOCK-BACK ────────────────────────────────────────────
cd "$FLOCK_DIR" || { echo "[!] flock-back not found at $FLOCK_DIR"; exit 1; }

if [ -z "$MONITOR_IFACE" ]; then
    echo "[!] No monitor adapter found — BLE only"
    venv/bin/python main.py &
else
    echo "[+] Launching flock-back on $MONITOR_IFACE..."
    venv/bin/python main.py -i "$MONITOR_IFACE" &
fi

FLOCK_PID=$!
echo "[+] flock-back running (PID $FLOCK_PID)"

# ── DASHBOARD ─────────────────────────────────────────────
echo "[+] Starting dashboard at http://10.10.10.1:5000"
python3 "$SERVER_SCRIPT"

# if dashboard dies, bring flock-back down too
kill "$FLOCK_PID" 2>/dev/null
