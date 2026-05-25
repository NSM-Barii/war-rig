# War-Rig Setup


## First Time (on the Pi)

**1. Clone repos**
```bash
cd /home/pi
git clone <war-rig-repo>
git clone <flock-back-repo>
```

**2. Install system packages**
```bash
sudo apt install -y tshark hostapd dnsmasq rfkill iw bluetooth bluez python3 python3-venv
```

**3. Install WiFi adapter drivers**
```
war-rig/docs/install_drivers.txt            (AWUS1900)
war-rig/docs/install_drivers_awus036acs.txt (AWUS036ACS)
```

**4. Set up flock-back Python environment**
```bash
cd /home/pi/flock-back/src
python3 -m venv venv
venv/bin/pip install -r requirements.txt
```

**5. Install and enable the service**
```bash
sudo cp /home/pi/war-rig/config/warrig.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable warrig.service
```

**6. Reboot**
```bash
sudo reboot
```

---

## After That

Plug in and everything comes up automatically.

- AP broadcasts as **WarRig** — password `wardriving123`
- Connect your phone, open `http://10.10.10.1:5000`
- Live flock hits show on the dashboard

---

## Test Adapters Before a Run

```bash
cd /home/pi/war-rig/scripts
sudo python3 test_rf.py
```

Runs for 10 minutes per adapter, prints live traffic. If an adapter shows zero devices it's not working.

---

## Check Service Logs

```bash
journalctl -u warrig.service -f
```
