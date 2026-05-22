# THIS MODULE WILL HOUSE RF ADAPTER TESTING FOR THE WAR RIG



# UI IMPORTS
from rich.panel import Panel


# ETC IMPORTS
import subprocess, time, threading


# NSM IMPORTS
from database import Variables, Utilities, Background_Threads


# CONSTANTS
console = Variables.console




class RF_Test():
    """This will verify monitor mode adapters are up and seeing real 802.11 traffic"""


    AP_IFACE = "wlan0"
    results  = {}


    @staticmethod
    def _mask_ssid(ssid):
        """Obfuscate ssid"""

        if ssid in ("<hidden>", "<probe>"):
            return ssid
        return ssid[:3] + "*" * (len(ssid) - 3)


    @staticmethod
    def _mask_mac(mac):
        """Obfuscate mac"""

        parts = mac.split(":")
        if len(parts) != 6:
            return mac
        return ":".join(parts[:3]) + ":xx:xx:xx"


    @classmethod
    def _get_adapters(cls):
        """Return dict of {iface: mode} for all wifi adapters"""

        adapters = {}

        try:
            out   = subprocess.check_output(["iw", "dev"], text=True)
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


    @classmethod
    def _check_adapters(cls):
        """Check adapter modes, set monitor where needed, return monitor interfaces"""

        console.print("\n[bold yellow][*] Checking adapters...[/bold yellow]")
        adapters       = cls._get_adapters()
        monitor_ifaces = []

        for iface, mode in adapters.items():

            if iface == cls.AP_IFACE:
                console.print(f"[bold blue][AP]  {iface}  ->  skipped[/bold blue]")
                continue

            if mode == "monitor":
                console.print(f"[bold green][✓]  {iface}  ->  monitor[/bold green]")
                monitor_ifaces.append(iface)
            else:
                Utilities.set_monitor_mode(iface=iface)
                console.print(f"[bold yellow][↑]  {iface}  ->  set to monitor[/bold yellow]")
                monitor_ifaces.append(iface)

        return monitor_ifaces


    @classmethod
    def _scanner(cls, iface, duration=600):
        """Run tshark on iface for N seconds and print what we see"""

        console.print(f"\n[bold purple]\\[{iface}][/bold purple]  [bold yellow][*] Sniffing for {duration}s...[/bold yellow]")

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

        seen  = {}
        count = 0

        process = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True
        )

        try:

            Background_Threads.channel_hopper(iface=iface)

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
                count    += 1

                if raw:
                    try:    ssid = bytes.fromhex(raw).decode("utf-8", errors="ignore") or "<hidden>"
                    except: ssid = raw or "<hidden>"
                else:
                    ssid = "<probe>" if ft == "0x0004" else "<hidden>"

                frame_type = "BEACON" if ft == "0x0008" else "PROBE"

                console.print(f"[bold purple]\\[{iface}][/bold purple]  [bold red]{rssi}[/bold red]  [dim]{frame_type}[/dim]  [bold white]{cls._mask_ssid(ssid)}[/bold white]  [dim]{cls._mask_mac(mac)}[/dim]  [bold purple]ch:{channel}[/bold purple]")

        except Exception as e: console.print(f"[bold purple]\\[{iface}][/bold purple]  [bold red][!] Scanner Error:[bold yellow] {e}")
        finally: process.kill()

        cls.results[iface] = count


    @classmethod
    def main(cls):
        """Run from here"""


        console.print(Panel("WarRig — RF Adapter Test", style="bold red", border_style="bold purple"))

        Utilities.unblock_rf()
        monitor_ifaces = cls._check_adapters()

        if not monitor_ifaces:
            console.print("\n[bold red][!] No monitor mode adapters found.[/bold red]")
            return

        console.print(f"\n[bold green][+] Found {len(monitor_ifaces)} monitor adapter(s): {', '.join(monitor_ifaces)}[/bold green]")

        threads = []

        for iface in monitor_ifaces:
            t = threading.Thread(target=cls._scanner, args=(iface,), daemon=True)
            threads.append(t)
            t.start()

        for t in threads:
            t.join()

        console.print("\n[bold yellow][*] Results:[/bold yellow]")

        for iface, count in cls.results.items():
            if count == 0:
                console.print(f"[bold red][!] {iface}  —  no traffic seen[/bold red]")
            else:
                console.print(f"[bold green][+] {iface}  —  {count} unique device(s) seen[/bold green]")

        console.print("\n[bold green][+] Test complete.[/bold green]\n")




if __name__ == "__main__":
    RF_Test.main()
