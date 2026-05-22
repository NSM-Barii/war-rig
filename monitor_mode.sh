#!/bin/bash

echo "[+] Unblocking WiFi (RFKill)"
sudo rfkill unblock all

echo "[+] Finding WiFi Adapters..."

for iface in $(iw dev | awk '$1=="Interface"{print $2}'); do

    # SKIP wlan0
    if [ "$iface" = "wlan0" ]; then
        echo "[!] Skipping $iface"
        continue
    fi

    echo "[+] Setting $iface to monitor mode..."

    sudo ip link set "$iface" down
    sudo iw dev "$iface" set type monitor
    sudo ip link set "$iface" up

    echo "[+] $iface is now:"
    iw dev "$iface" info | grep type

done

echo "[+] MM Done."