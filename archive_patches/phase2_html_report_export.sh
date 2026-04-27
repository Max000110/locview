#!/usr/bin/env bash
set -e

########################################
# HTML Report Generator
########################################
mkdir -p locview/export

cat > locview/export/html_report.py <<'PYEOF'
import os
import time


EXPORT_DIR = "/storage/emulated/0/Documents/LocViewReports"
os.makedirs(EXPORT_DIR, exist_ok=True)


def generate_html_report(scan_data: dict, screenshot_path: str = None):
    ts = int(time.time())
    out_path = os.path.join(EXPORT_DIR, f"locview_report_{ts}.html")

    geo = scan_data.get("geo", {})
    addr = geo.get("address", {})
    weather = scan_data.get("weather", {})
    pois = scan_data.get("pois", [])

    poi_rows = ""
    for poi in pois[:25]:
        tags = poi.get("tags", {})
        poi_rows += f"""
        <tr>
            <td>{tags.get('name', 'Unnamed')}</td>
            <td>{tags.get('amenity') or tags.get('tourism') or tags.get('shop') or 'POI'}</td>
        </tr>
        """

    img_html = ""
    if screenshot_path and os.path.exists(screenshot_path):
        img_html = f'<img src="{screenshot_path}" style="max-width:100%;border-radius:8px;">'

    html = f"""
    <html>
    <head>
        <title>LocView Report</title>
        <style>
            body {{
                font-family: Arial;
                background: #0b0f14;
                color: #e6edf3;
                padding: 30px;
            }}
            .card {{
                background: #161b22;
                padding: 20px;
                margin-bottom: 20px;
                border-radius: 12px;
            }}
            table {{
                width: 100%;
                border-collapse: collapse;
            }}
            td, th {{
                border: 1px solid #30363d;
                padding: 10px;
            }}
            th {{
                background: #21262d;
            }}
        </style>
    </head>
    <body>

        <h1>LocView Geospatial Intel Report</h1>

        <div class="card">
            <h2>Location Details</h2>
            <p><b>Address:</b> {geo.get("display_name","Unknown")}</p>
            <p><b>Country:</b> {addr.get("country","N/A")}</p>
            <p><b>State:</b> {addr.get("state","N/A")}</p>
            <p><b>City:</b> {addr.get("city","N/A")}</p>
            <p><b>ZIP:</b> {addr.get("postcode","N/A")}</p>
        </div>

        <div class="card">
            <h2>Weather</h2>
            <p><b>Temperature:</b> {weather.get("temperature","N/A")}°C</p>
            <p><b>Wind Speed:</b> {weather.get("windspeed","N/A")} km/h</p>
        </div>

        <div class="card">
            <h2>Satellite Preview</h2>
            {img_html}
        </div>

        <div class="card">
            <h2>Nearby POIs</h2>
            <table>
                <tr><th>Name</th><th>Type</th></tr>
                {poi_rows}
            </table>
        </div>

    </body>
    </html>
    """

    with open(out_path, "w", encoding="utf-8") as f:
        f.write(html)

    return out_path
PYEOF

########################################
# Add Browser Open Utility
########################################
cat > locview/utils/browser.py <<'PYEOF'
import subprocess
import shutil


def open_browser(path: str):
    try:
        if shutil.which("termux-open"):
            subprocess.run(["termux-open", path], check=False)
    except:
        pass
PYEOF

########################################
# Patch Dashboard with Export Button
########################################
cat > locview/tui/dashboard.py <<'PYEOF'
from textual.app import App, ComposeResult
from textual.containers import Horizontal, Vertical
from textual.widgets import Header, Footer, Static, Input, Button, DataTable

from locview.providers.geocode import reverse_geocode
from locview.providers.weather import get_weather
from locview.providers.poi import get_pois
from locview.providers.maps import satellite_preview_url
from locview.providers.screenshot import fetch_static_map
from locview.utils.viewer import open_folder
from locview.export.html_report import generate_html_report
from locview.utils.browser import open_browser


def clean_coord(val: str) -> str:
    return val.strip().replace("°", "").replace(",", "").replace(" ", "")


class LocViewDashboard(App):
    ENABLE_COMMAND_PALETTE = False

    def compose(self) -> ComposeResult:
        yield Header()

        with Horizontal():
            with Vertical():
                yield Static("LOCVIEW INPUT PANEL")
                yield Input(placeholder="Latitude", id="lat")
                yield Input(placeholder="Longitude", id="lon")
                yield Input(value="1000", placeholder="Radius", id="radius")
                yield Button("Run Scan", id="scan")
                yield Button("Export HTML Report", id="export")

            with Vertical():
                yield Static("Awaiting Scan...", id="results")
                yield DataTable(id="poi_table")
                yield Static("No Preview Yet", id="preview")

        yield Footer()

    def on_mount(self):
        self.query_one(DataTable).add_columns("POI", "Type")
        self.last_scan = None
        self.last_screenshot = None

    async def on_button_pressed(self, event: Button.Pressed):
        if event.button.id == "scan":
            lat = clean_coord(self.query_one("#lat", Input).value)
            lon = clean_coord(self.query_one("#lon", Input).value)
            radius = int(self.query_one("#radius", Input).value or 1000)

            geo = reverse_geocode(lat, lon)
            weather = get_weather(lat, lon)
            pois = get_pois(lat, lon, radius)

            screenshot = fetch_static_map(satellite_preview_url(lat, lon))

            self.last_scan = {
                "geo": geo,
                "weather": weather,
                "pois": pois
            }
            self.last_screenshot = screenshot

            if screenshot:
                open_folder(screenshot)

            self.query_one("#results", Static).update(
                geo.get("display_name", "Unknown")
            )

            table = self.query_one(DataTable)
            table.clear()

            for poi in pois[:20]:
                tags = poi.get("tags", {})
                table.add_row(
                    tags.get("name", "Unnamed"),
                    tags.get("amenity")
                    or tags.get("tourism")
                    or "POI"
                )

            self.query_one("#preview", Static).update(
                f"Saved Screenshot:\n{screenshot}"
            )

        elif event.button.id == "export":
            if not self.last_scan:
                self.query_one("#preview", Static).update(
                    "Run a scan first before exporting."
                )
                return

            report = generate_html_report(
                self.last_scan,
                self.last_screenshot
            )

            open_browser(report)

            self.query_one("#preview", Static).update(
                f"HTML Report Exported:\n{report}"
            )


def run_dashboard():
    LocViewDashboard().run()
PYEOF

pip install -e .

echo "[+] HTML Report Export Integrated"
