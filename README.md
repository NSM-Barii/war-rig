# WarRig

Portable wardriving rig built on a Raspberry Pi 5. Boots headless, spins up a local AP, puts all WiFi adapters into monitor mode, runs flock-back, and serves a live dashboard you access from your phone.

---

## Dependencies

**hostapd (Access Point):**
```bash
sudo apt install hostapd -y
sudo systemctl unmask hostapd
```

**dnsmasq (DHCP):**
```bash
sudo apt install dnsmasq -y
```

**BlueZ (Bluetooth):**
```bash
sudo apt install bluez bluez-tools bluez-firmware -y
sudo systemctl enable bluetooth && sudo systemctl start bluetooth
```

**tshark (WiFi packet capture):**
```bash
sudo apt install tshark -y
```
> Select **Yes** when asked to allow non-superusers to capture packets, or run with `sudo`.

**Python 3.10+** — already on Kali.

---

## Setup

**1. Clone flock-back and install dependencies:**
```bash
git clone https://github.com/nsm-barii/flock-back
cd flock-back/src
python3 -m venv venv
source venv/bin/activate
pip install -r ../requirements.txt
```

**2. Copy dnsmasq config:**
```bash
sudo cp dnsmasq.conf /etc/dnsmasq.d/warrig.conf
```

**3. Make start script executable:**
```bash
chmod +x start.sh
```

**4. Disable conflicting system services:**
```bash
sudo systemctl stop hostapd dnsmasq
sudo systemctl disable hostapd
```
> dnsmasq stays enabled — warrig restarts it with our config. hostapd is launched directly by start.sh so the system service needs to be off.

**5. Install and enable warrig service:**
```bash
sudo cp warrig.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable warrig
sudo systemctl start warrig
```

**6. Update paths in `start.sh` and `server.py` to match where flock-back lives on your Pi.**

---

## Checking Logs

```bash
# live logs
sudo journalctl -u warrig -f

# last boot
sudo journalctl -u warrig -b
```

---

## Boot Flow

```
Power On
  → AP up on wlan0 (SSID: WarRig)
  → All other adapters → monitor mode (dynamic, however many you have)
  → flock-back starts scanning
  → Dashboard server starts on port 5000

Phone connects to WarRig AP
  → Open browser → 10.10.10.1:5000
  → Live table of Flock finds, updates every 5s
```

---

## Files

```
start.sh          — master boot script
server.py         — HTTP dashboard server
dashboard.html    — phone UI
hostapd.conf      — AP config (SSID, password, channel)
dnsmasq.conf      — DHCP config for connected phones
warrig.service    — systemd unit for auto-start on boot
```

---

Made by NSM Barii
