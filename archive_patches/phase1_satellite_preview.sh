#!/usr/bin/env bash
set -e

########################################
# Map Provider Helper
########################################
mkdir -p locview/providers

cat > locview/providers/maps.py <<'PYEOF'
def satellite_preview_url(lat, lon, zoom=17):
    # Static OSM map preview via third-party static map endpoint
    # Replace provider later if desired
    return (
        f"https://staticmap.openstreetmap.de/staticmap.php"
        f"?center={lat},{lon}&zoom={zoom}&size=800x400&maptype=mapnik"
        f"&markers={lat},{lon},red-pushpin"
    )

def google_maps_url(lat, lon):
    return f"https://www.google.com/maps?q={lat},{lon}"

def google_earth_url(lat, lon):
    return f"https://earth.google.com/web/@{lat},{lon},500a"
PYEOF

########################################
# Enhanced Dashboard with Preview Panel
########################################
cat > locview/tui/dashboard.py <<'PYEOF'
from textual.app import App, ComposeResult
from textual.containers import Horizontal, Vertical
from textual.widgets import Header, Footer, Static, Input, Button, DataTable

from locview.providers.geocode import reverse_geocode
from locview.providers.weather import get_weather
from locview.providers.poi import get_pois
from locview.providers.maps import satellite_preview_url


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
        height: 8;
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
                yield Static("Satellite Preview URL will appear here", id="preview")

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

        addr = geo.get("address", {})
        preview_url = satellite_preview_url(lat, lon)

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
            f"[yellow]Satellite Preview URL:[/yellow]\n{preview_url}"
        )


def run_dashboard():
    LocViewDashboard().run()
PYEOF

echo "[+] Satellite Preview Integration Added"
echo "[+] Reinstall with: pip install -e ."
