#!/bin/bash
# Install WiFi adapter drivers for AWUS1900 + AWUS036ACS on Raspberry Pi OS Bookworm

set -e

if [ "$EUID" -ne 0 ]; then
    echo "[!] Run as root: sudo bash install_drivers.sh"
    exit 1
fi

KERNEL=$(uname -r)
ARCH=$(uname -m)


# ── CLEAN OLD BROKEN STATE ────────────────────────────────
echo "[+] Cleaning previous driver installs..."
dkms remove rtl8814au/4.3.21  --all 2>/dev/null || true
dkms remove 8814au/5.8.5.1    --all 2>/dev/null || true
dkms remove 8821au/5.12.5.2   --all 2>/dev/null || true
rm -rf /usr/src/rtl8814au-* /usr/src/8814au-* /usr/src/8821au-*
rm -rf /tmp/8814au /tmp/rtl8814au /tmp/8821au /tmp/rtw88
echo "[+] Clean"
echo ""


# ── KERNEL HEADERS ────────────────────────────────────────
echo "[+] Installing kernel headers for $ARCH (kernel $KERNEL)..."
apt update -qq
apt install --no-install-recommends -y dkms build-essential git bc libelf-dev

if [[ "$KERNEL" == *"rpi-2712"* ]]; then
    apt install -y linux-headers-rpi-2712
elif [[ "$ARCH" == "aarch64" ]]; then
    apt install -y linux-headers-rpi-v8
else
    apt install -y linux-headers-rpi-v7l
fi

# verify headers exist
if [ ! -d "/lib/modules/$KERNEL/build" ]; then
    echo "[!] Headers not found at /lib/modules/$KERNEL/build — aborting"
    exit 1
fi

echo "[+] Headers verified"
echo ""


# ── AWUS1900 (RTL8814AU) ──────────────────────────────────
echo "[+] Installing AWUS1900 driver (zebulon2/rtl8814au v4.3.21)..."
rm -rf /tmp/rtl8814au /usr/src/rtl8814au-4.3.21
git clone https://github.com/zebulon2/rtl8814au.git /tmp/rtl8814au
cp -R /tmp/rtl8814au /usr/src/rtl8814au-4.3.21

if dkms build -m rtl8814au -v 4.3.21 && dkms install -m rtl8814au -v 4.3.21; then
    echo "[+] AWUS1900 done"
else
    echo "[!] Build failed — check: cat /var/lib/dkms/rtl8814au/4.3.21/build/make.log"
    exit 1
fi
echo ""


# ── AWUS036ACS (RTL8821AU) ────────────────────────────────
MAJOR=$(echo "$KERNEL" | cut -d'.' -f1)
MINOR=$(echo "$KERNEL" | cut -d'.' -f2)

echo "[+] Installing AWUS036ACS driver (kernel $KERNEL)..."

if modprobe rtw88_8821au 2>/dev/null; then
    echo "[+] AWUS036ACS using in-kernel rtw88 driver"
elif [ "$MAJOR" -gt 6 ] || { [ "$MAJOR" -eq 6 ] && [ "$MINOR" -ge 14 ]; }; then
    echo "[*] Kernel 6.14+ — using lwfinger/rtw88"
    rm -rf /tmp/rtw88
    git clone https://github.com/lwfinger/rtw88.git /tmp/rtw88
    cd /tmp/rtw88 && make && make install && depmod -a
else
    echo "[*] Using aircrack-ng/rtl8812au"
    rm -rf /tmp/rtl8812au
    git clone https://github.com/aircrack-ng/rtl8812au.git /tmp/rtl8812au
    cd /tmp/rtl8812au && make dkms_install
fi

echo "[+] AWUS036ACS done"
echo ""


# ── DONE ──────────────────────────────────────────────────
echo "[+] All drivers installed — rebooting in 3 seconds..."
sleep 3
reboot
