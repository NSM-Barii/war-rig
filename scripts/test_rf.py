# RF ADAPTER TEST SCRIPT
# Verifies monitor mode adapters are up and seeing real 802.11 traffic
# Run this before launching flock-back to confirm everything is working

import subprocess, time
from rich.console import Console
from rich.table import Table
from rich.panel import Panel

console = Console()
AP_IFACE = "wlan0"


# ── STEP 1: CHECK ADAPTERS ────────────────────────────────
def get_adapters():
    """Return dict of {iface: mode} for all wifi adapters"""

    adapters = {}

    try:
        out = subprocess.check_output(["iw", "dev"], text=True)
        iface = None

        for line in out.splitlines():
            line = line.strip()
            if line.startswith("Interface"):
                iface = line.split()[1]
            elif line.startswith("type") and iface:
                adapters[iface] = line.split()[1]
                iface = None

    except Exception as e:
        console.print(f"[bold red][!] iw dev failed: {e}")

    return adapters


def check_adapters():
    console.print("\n[bold yellow][*] Checking adapters...[/bold yellow]")
    adapters = get_adapters()

    table = Table(border_style="bold purple", header_style="bold red")
    table.add_column("Interface")
    table.add_column("Mode")
    table.add_column("Status")

    monitor_ifaces = []

    for iface, mode in adapters.items():
        if iface == AP_IFACE:
            table.add_row(iface, mode, "[bold blue]AP (skipped)[/bold blue]")
            continue

        if mode == "monitor":
            table.add_row(iface, mode, "[bold green]✓ Ready[/bold green]")
            monitor_ifaces.append(iface)
        else:
            table.add_row(iface, mode, "[bold red]✗ Not in monitor mode[/bold red]")

    console.print(table)
    return monitor_ifaces


# ── STEP 2: SNIFF TRAFFIC ─────────────────────────────────
def sniff_traffic(iface, duration=10):
    """Run tshark for N seconds and print what we see"""

    console.print(f"\n[bold yellow][*] Sniffing on [bold white]{iface}[/bold white] for {duration}s...[/bold yellow]")

    cmd = [
        "tshark", "-i", iface, "-l",
        "-a", f"duration:{duration}",
        "-Y", "wlan.fc.type_subtype == 0x08 || wlan.fc.type_subtype == 0x04",
        "-T", "fields",
        "-e", "wlan.ta",
        "-e", "wlan.ssid",
        "-e", "radiotap.dbm_antsignal",
        "-e", "wlan_radio.channel",
        "-e", "wlan.fc.type_subtype",
    ]

    seen    = {}
    count   = 0

    table = Table(title=f"Traffic on {iface}", title_style="bold red", border_style="bold purple", header_style="bold red")
    table.add_column("#",       style="bold white", width=4)
    table.add_column("Type",    style="bold yellow")
    table.add_column("SSID",    style="bold white")
    table.add_column("MAC",     style="bold cyan")
    table.add_column("RSSI",    style="bold magenta")
    table.add_column("Channel", style="bold blue")

    try:
        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)

        for line in process.stdout:
            parts = line.strip().split("\t")
            if len(parts) < 5: continue

            mac     = parts[0]
            raw     = parts[1].strip()
            rssi    = parts[2].split(",")[0] if parts[2] else "?"
            channel = parts[3] or "?"
            ft      = parts[4].strip()

            if not mac or mac == "ff:ff:ff:ff:ff:ff": continue
            if mac in seen: continue

            seen[mac] = True
            count += 1

            # decode ssid
            if raw:
                try:    ssid = bytes.fromhex(raw).decode("utf-8", errors="ignore") or "<hidden>"
                except: ssid = raw or "<hidden>"
            else:
                ssid = "<probe>" if ft == "0x0004" else "<hidden>"

            frame_type = "BEACON" if ft == "0x0008" else "PROBE"

            table.add_row(str(count), frame_type, ssid, mac, f"{rssi} dBm", channel)
            console.print(table)

    except KeyboardInterrupt:
        pass
    finally:
        process.kill()

    return count


# ── MAIN ──────────────────────────────────────────────────
if __name__ == "__main__":

    console.print(Panel("WarRig — RF Adapter Test", style="bold red", border_style="bold purple"))

    monitor_ifaces = check_adapters()

    if not monitor_ifaces:
        console.print("\n[bold red][!] No monitor mode adapters found. Run start.sh first or check your adapters.[/bold red]")
        exit(1)

    console.print(f"\n[bold green][+] Found {len(monitor_ifaces)} monitor adapter(s): {', '.join(monitor_ifaces)}[/bold green]")

    for iface in monitor_ifaces:
        count = sniff_traffic(iface, duration=10)

        if count == 0:
            console.print(f"[bold red][!] {iface} — no traffic seen. Adapter may not be working or no APs in range.[/bold red]")
        else:
            console.print(f"[bold green][+] {iface} — {count} unique device(s) seen. Adapter is working.[/bold green]")

    console.print("\n[bold green][+] Test complete. If you saw traffic, you're good to run flock-back.[/bold green]\n")
