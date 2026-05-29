#!/bin/bash
# Remove all RTL driver installs — clean slate

if [ "$EUID" -ne 0 ]; then
    echo "[!] Run as root: sudo bash clean_drivers.sh"
    exit 1
fi

echo "[+] Removing DKMS modules..."
dkms remove rtl8814au/4.3.21 --all 2>/dev/null && echo "    removed rtl8814au 4.3.21" || echo "    rtl8814au 4.3.21 not found"
dkms remove 8814au/5.8.5.1   --all 2>/dev/null && echo "    removed 8814au 5.8.5.1"   || echo "    8814au 5.8.5.1 not found"
dkms remove 8821au/5.12.5.2  --all 2>/dev/null && echo "    removed 8821au 5.12.5.2"  || echo "    8821au 5.12.5.2 not found"

echo "[+] Removing source dirs from /usr/src..."
rm -rf /usr/src/rtl8814au-* /usr/src/8814au-* /usr/src/8821au-* /usr/src/rtw88-*
echo "    done"

echo "[+] Removing apt packages if installed..."
apt remove -y realtek-rtl88xxau-dkms 2>/dev/null && echo "    removed realtek-rtl88xxau-dkms" || echo "    not installed"

echo "[+] Cleaning temp build dirs..."
rm -rf /tmp/rtl8814au /tmp/rtl8814au_ac /tmp/8814au /tmp/8821au /tmp/rtw88
echo "    done"

echo ""
echo "[+] Clean — run install_drivers.sh to reinstall"
