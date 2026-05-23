# WarRig

> ⚠️ Currently in active development and testing. Features are being built and pushed regularly.

<img src="assets/IMG_1346.png" width="400"/>

Portable wardriving rig built inside a hardened case. Raspberry Pi 5 running Kali Linux, multiple WiFi adapters, boots headless and runs fully automated.

---

## What's Coming

- **Multi-adapter monitor mode** — all adapters scanning simultaneously across 2.4GHz and 5GHz
- **Live dashboard** — connect your phone to the rig's hotspot and view findings in real time
- **Channel hopping** — automated hopping across all major channels per adapter
- **flock-back integration** — full WiFi and BLE wardriving powered by [flock-back](https://github.com/nsm-barii/flock-back)
- **Auto-start on boot** — plug in and everything comes up on its own via systemd
- **GPS logging** — location tagging for every find
- **Session management** — clean separation of data between drives
- **BLE scanning** — Bluetooth device detection alongside WiFi

---

## Hardware

- Raspberry Pi 5 (8GB) -  will soon be headless debian
- Kali Linux ARM64
- 4 WiFi adapters
- USB hub
- Hardened carry case
- Portable battery bank

---

## Status

Currently in the **RF testing phase**. Adapters are being verified for monitor mode, channel hopping, and live packet capture across all interfaces.

---

## Follow Along

If you want to follow the build as updates get pushed —

⭐ **Give the repo a star** to keep up with progress.

---

Made by NSM Barii
