# THIS MODULE WILL HOUSE AP DIAGNOSTIC TESTING FOR THE WAR RIG


# UI IMPORTS
from rich.panel import Panel


# ETC IMPORTS
import subprocess
from pathlib import Path


# NSM IMPORTS
from database import Variables


# CONSTANTS
console      = Variables.console
BASE         = Path(__file__).parent.parent
HOSTAPD_CONF = BASE / "config" / "hostapd.conf"
DNSMASQ_CONF = BASE / "config" / "dnsmasq.conf"




class AP_Test():
    """This will verify the AP stack is up and healthy"""


    AP_IFACE = "wlan0"
    AP_IP    = "10.10.10.1"


    @classmethod
    def _check_rfkill(cls):
        """Check RF is unblocked"""

        out = subprocess.run(["rfkill", "list"], capture_output=True, text=True).stdout

        if "yes" in out.lower():
            console.print("[bold red][!] RF is blocked — run rfkill unblock all[/bold red]")
            return False

        console.print("[bold green][+] RF unblocked[/bold green]")
        return True


    @classmethod
    def _check_ip(cls):
        """Check wlan0 has the right IP"""

        out = subprocess.run(["ip", "addr", "show", cls.AP_IFACE], capture_output=True, text=True).stdout

        if cls.AP_IP in out:
            console.print(f"[bold green][+] {cls.AP_IFACE} has IP {cls.AP_IP}[/bold green]")
            return True

        console.print(f"[bold red][!] {cls.AP_IFACE} missing {cls.AP_IP}[/bold red]")
        console.print(f"[dim]{out.strip()}[/dim]")
        return False


    @classmethod
    def _check_hostapd(cls):
        """Check hostapd is running"""

        result = subprocess.run(["pgrep", "-x", "hostapd"], capture_output=True)

        if result.returncode == 0:
            console.print("[bold green][+] hostapd running[/bold green]")
            return True

        console.print(f"[bold red][!] hostapd not running — check {HOSTAPD_CONF}[/bold red]")
        return False


    @classmethod
    def _check_dnsmasq(cls):
        """Check dnsmasq is running and config is deployed"""

        result = subprocess.run(["systemctl", "is-active", "dnsmasq"], capture_output=True, text=True)
        active = result.stdout.strip() == "active"

        if active:
            console.print("[bold green][+] dnsmasq running[/bold green]")
        else:
            console.print("[bold red][!] dnsmasq not running[/bold red]")

        conf = Path("/etc/dnsmasq.d/warrig.conf")

        if conf.exists():
            console.print(f"[bold green][+] dnsmasq config deployed → {conf}[/bold green]")
        else:
            console.print(f"[bold red][!] dnsmasq config missing at {conf}[/bold red]")
            console.print(f"[dim]source: {DNSMASQ_CONF}[/dim]")

        return active and conf.exists()


    @classmethod
    def _check_nmcli(cls):
        """Check NetworkManager isn't managing wlan0"""

        out = subprocess.run(["nmcli", "dev", "show", cls.AP_IFACE], capture_output=True, text=True).stdout

        if "unmanaged" in out.lower():
            console.print(f"[bold green][+] NetworkManager not managing {cls.AP_IFACE}[/bold green]")
            return True

        console.print(f"[bold red][!] NetworkManager may be interfering with {cls.AP_IFACE}[/bold red]")
        return False


    @classmethod
    def main(cls):
        """Run from here"""


        console.print(Panel("WarRig — AP Diagnostic", style="bold red", border_style="bold purple"))

        results = {
            "RF unblocked":   cls._check_rfkill(),
            "wlan0 IP":       cls._check_ip(),
            "hostapd":        cls._check_hostapd(),
            "dnsmasq":        cls._check_dnsmasq(),
            "NetworkManager": cls._check_nmcli(),
        }

        console.print()

        passed = all(results.values())

        if passed:
            console.print("[bold green][+] All checks passed — AP should be working[/bold green]")
        else:
            console.print("[bold red][!] Some checks failed — see above[/bold red]")




if __name__ == "__main__":
    AP_Test.main()
