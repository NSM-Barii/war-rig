#!/bin/bash
# DOOKU FIRST TIME SETUP


set -e

if [ "$EUID" -ne 0 ]; then
    echo "[!] Run as root: sudo bash setup.sh"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE="$(dirname "$SCRIPT_DIR")"
FLOCK_DIR="$(dirname "$BASE")/flock-back"
KERNEL=$(uname -r)
ARCH=$(uname -m)


echo ""
echo "[+] Dooku setup starting..."
echo ""


# ── SYSTEM DEPS ───────────────────────────────────────────
echo "[+] Installing system packages..."
apt update -qq
apt install -y tshark hostapd dnsmasq rfkill iw bluetooth bluez python3 python3-venv bc dkms build-essential git libelf-dev wget gnupg
echo "[+] System packages installed"
echo ""


# ── KISMET ────────────────────────────────────────────────
echo "[+] Installing Kismet..."

wget -O - https://www.kismetwireless.net/repos/kismet-release.gpg.key --quiet | gpg --dearmor | tee /usr/share/keyrings/kismet-archive-keyring.gpg >/dev/null
echo 'deb [signed-by=/usr/share/keyrings/kismet-archive-keyring.gpg] https://www.kismetwireless.net/repos/apt/release/bookworm bookworm main' | tee /etc/apt/sources.list.d/kismet.list >/dev/null
apt update -qq

if ! apt install -y kismet 2>/dev/null; then
    echo "[*] Kismet install failed — trying libprotobuf23 fix..."
    wget -q "http://ftp.de.debian.org/debian/pool/main/p/protobuf/libprotobuf23_3.12.4-1_${ARCH}.deb" -O /tmp/libprotobuf23.deb
    dpkg -i /tmp/libprotobuf23.deb
    apt install -y kismet
fi

usermod -aG kismet "$SUDO_USER"
echo "[+] Kismet installed"
echo ""


# ── KERNEL HEADERS ────────────────────────────────────────
echo "[+] Installing kernel headers for $ARCH (kernel $KERNEL)..."
apt install --no-install-recommends -y dkms build-essential git bc libelf-dev

if [[ "$KERNEL" == *"rpi-2712"* ]]; then
    apt install -y linux-headers-rpi-2712
elif [[ "$ARCH" == "aarch64" ]]; then
    apt install -y linux-headers-rpi-v8
else
    apt install -y linux-headers-rpi-v7l
fi

if [ ! -d "/lib/modules/$KERNEL/build" ]; then
    echo "[!] Headers not found at /lib/modules/$KERNEL/build — aborting"
    exit 1
fi
echo "[+] Headers verified"
echo ""


# ── DRIVERS ───────────────────────────────────────────────
echo "[+] Cleaning old driver state..."
dkms remove rtl8814au/4.3.21 --all 2>/dev/null || true
dkms remove 8814au/5.8.5.1   --all 2>/dev/null || true
dkms remove 8821au/5.12.5.2  --all 2>/dev/null || true
rm -rf /usr/src/rtl8814au-* /usr/src/8814au-* /usr/src/8821au-*
rm -rf /tmp/8814au /tmp/8821au /tmp/rtw88

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

MAJOR=$(echo "$KERNEL" | cut -d'.' -f1)
MINOR=$(echo "$KERNEL" | cut -d'.' -f2)

echo "[+] Installing AWUS036ACS driver..."

if modprobe rtw88_8821au 2>/dev/null; then
    echo "[+] AWUS036ACS using in-kernel rtw88 driver"
elif [ "$MAJOR" -gt 6 ] || { [ "$MAJOR" -eq 6 ] && [ "$MINOR" -ge 14 ]; }; then
    echo "[*] Kernel 6.14+ — using lwfinger/rtw88"
    git clone https://github.com/lwfinger/rtw88.git /tmp/rtw88
    cd /tmp/rtw88 && make && make install && depmod -a
else
    echo "[*] Using aircrack-ng/rtl8812au"
    git clone https://github.com/aircrack-ng/rtl8812au.git /tmp/rtl8812au
    cd /tmp/rtl8812au && make dkms_install
fi

echo "[+] AWUS036ACS done"
echo ""


# ── DOOKU VENV ────────────────────────────────────────────
echo "[+] Setting up Dooku Python environment..."
cd "$SCRIPT_DIR"
python3 -m venv venv
venv/bin/pip install -q -r "$SCRIPT_DIR/requirements.txt"
echo "[+] Dooku venv ready"
echo ""


# ── FLOCK-BACK VENV ───────────────────────────────────────
echo "[+] Setting up flock-back Python environment..."

if [ ! -d "$FLOCK_DIR" ]; then
    echo "[*] flock-back not found — cloning..."
    git clone https://github.com/NSM-Barii/flock-back.git "$FLOCK_DIR"
fi

cd "$FLOCK_DIR/src"
python3 -m venv venv
venv/bin/pip install -q -r "$FLOCK_DIR/requirements.txt"
echo "[+] flock-back venv ready"
echo ""


# ── SYSTEMD SERVICE ───────────────────────────────────────
echo "[+] Installing dooku service..."
sed "s|ExecStart=.*|ExecStart=$SCRIPT_DIR/venv/bin/python $SCRIPT_DIR/start.py|" \
    "$BASE/config/dooku.service" > /etc/systemd/system/dooku.service
systemctl daemon-reload
systemctl enable dooku.service
echo "[+] dooku.service enabled"
echo ""


# ── DEBUG SUMMARY ─────────────────────────────────────────
echo "===== KERNEL ====="
uname -r

echo ""
echo "===== INTERFACES ====="
ip link show

echo ""
echo "===== DKMS STATUS ====="
dkms status

echo ""
echo "===== LOADED MODULES ====="
lsmod | grep -E "rtl|88|8814|8821" || echo "none"

echo ""
echo "===== USB DEVICES ====="
lsusb


# ── DONE ──────────────────────────────────────────────────
echo ""
echo "[+] Setup complete — reboot to start"
echo ""
