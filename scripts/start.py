# THIS MODULE WILL HOUSE THE BOOT SEQUENCE FOR THE WAR RIG



# UI IMPORTS
from rich.panel import Panel


# ETC IMPORTS
import subprocess, time
from pathlib import Path


# NSM IMPORTS
from database import Variables, Utilities


# CONSTANTS
console      = Variables.console
BASE         = Path(__file__).parent.parent
HOSTAPD_CONF  = BASE / "config" / "hostapd.conf"
DNSMASQ_CONF  = BASE / "config" / "dnsmasq.conf"
SERVER       = BASE / "gui" / "server.py"
FLOCK_DIR    = Path(__file__).parent.parent.parent / "flock-back" / "src"




class Boot():
    """This will be responsible for booting the war rig"""


    AP_IFACE = "wlan0"
    AP_IP    = "10.10.10.1/24"


    @classmethod
    def _unblock_rf(cls):
        """Unblock all RF interfaces"""

        Utilities.unblock_rf()
        console.print("[bold green][+][/bold green]  RF unblocked")


    @classmethod
    def _start_ap(cls):
        """Bring up the AP on wlan0"""

        console.print(f"[bold green][+][/bold green]  Bringing up AP on {cls.AP_IFACE}...")

        try:
            subprocess.run(["nmcli", "dev", "set", cls.AP_IFACE, "managed", "no"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

            subprocess.run(["ip", "link", "set",  cls.AP_IFACE, "down"],           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            subprocess.run(["ip", "addr", "flush", "dev", cls.AP_IFACE],           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            subprocess.run(["ip", "addr", "add",   cls.AP_IP, "dev", cls.AP_IFACE],stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            subprocess.run(["ip", "link", "set",   cls.AP_IFACE, "up"],            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

            subprocess.run(["cp", str(DNSMASQ_CONF), "/etc/dnsmasq.d/warrig.conf"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            subprocess.run(["systemctl", "restart", "dnsmasq"],                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            subprocess.Popen(["hostapd", "-B", str(HOSTAPD_CONF)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

            time.sleep(3)

            result = subprocess.run(["pgrep", "-x", "hostapd"], stdout=subprocess.DEVNULL)

            if result.returncode != 0:
                console.print(f"[bold red][!] hostapd failed to start — check {HOSTAPD_CONF}[/bold red]")
                return False

            console.print("[bold green][+][/bold green]  AP live — SSID: WarRig @ 10.10.10.1")
            return True

        except Exception as e: console.print(f"[bold red][!] AP Error:[bold yellow] {e}")


    @classmethod
    def _start_flock(cls):
        """Launch flock-back in wardriver mode"""


        if not FLOCK_DIR.exists(): console.print(f"[bold red][!] flock-back not found at {FLOCK_DIR}[/bold red]"); return None

        console.print("[bold green][+][/bold green]  Launching flock-back in wardriver mode...")

        process = subprocess.Popen(
            ["venv/bin/python", "main.py", "-w"],
            cwd=str(FLOCK_DIR)
        )

        console.print(f"[bold green][+][/bold green]  flock-back running (PID {process.pid})")
        return process


    @classmethod
    def _start_dashboard(cls):
        """Launch the dashboard server"""

        console.print("[bold green][+][/bold green]  Starting dashboard at http://10.10.10.1:5000")

        subprocess.run(["python3", str(SERVER)])


    @classmethod
    def main(cls):
        """Run from here"""


        console.print(f"[bold green][+] War-rig starting")

        cls._unblock_rf()

        if not cls._start_ap(): return False

        flock = cls._start_flock()

        cls._start_dashboard()

        if flock: flock.kill()




if __name__ == "__main__":
    Boot.main()
