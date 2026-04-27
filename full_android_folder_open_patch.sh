#!/usr/bin/env bash
set -e

########################################
# Viewer Helper
########################################
cat > locview/utils/viewer.py <<'PYEOF'
import os
import subprocess
import shutil


def open_folder(path: str):
    folder = os.path.dirname(path)

    try:
        if shutil.which("termux-open"):
            subprocess.run(["termux-open", folder], check=False)
            return

        if shutil.which("termux-open-url"):
            subprocess.run(["termux-open-url", f"file://{folder}"], check=False)

    except Exception as e:
        print("[DEBUG Viewer Error]", e)
PYEOF

########################################
# Patch Dashboard
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


def clean_coord(val: str) -> str:
    return val.strip().replace("°", "").replace(",", "").replace(" ", "")


class LocViewDashboard(App):
    CSS = """
    Screen { layout: vertical; }

    #main {
        layout: horizontal;
        height: 1fr;
    }

    #left {
        width: 28%;
        border: round cyan;
        padding: 1;
    }

    #right {
        width: 72%;
        border: round green;
        padding: 1;
    }

    #poi_table {
        height: 12;
        margin-top: 1;
    }

    #preview {
        border: round yellow;
        padding: 1;
        margin-top: 1;
        height: 10;
    }

    Input, Button {
        margin-top: 1;
    }

    .label {
        color: cyan;
        margin-top: 1;
    }
    """

    def compose(self) -> ComposeResult:
        yield Header()

        with Horizontal(id="main"):
            with Vertical(id="left"):
                yield Static("LOCVIEW INPUT PANEL")

                yield Static("Latitude", classes="label")
                yield Input(id="lat")

                yield Static("Longitude", classes="label")
                yield Input(id="lon")

                yield Static("Scan Radius (meters)", classes="label")
                yield Input(value="1000", id="radius")

                yield Button("Run Scan", id="scan")

            with Vertical(id="right"):
                yield Static("Awaiting Scan...", id="results")
                yield DataTable(id="poi_table")
                yield Static("No Preview Yet", id="preview")

        yield Footer()

    def on_mount(self):
        self.query_one("#poi_table", DataTable).add_columns("POI", "Type")

    async def on_button_pressed(self, event: Button.Pressed):
        if event.button.id != "scan":
            return

        lat = clean_coord(self.query_one("#lat", Input).value)
        lon = clean_coord(self.query_one("#lon", Input).value)

        try:
            radius = int(self.query_one("#radius", Input).value)
        except:
            radius = 1000

        self.query_one("#results", Static).update("Scanning...")

        geo = reverse_geocode(lat, lon)
        weather = get_weather(lat, lon)
        pois = get_pois(lat, lon, radius)

        preview_url = satellite_preview_url(lat, lon)
        screenshot_path = fetch_static_map(preview_url)

        if screenshot_path:
            open_folder(screenshot_path)

        addr = geo.get("address", {})

        self.query_one("#results", Static).update(f"""
Address:
{geo.get("display_name", "Unknown")}

Country: {addr.get("country", "N/A")}
State: {addr.get("state", "N/A")}
City: {addr.get("city") or addr.get("town") or "N/A"}
ZIP: {addr.get("postcode", "N/A")}

Weather:
Temperature: {weather.get("temperature", "N/A")}°C
Wind Speed: {weather.get("windspeed", "N/A")} km/h

Radius: {radius}m
""")

        table = self.query_one("#poi_table", DataTable)
        table.clear()

        for poi in pois[:20]:
            tags = poi.get("tags", {})
            table.add_row(
                tags.get("name", "Unnamed"),
                tags.get("amenity")
                or tags.get("tourism")
                or tags.get("shop")
                or "POI"
            )

        display_path = screenshot_path.split("/")[-1] if screenshot_path else "Failed"

        self.query_one("#preview", Static).update(
            f"Screenshot Saved:\n/storage/emulated/0/Pictures/LocView/{display_path}\n\nFolder Opened."
        )


def run_dashboard():
    LocViewDashboard().run()
PYEOF

pip install -e .

echo "[+] Full Android Folder-Open Patch Applied Successfully"
