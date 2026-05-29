#!/bin/bash
# Install WiFi adapter drivers for AWUS1900 + AWUS036ACS on Raspberry Pi OS Bookworm 64-bit

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
dkms remove rtl8821au/5.12.5.2 --all 2>/dev/null || true
rm -rf /usr/src/rtl8814au-* /usr/src/8814au-* /usr/src/8821au-* /usr/src/rtl8812au-*
rm -rf /tmp/rtl8814au /tmp/rtl8812au /tmp/rtw88
echo "[+] Clean"
echo ""


# ── SWAP (needed for compiling on Pi) ─────────────────────
echo "[+] Increasing swap for build..."
dphys-swapfile swapoff 2>/dev/null || true
sed -i 's/CONF_SWAPSIZE=.*/CONF_SWAPSIZE=2000/' /etc/dphys-swapfile 2>/dev/null || true
dphys-swapfile setup 2>/dev/null || true
dphys-swapfile swapon 2>/dev/null || true
echo ""


# ── KERNEL HEADERS ────────────────────────────────────────
echo "[+] Installing kernel headers for $ARCH (kernel $KERNEL)..."
apt update -qq
apt install --no-install-recommends -y dkms build-essential git bc libelf-dev

apt install -y kalipi-kernel-headers

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

# patch Makefile for ARM64 Pi
sed -i 's/CONFIG_PLATFORM_I386_PC = y/CONFIG_PLATFORM_I386_PC = n/g' /tmp/rtl8814au/Makefile
sed -i 's/CONFIG_PLATFORM_ARM64_RPI = n/CONFIG_PLATFORM_ARM64_RPI = y/g' /tmp/rtl8814au/Makefile

mkdir -p /usr/src/rtl8814au-4.3.21
cp -R /tmp/rtl8814au/. /usr/src/rtl8814au-4.3.21/

dkms add -m rtl8814au -v 4.3.21

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

echo "[+] Installing AWUS036ACS driver (aircrack-ng/rtl8812au)..."
rm -rf /tmp/rtl8812au
git clone https://github.com/aircrack-ng/rtl8812au.git /tmp/rtl8812au
cd /tmp/rtl8812au

# patch Makefile for ARM64 Pi
sed -i 's/CONFIG_PLATFORM_I386_PC = y/CONFIG_PLATFORM_I386_PC = n/g' Makefile
sed -i 's/CONFIG_PLATFORM_ARM64_RPI = n/CONFIG_PLATFORM_ARM64_RPI = y/g' Makefile
export ARCH=arm64
sed -i 's/^MAKE="/MAKE="ARCH=arm64 /' dkms.conf

make dkms_install

echo "[+] AWUS036ACS done"
echo ""


# ── DONE ──────────────────────────────────────────────────
echo "[+] All drivers installed — rebooting in 3 seconds..."
sleep 3
reboot
