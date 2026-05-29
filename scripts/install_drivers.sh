#!/bin/bash
# Install WiFi adapter drivers for AWUS1900 + AWUS036ACS

set -e

if [ "$EUID" -ne 0 ]; then
    echo "[!] Run as root: sudo bash install_drivers.sh"
    exit 1
fi


# ── KERNEL HEADERS ────────────────────────────────────────
echo "[+] Installing build dependencies..."
apt install -y build-essential dkms git libelf-dev linux-headers-$(uname -r)
echo "[+] Headers installed for kernel $(uname -r)"
echo ""


# ── AWUS1900 (RTL8814AU) ──────────────────────────────────
echo "[+] Installing AWUS1900 driver (zebulon2/rtl8814au v4.3.21)..."
rm -rf /tmp/rtl8814au
git clone https://github.com/zebulon2/rtl8814au.git /tmp/rtl8814au
cp -R /tmp/rtl8814au /usr/src/rtl8814au-4.3.21

if dkms build -m rtl8814au -v 4.3.21 && dkms install -m rtl8814au -v 4.3.21; then
    echo "[+] AWUS1900 driver installed"
else
    echo "[!] zebulon2 build failed — check: cat /var/lib/dkms/rtl8814au/4.3.21/build/make.log"
    echo "[*] Trying aircrack-ng/rtl8814au fallback..."
    dkms remove rtl8814au/4.3.21 --all 2>/dev/null || true
    rm -rf /tmp/rtl8814au_ac
    git clone https://github.com/aircrack-ng/rtl8814au.git /tmp/rtl8814au_ac
    cd /tmp/rtl8814au_ac && make dkms_install
    echo "[+] AWUS1900 driver installed (aircrack-ng)"
fi
echo ""


# ── AWUS036ACS (RTL8821AU) ────────────────────────────────
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
    cd /tmp/8821au && ./install-driver.sh NoPrompt
fi

echo "[+] AWUS036ACS driver installed"
echo ""


# ── DONE ──────────────────────────────────────────────────
echo "[+] All done — rebooting in 3 seconds..."
sleep 3
reboot
