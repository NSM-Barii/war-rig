from http.server import HTTPServer, BaseHTTPRequestHandler
import json, os

# ── CONFIG ────────────────────────────────────────────────
PORT         = 5000
FLOCKS_JSON  = "/home/pi/flock-back/src/database/flocks.json"
PACKETS_JSON = "/home/pi/flock-back/src/database/packets.json"
DASHBOARD    = os.path.join(os.path.dirname(__file__), "dashboard.html")
# ──────────────────────────────────────────────────────────


class Handler(BaseHTTPRequestHandler):

    def do_GET(self):
        if self.path == "/":
            self._serve_html()
        elif self.path == "/data":
            self._serve_data()
        else:
            self.send_response(404)
            self.end_headers()

    def _serve_html(self):
        try:
            with open(DASHBOARD, "rb") as f:
                content = f.read()
            self.send_response(200)
            self.send_header("Content-Type", "text/html")
            self.end_headers()
            self.wfile.write(content)
        except FileNotFoundError:
            self.send_response(404)
            self.end_headers()

    def _serve_data(self):
        devices = []
        try:
            with open(FLOCKS_JSON, "r") as f:
                for line in f:
                    line = line.strip()
                    if line:
                        devices.append(json.loads(line))
        except FileNotFoundError:
            pass

        # build a map of mac -> max frame_count from packets.json
        packet_counts = {}
        try:
            with open(PACKETS_JSON, "r") as f:
                for line in f:
                    line = line.strip()
                    if not line:
                        continue
                    entry = json.loads(line)
                    mac   = entry.get("mac")
                    count = entry.get("frame_count", 0)
                    if mac and count > packet_counts.get(mac, 0):
                        packet_counts[mac] = count
        except FileNotFoundError:
            pass

        # enrich each device with its packet hit count
        for device in devices:
            mac = device.get("mac")
            device["frame_count"] = packet_counts.get(mac, 0)

        payload = json.dumps(devices).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(payload)

    def log_message(self, format, *args):
        pass  # suppress per-request logs


if __name__ == "__main__":
    server = HTTPServer(("0.0.0.0", PORT), Handler)
    print(f"[+] Dashboard → http://10.10.10.1:{PORT}")
    server.serve_forever()
