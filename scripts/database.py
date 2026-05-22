# THIS WILL HOUSE DATABASE AND BACKGROUND THREAD LOGIC FOR THE WAR RIG


# UI IMPORTS
from rich.console import Console


# ETC IMPORTS
import threading, subprocess, time


# CONSTANTS
console = Console()




class Variables():
    """Program wide variables"""


    delay = 0.125
    hops  = [1, 6, 11, 36, 40, 44, 48, 149, 153, 157, 161]

    presets = {
        "2.4": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
        "5":   [36, 40, 44, 48, 149, 153, 157, 161],
        "all": [1, 6, 11, 36, 40, 44, 48, 149, 153, 157, 161]
    }

    console = Console()




class Utilities():
    """This will house utility methods for the war rig"""


    @staticmethod
    def unblock_rf():
        """Unblock all RF interfaces"""

        try:
            subprocess.run(["rfkill", "unblock", "all"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except Exception as e: console.print(f"[bold red]Exception Error:[bold yellow] {e}")


    @staticmethod
    def set_monitor_mode(iface, verbose=False):
        """Put an interface into monitor mode"""

        try:
            subprocess.run(["ip",  "link", "set", iface, "down"],           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            subprocess.run(["iw",  "dev",  iface, "set", "type", "monitor"],stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            subprocess.run(["ip",  "link", "set", iface, "up"],             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

            if verbose: console.print(f"[bold green][+] {iface} -> monitor mode")

        except Exception as e: console.print(f"[bold red]Exception Error:[bold yellow] {e}")




class Background_Threads():
    """This module will house background permanent running threads"""


    hop     = True
    channel = 0


    @classmethod
    def channel_hopper(cls, iface, set_channel=False, verbose=False):
        """This method will be responsible for automatically hopping channels"""


        def hopper():

            delay    = Variables.delay
            all_hops = Variables.hops


            if set_channel:

                cls.hop = False

                try:
                    subprocess.run(
                        ["sudo", "iw", "dev", iface, "set", "channel", str(set_channel)],
                        stdout=subprocess.DEVNULL,
                        stderr=subprocess.DEVNULL
                    )

                except Exception as e: console.print(f"[bold red]Exception Error:[bold yellow] {e}")

                return


            while cls.hop:

                for channel in all_hops:

                    if not cls.hop: break

                    try:
                        subprocess.run(
                            ["sudo", "iw", "dev", iface, "set", "channel", str(channel)],
                            stdout=subprocess.DEVNULL,
                            stderr=subprocess.DEVNULL
                        )
                        cls.channel = channel
                        if verbose: console.print(f"[bold green]Hopping on Channel:[bold yellow] {channel}")
                        time.sleep(delay)

                    except Exception as e: console.print(f"[bold red]Exception Error:[bold yellow] {e}")


        cls.hop = True
        threading.Thread(target=hopper, args=(), daemon=True).start()
