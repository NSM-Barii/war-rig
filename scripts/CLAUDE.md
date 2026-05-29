# Dooku — Claude Context

## What This Is
Wardriving NSM rig running on Raspberry Pi with Kali Linux. Controls everything from a phone via AP-hosted dashboard.

## Current Status
- Reflashed to **Kali Linux ARM64 (with GUI)** after Debian Bookworm driver issues
- Drivers are **NOT YET WORKING** — this is the main blocker
- AP mode not yet tested on Kali

## Hardware
- Raspberry Pi 5 (8GB)
- ALFA AWUS1900 (RTL8814AU) — needs monitor mode
- ALFA AWUS036ACS (RTL8821AU) — needs monitor mode
- Both plug into a powered USB hub
- `lsusb` sees both adapters — it's a driver issue, not hardware

## Driver History
- Kali uses `kalipi-kernel-headers` — this is the right package
- AWUS1900: `morrownr/8814au` with `./install-driver.sh NoPrompt`
- AWUS036ACS: `morrownr/8821au-20210708` with `./install-driver.sh NoPrompt` (kernel < 6.14)
- Previous attempts on Debian Bookworm all failed due to wrong headers package
- On Kali these should work — run `sudo bash scripts/setup.sh` first

## What To Do First
1. Run `sudo bash scripts/setup.sh`
2. Check debug summary output at the end
3. Reboot and verify `ip link show` shows adapters

## Project Structure
- `scripts/start.py` — boot sequence (AP → monitor mode → Kismet → flock-back → dashboard)
- `scripts/setup.sh` — full setup (deps, Kismet, drivers, venv, systemd)
- `scripts/install_drivers.sh` — standalone driver installer
- `gui/server.py` — HTTP server at port 5000
- `gui/dashboard.html` — mobile dashboard (FLOCK tab + KISMET ↗ button)
- `config/hostapd.conf` — AP config (SSID: Dooku, country_code: US)
- `config/dooku.service` — systemd unit

## Boot Flow
1. Unblock RF
2. Pre-create Kismet credentials (`~/.kismet/kismet_httpd.conf`)
3. Bring up AP on wlan0 (IP: 10.10.10.1)
4. Set all other interfaces to monitor mode
5. Start Kismet on monitor interfaces
6. Start flock-back in wardriver mode
7. Serve dashboard at http://10.10.10.1:5000

## AP Details
- SSID: Dooku
- Password: wardriving123
- Pi IP: 10.10.10.1
- Dashboard: http://10.10.10.1:5000
- Kismet UI: http://10.10.10.1:2501 (user: kismet, pass: warrig)

## User
Bari — keep responses short and direct. Ask for error output before suggesting fixes.
