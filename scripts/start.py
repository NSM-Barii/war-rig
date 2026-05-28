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
HOSTAPD_CONF = BASE / "config" / "hostapd.conf"
DNSMASQ_CONF = BASE / "config" / "dnsmasq.conf"
SERVER       = BASE / "gui" / "server.py"
FLOCK_DIR    = Path(__file__).parent.parent.parent / "flock-back" / "src"
KISMET_CONF  = Path.home() / ".kismet" / "kismet_httpd.conf"




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
    def _setup_kismet_auth(cls):
        """Pre-create Kismet httpd credentials so it can run headlessly on first boot"""

        if KISMET_CONF.exists(): return

        try:
            KISMET_CONF.parent.mkdir(parents=True, exist_ok=True)
            KISMET_CONF.write_text("httpd_username=kismet\nhttpd_password=warrig\n")
            console.print("[bold green][+][/bold green]  Kismet credentials created")
        except Exception as e:
            console.print(f"[bold red][!] Could not write Kismet config:[bold yellow] {e}")


    @classmethod
    def _set_monitor_mode(cls):
        """Put all non-AP wireless interfaces into monitor mode"""

        try:
            result  = subprocess.run(["iw", "dev"], capture_output=True, text=True)
            ifaces  = []
            current = None

            for line in result.stdout.splitlines():
                line = line.strip()
                if line.startswith("Interface"):
                    current = line.split()[1]
                elif current and line.startswith("type") and "monitor" not in line:
                    if current != cls.AP_IFACE:
                        ifaces.append(current)
                    current = None

            for iface in ifaces:
                Utilities.set_monitor_mode(iface=iface, verbose=True)

            return ifaces

        except Exception as e:
            console.print(f"[bold red][!] Monitor mode error:[bold yellow] {e}")
            return []


    @classmethod
    def _start_ap(cls):
        """Bring up the AP on wlan0"""

        console.print(f"[bold green][+][/bold green]  Bringing up AP on {cls.AP_IFACE}...")

        try:
            subprocess.run(["nmcli", "dev", "set", cls.AP_IFACE, "managed", "no"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

            subprocess.run(["ip", "link", "set",  cls.AP_IFACE, "down"],            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            subprocess.run(["ip", "addr", "flush", "dev", cls.AP_IFACE],            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            subprocess.run(["ip", "addr", "add",   cls.AP_IP, "dev", cls.AP_IFACE], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            subprocess.run(["ip", "link", "set",   cls.AP_IFACE, "up"],             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

            subprocess.run(["cp", str(DNSMASQ_CONF), "/etc/dnsmasq.d/warrig.conf"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            subprocess.run(["systemctl", "restart", "dnsmasq"],                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            subprocess.Popen(["hostapd", "-B", str(HOSTAPD_CONF)],                  stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

            time.sleep(3)

            result = subprocess.run(["pgrep", "-x", "hostapd"], stdout=subprocess.DEVNULL)

            if result.returncode != 0:
                console.print(f"[bold red][!] hostapd failed to start — check {HOSTAPD_CONF}[/bold red]")
                return False

            console.print("[bold green][+][/bold green]  AP live — SSID: WarRig @ 10.10.10.1")
            return True

        except Exception as e: console.print(f"[bold red][!] AP Error:[bold yellow] {e}")


    @classmethod
    def _get_monitor_ifaces(cls):
        """Find all wireless interfaces currently in monitor mode"""

        try:
            result  = subprocess.run(["iw", "dev"], capture_output=True, text=True)
            ifaces  = []
            current = None

            for line in result.stdout.splitlines():
                line = line.strip()
                if line.startswith("Interface"): current = line.split()[1]
                if line.startswith("type monitor") and current:
                    ifaces.append(current)
                    current = None

            return ifaces

        except Exception: return []


    @classmethod
    def _start_kismet(cls):
        """Launch Kismet in headless mode using all detected monitor interfaces"""

        ifaces = cls._get_monitor_ifaces()

        if not ifaces:
            console.print("[bold red][!] No monitor interfaces found — skipping Kismet[/bold red]"); return None

        cmd = ["kismet", "--no-ncurses"]
        for iface in ifaces: cmd += ["-c", iface]

        console.print(f"[bold green][+][/bold green]  Starting Kismet on {ifaces}...")

        process = subprocess.Popen(
            cmd,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )

        time.sleep(6)

        if process.poll() is not None:
            console.print("[bold red][!] Kismet failed to start[/bold red]"); return None

        console.print(f"[bold green][+][/bold green]  Kismet running (PID {process.pid}) @ http://127.0.0.1:2501")
        return process


    @classmethod
    def _start_flock(cls):
        """Launch flock-back in wardriver mode"""

        if not FLOCK_DIR.exists():
            console.print(f"[bold red][!] flock-back not found at {FLOCK_DIR}[/bold red]"); return None

        console.print("[bold green][+][/bold green]  Launching flock-back in wardriver mode...")

        venv_python = str(FLOCK_DIR / "venv" / "bin" / "python")

        process = subprocess.Popen(
            [venv_python, "main.py", "-w"],
            cwd=str(FLOCK_DIR)
        )

        console.print(f"[bold green][+][/bold green]  flock-back running (PID {process.pid})")
        return process


    @classmethod
    def _start_dashboard(cls):
        """Launch the dashboard server — blocks until SSH MODE is triggered"""

        console.print("[bold green][+][/bold green]  Starting dashboard at http://10.10.10.1:5000")

        subprocess.run(["python3", str(SERVER)])


    @classmethod
    def main(cls):
        """Run from here"""

        console.print(f"[bold green][+] War-rig starting")

        cls._unblock_rf()
        cls._setup_kismet_auth()

        if not cls._start_ap(): return False

        cls._set_monitor_mode()

        kismet = cls._start_kismet()
        flock  = cls._start_flock()

        cls._start_dashboard()

        if flock:  flock.kill()
        if kismet: kismet.kill()




if __name__ == "__main__":
    Boot.main()
