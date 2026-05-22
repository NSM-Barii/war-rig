#!/bin/bash

AP_IFACE="wlan0"
AP_IP="10.10.10.1/24"

echo "[+] Starting WarRig AP..."

rfkill unblock all

# Keep NetworkManager from touching wlan0
nmcli dev set "$AP_IFACE" managed no 2>/dev/null

# Reset interface
ip link set "$AP_IFACE" down
ip addr flush dev "$AP_IFACE"
ip addr add "$AP_IP" dev "$AP_IFACE"
ip link set "$AP_IFACE" up

# Start AP services
systemctl restart dnsmasq
systemctl restart hostapd

echo "[+] AP should be live on $AP_IFACE at 10.10.10.1"