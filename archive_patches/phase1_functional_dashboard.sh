#!/usr/bin/env bash
set -e

cat > locview/tui/dashboard.py <<'PYEOF'
from textual.app import App, ComposeResult
from textual.containers import Horizontal, Vertical
from textual.widgets import Header, Footer, Static, Input, Button, DataTable

from locview.providers.geocode import reverse_geocode
from locview.providers.weather import get_weather
from locview.providers.poi import get_pois


class LocViewDashboard(App):
    CSS = """
    Screen {
        layout: vertical;
    }

    #main {
        layout: horizontal;
        height: 1fr;
    }

    #left {
        width: 30%;
        border: round cyan;
        padding: 1;
    }

    #right {
        width: 70%;
        border: round green;
        padding: 1;
    }

    #poi_table {
        height: 18;
        margin-top: 1;
    }

    Input, Button {
        margin-top: 1;
    }
    """

    def compose(self) -> ComposeResult:
        yield Header()

        with Horizontal(id="main"):
            with Vertical(id="left"):
                yield Static("LOCVIEW INPUT PANEL")
                yield Input(placeholder="Latitude", id="lat")
                yield Input(placeholder="Longitude", id="lon")
                yield Input(value="1000", placeholder="Radius (meters)", id="radius")
                yield Button("Run Scan", id="scan")

            with Vertical(id="right"):
                yield Static("Awaiting Scan...", id="results")
                yield DataTable(id="poi_table")

        yield Footer()

    def on_mount(self):
        table = self.query_one("#poi_table", DataTable)
        table.add_columns("POI", "Type")

    async def on_button_pressed(self, event: Button.Pressed):
        if event.button.id != "scan":
            return

        lat = self.query_one("#lat", Input).value.strip()
        lon = self.query_one("#lon", Input).value.strip()
        radius = self.query_one("#radius", Input).value.strip()

        if not lat or not lon:
            self.query_one("#results", Static).update(
                "[red]Latitude and Longitude required[/red]"
            )
            return

        try:
            radius = int(radius)
        except:
            radius = 1000

        self.query_one("#results", Static).update("Scanning...")

        geo = reverse_geocode(lat, lon)
        weather = get_weather(lat, lon)
        pois = get_pois(lat, lon, radius)

        addr = geo.get("address", {})
        display = geo.get("display_name", "Unknown")

        result_text = f"""
Address:
{display}

Country: {addr.get('country', 'N/A')}
State: {addr.get('state', 'N/A')}
City: {addr.get('city') or addr.get('town') or 'N/A'}
ZIP: {addr.get('postcode', 'N/A')}

Weather:
Temperature: {weather.get('temperature', 'N/A')}°C
Wind Speed: {weather.get('windspeed', 'N/A')} km/h
"""

        self.query_one("#results", Static).update(result_text)

        table = self.query_one("#poi_table", DataTable)
        table.clear()

        for poi in pois[:20]:
            tags = poi.get("tags", {})
            name = tags.get("name", "Unnamed")
            kind = (
                tags.get("amenity")
                or tags.get("tourism")
                or tags.get("shop")
                or "POI"
            )
            table.add_row(name, kind)


def run_dashboard():
    LocViewDashboard().run()
PYEOF

echo "[+] Functional Dashboard Patch Applied"
echo "[+] Reinstall: pip install -e ."
