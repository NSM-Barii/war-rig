```
██████╗  ██████╗  ██████╗ ██╗  ██╗██╗   ██╗
██╔══██╗██╔═══██╗██╔═══██╗██║ ██╔╝██║   ██║
██║  ██║██║   ██║██║   ██║█████╔╝ ██║   ██║
██║  ██║██║   ██║██║   ██║██╔═██╗ ██║   ██║
██████╔╝╚██████╔╝╚██████╔╝██║  ██╗╚██████╔╝
╚═════╝  ╚═════╝  ╚═════╝ ╚═╝  ╚═╝ ╚═════╝
```

> ⚠️ Currently in active development and testing. Features are being built and pushed regularly.

<img src="assets/IMG_1346.jpg" width="400"/>

Portable wardriving rig built inside a hardened case. Raspberry Pi 5 running Debian Bookworm Lite, multiple WiFi adapters, boots headless and runs fully automated.

---

## What It Does

- **AP on boot** — Pi creates its own WiFi hotspot (SSID: Dooku). Connect your phone, open `10.10.10.1:5000`
- **Live dashboard** — FLOCK tab shows real-time WiFi and BLE detections. KISMET tab opens Kismet's native wardriving UI
- **flock-back integration** — full WiFi and BLE wardriving powered by [flock-back](https://github.com/nsm-barii/flock-back)
- **Kismet integration** — RF wardriving across all monitor-mode adapters, accessible at `10.10.10.1:2501`
- **Multi-adapter monitor mode** — all non-AP adapters scanning simultaneously across 2.4GHz and 5GHz
- **Channel hopping** — automated hopping across all major channels per adapter
- **Auto-start on boot** — plug in and everything comes up on its own via systemd
- **SSH MODE** — tap button on dashboard to drop AP and hand wlan0 back to NetworkManager for SSH access

---

## Hardware

- Raspberry Pi 5 (8GB)
- Debian Bookworm Lite (64-bit)
- ALFA AWUS1900 (RTL8814AU) — monitor mode
- ALFA AWUS036ACS (RTL8821AU) — monitor mode
- Powered USB hub
- Hardened carry case
- Portable battery bank

---

## Setup

```bash
sudo bash scripts/setup.sh
```

Installs all dependencies, drivers, and registers the `dooku` systemd service. Reboot when done.

---

## Status

Currently in the **driver + integration testing phase**.

---

## Follow Along

⭐ **Give the repo a star** to keep up with progress.

---

Made by NSM Barii
