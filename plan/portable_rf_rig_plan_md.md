# Portable RF Rig Plan

## Hardware
- Raspberry Pi 5 (8GB)
- Kali Linux ARM64
- 4 WiFi adapters
- USB hub
- 2 cooling fans
- Portable battery bank
- SSD later

---

# Main Goals
- Multi-adapter monitor mode
- BLE scanning
- Local AP for dashboard
- Auto-start on boot
- GPS logging later
- RF telemetry collection

---

# Adapter Layout
## wlan0
- Dedicated AP interface
- Phone dashboard access

## USB Adapters
- Monitor mode
- Packet capture
- Channel hopping

---

# Boot Flow
```text
Power On
↓
Linux Boots
↓
rfkill unblock
↓
AP starts
↓
Adapters enter monitor mode
↓
Python scanner starts
↓
Dashboard launches
```

---

# Important Linux Tools
```bash
iw
ip
rfkill
hostapd
dnsmasq
systemd
```

---

# Core Commands
## Check adapters
```bash
iw dev
lsusb
rfkill list
```

## Update system
```bash
sudo apt update && sudo apt full-upgrade -y
```

## Check temperature
```bash
vcgencmd measure_temp
```

---

# AP Plan
## Stack
- hostapd
- dnsmasq

## Goal
```text
Phone connects to Pi hotspot
↓
Open dashboard locally
```

---

# Health Monitoring
Track:
- CPU temp
- Adapter count
- Storage remaining
- AP status
- Scanner status
- Uptime

---

# Future Additions
- SSD boot
- GPS module
- SDR integration
- BLE analytics
- RF anomaly detection
- Auto-recovery logic
- Heatmaps
- Session replay

---

# Design Philosophy
Prioritize:
1. Stability
2. Reliability
3. Automation
4. Recovery
5. Data quality

Before:
- Fancy UI
- Complex analytics
- Advanced RF intelligence

