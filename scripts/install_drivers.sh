#!/bin/bash
# Install WiFi adapter drivers for AWUS1900 + AWUS036ACS on Debian/Pi OS

set -e

if [ "$EUID" -ne 0 ]; then
    echo "[!] Run as root: sudo bash install_drivers.sh"
    exit 1
fi


# ── KERNEL HEADERS ────────────────────────────────────────
echo "[+] Installing kernel headers..."

if apt install -y raspberrypi-kernel-headers build-essential dkms git 2>/dev/null; then
    echo "[+] raspberrypi-kernel-headers installed"
else
    echo "[*] raspberrypi-kernel-headers not found — trying linux-headers..."
    apt install -y linux-headers-$(uname -r) build-essential dkms git
    echo "[+] linux-headers-$(uname -r) installed"
fi


# ── DRIVERS ───────────────────────────────────────────────
echo ""
echo "[+] Attempting realtek-rtl88xxau-dkms..."

if apt install -y realtek-rtl88xxau-dkms 2>/dev/null; then
    echo "[+] realtek-rtl88xxau-dkms installed — covers both adapters"
else
    echo "[*] Package not found — falling back to GitHub installs..."
    echo ""

    # AWUS1900 (RTL8814AU)
    echo "[+] Installing AWUS1900 driver (8814au)..."
    rm -rf /tmp/8814au
    git clone https://github.com/morrownr/8814au.git /tmp/8814au
    cd /tmp/8814au && sudo ./install-driver.sh NoPrompt
    echo "[+] AWUS1900 driver installed"
    echo ""

    # AWUS036ACS — pick driver based on kernel version
    KERNEL=$(uname -r)
    MAJOR=$(echo "$KERNEL" | cut -d'.' -f1)
    MINOR=$(echo "$KERNEL" | cut -d'.' -f2)

    echo "[+] Installing AWUS036ACS driver (kernel $KERNEL)..."

    if [ "$MAJOR" -gt 6 ] || { [ "$MAJOR" -eq 6 ] && [ "$MINOR" -ge 14 ]; }; then
        echo "[*] Kernel 6.14+ — using lwfinger/rtw88"
        rm -rf /tmp/rtw88
        git clone https://github.com/lwfinger/rtw88.git /tmp/rtw88
        cd /tmp/rtw88 && make && make install && depmod -a
    else
        echo "[*] Kernel below 6.14 — using morrownr/8821au"
        rm -rf /tmp/8821au
        git clone https://github.com/morrownr/8821au-20210708.git /tmp/8821au
        cd /tmp/8821au && sudo ./install-driver.sh NoPrompt
    fi

    echo "[+] AWUS036ACS driver installed"
fi


# ── DONE ──────────────────────────────────────────────────
echo ""
echo "[+] All drivers installed — rebooting in 3 seconds..."
sleep 3
reboot
