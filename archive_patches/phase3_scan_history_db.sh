#!/usr/bin/env bash
set -e

########################################
# Database Layer
########################################
mkdir -p locview/db

cat > locview/db/history.py <<'PYEOF'
import os
import sqlite3
import json
import time

DB_PATH = os.path.expanduser("~/.locview/history.db")


def init_db():
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)

    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    cur.execute("""
    CREATE TABLE IF NOT EXISTS scans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp INTEGER,
        lat TEXT,
        lon TEXT,
        radius INTEGER,
        geo_json TEXT,
        weather_json TEXT,
        pois_json TEXT,
        screenshot_path TEXT
    )
    """)

    conn.commit()
    conn.close()


def save_scan(lat, lon, radius, geo, weather, pois, screenshot):
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    cur.execute("""
    INSERT INTO scans (
        timestamp, lat, lon, radius,
        geo_json, weather_json, pois_json,
        screenshot_path
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        int(time.time()),
        lat,
        lon,
        radius,
        json.dumps(geo),
        json.dumps(weather),
        json.dumps(pois),
        screenshot
    ))

    conn.commit()
    conn.close()


def get_recent_scans(limit=10):
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    cur.execute("""
    SELECT id, timestamp, lat, lon, radius
    FROM scans
    ORDER BY timestamp DESC
    LIMIT ?
    """, (limit,))

    rows = cur.fetchall()
    conn.close()

    return rows
PYEOF

########################################
# Patch Dashboard Integration
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
from locview.db.history import init_db, save_scan, get_recent_scans


def clean_coord(val: str) -> str:
    return val.strip().replace("°", "").replace(",", "").replace(" ", "")


class LocViewDashboard(App):
    ENABLE_COMMAND_PALETTE = False

    CSS = """
    Screen { layout: vertical; }

    #main { layout: horizontal; height: 1fr; }
    #left { width: 28%; border: round cyan; padding: 1; }
    #right { width: 72%; border: round green; padding: 1; }

    #poi_table {
        height: 10;
        margin-top: 1;
    }

    #history_box {
        border: round magenta;
        height: 10;
        margin-top: 1;
        padding: 1;
    }

    #preview {
        border: round yellow;
        padding: 1;
        margin-top: 1;
        height: 8;
    }

    Input, Button { margin-top: 1; }

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
                yield Button("Export HTML Report", id="export")

            with Vertical(id="right"):
                yield Static("Awaiting Scan...", id="results")
                yield DataTable(id="poi_table")
                yield Static("Recent Scan History Loading...", id="history_box")
                yield Static("No Preview Yet", id="preview")

        yield Footer()

    def on_mount(self):
        init_db()

        self.query_one("#poi_table", DataTable).add_columns("POI", "Type")

        self.last_scan = None
        self.last_screenshot = None

        self.refresh_history()

    def refresh_history(self):
        scans = get_recent_scans()

        lines = ["Recent Scan History:\n"]

        for sid, ts, lat, lon, radius in scans:
            lines.append(
                f"#{sid} | {lat},{lon} | {radius}m"
            )

        self.query_one("#history_box", Static).update(
            "\n".join(lines)
        )

    async def on_button_pressed(self, event: Button.Pressed):
        if event.button.id == "scan":
            lat = clean_coord(self.query_one("#lat", Input).value)
            lon = clean_coord(self.query_one("#lon", Input).value)

            try:
                radius = int(self.query_one("#radius", Input).value)
            except:
                radius = 1000

            geo = reverse_geocode(lat, lon)
            weather = get_weather(lat, lon)
            pois = get_pois(lat, lon, radius)

            screenshot = fetch_static_map(
                satellite_preview_url(lat, lon)
            )

            save_scan(
                lat, lon, radius,
                geo, weather, pois,
                screenshot
            )

            self.refresh_history()

            self.last_scan = {
                "geo": geo,
                "weather": weather,
                "pois": pois
            }

            self.last_screenshot = screenshot

            if screenshot:
                open_folder(screenshot)

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

            self.query_one("#preview", Static).update(
                f"Screenshot Saved:\n{screenshot or 'Failed'}"
            )

        elif event.button.id == "export":
            if not self.last_scan:
                self.query_one("#preview", Static).update(
                    "Run scan first."
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

echo "[+] SQLite Scan History Database Integrated"
