#!/bin/bash
# WAR-RIG FIRST TIME SETUP


set -e

if [ "$EUID" -ne 0 ]; then
    echo "[!] Run as root: sudo bash setup.sh"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE="$(dirname "$SCRIPT_DIR")"
FLOCK_DIR="$(dirname "$BASE")/flock-back"


echo ""
echo "[+] War-Rig Setup Starting..."
echo ""


# ── SYSTEM DEPS ───────────────────────────────────────────
echo "[+] Installing system packages..."
apt update -qq
apt install -y tshark hostapd dnsmasq rfkill iw bluetooth bluez python3 python3-venv
echo "[+] System packages installed"
echo ""


# ── DRIVERS ───────────────────────────────────────────────
echo "[+] Installing driver dependencies..."
apt install -y kalipi-kernel-headers build-essential dkms git libelf-dev
echo ""

echo "[+] Installing AWUS1900 driver (rtl8814au)..."
rm -rf /tmp/8814au
git clone https://github.com/morrownr/8814au.git /tmp/8814au
cd /tmp/8814au && ./install-driver.sh NoPrompt
echo "[+] AWUS1900 driver installed"
echo ""

echo "[+] Installing AWUS036ACS driver..."
KERNEL_VER="$(uname -r | cut -d'.' -f1-2 | awk -F'.' '{if ($1*100+$2 >= 614) print "new"; else print "old"}')"

if [ "$KERNEL_VER" = "new" ]; then
    echo "[*] Kernel 6.14+ detected — using lwfinger/rtw88"
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


# ── FLOCK-BACK VENV ───────────────────────────────────────
echo "[+] Setting up flock-back Python environment..."

if [ ! -d "$FLOCK_DIR" ]; then
    echo "[!] flock-back not found at $FLOCK_DIR — clone it first"
    exit 1
fi

cd "$FLOCK_DIR/src"
python3 -m venv venv
venv/bin/pip install -q -r "$FLOCK_DIR/requirements.txt"
echo "[+] flock-back venv ready"
echo ""


# ── SYSTEMD SERVICE ───────────────────────────────────────
echo "[+] Installing warrig service..."
sed "s|ExecStart=.*|ExecStart=/usr/bin/python3 $SCRIPT_DIR/start.py|" \
    "$BASE/config/warrig.service" > /etc/systemd/system/warrig.service
systemctl daemon-reload
systemctl enable warrig.service
echo "[+] warrig.service enabled — ExecStart: $SCRIPT_DIR/start.py"
echo ""


# ── DONE ──────────────────────────────────────────────────
echo "[+] Setup complete — reboot to start"
echo ""
