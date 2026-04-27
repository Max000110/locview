from textual.app import App, ComposeResult
from textual.containers import Horizontal, Vertical
from textual.widgets import Header, Footer, Static, Button, Input, Select, DataTable

from locview.providers.geocode import reverse_geocode
from locview.providers.weather import get_weather
from locview.providers.poi import get_pois
from locview.providers.screenshot import save_satellite_screenshot
from locview.providers.maps import google_maps_url, google_earth_url

from locview.export.html_report import generate_html_report
from locview.export.pdf_report import generate_pdf_report

from locview.core.polygon_scan import scan_bbox
from locview.export.heatmap_report import generate_heatmap_report
from locview.utils.browser import open_browser


PLANET_LOGO = r"""
⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⣀⣀⣀
⠀⠀⠀⠀⠀⣠⣶⣿⣿⣿⣿⣿⣿⣷⣄
⠀⠀⠀⠀⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷
⠀⠀⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧
⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⠀⠀⠀⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿
⠀⠀⠀⠀⠙⢿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠋
"""

THEMES = {
    "dark": "🌍 LOCVIEW // DARK OPS",
    "green": "🟢 LOCVIEW // MATRIX",
    "purple": "🪐 LOCVIEW // NEBULA",
    "amber": "🛰 LOCVIEW // AMBER RADAR",
}


class Dashboard(App):
    CSS = """
    Screen { background: #0b0f14; }

    #hero {
        height: 6;
        border: round cyan;
        content-align: center middle;
        margin: 1;
    }

    #left {
        width: 28%;
        border: round green;
        padding: 1;
        margin: 1;
    }

    #right {
        width: 72%;
        border: round cyan;
        padding: 1;
        margin: 1;
    }

    #satellite-box {
        height: 20;
        border: round yellow;
        margin-top: 1;
    }

    #planet-logo {
        color: lime;
        content-align: center middle;
        height: 12;
        margin-top: 1;
    }

    Input, Select, Button { margin: 1 0; }

    DataTable {
        height: 12;
        margin-top: 1;
    }
    """

    theme_name = "dark"
    last_scan = None
    last_png = None
    last_html = None
    last_pdf = None
    last_polygon_report = None

    def compose(self) -> ComposeResult:
        yield Header()

        yield Static(
            f"{THEMES[self.theme_name]}\nSatellite • Intelligence • Reconnaissance",
            id="hero"
        )

        with Horizontal():
            with Vertical(id="left"):
                yield Input(value="19.1606", id="lat")
                yield Input(value="72.8479", id="lon")
                yield Input(value="1000", id="radius")

                yield Select(
                    [
                        ("Dark Ops", "dark"),
                        ("Matrix Green", "green"),
                        ("Nebula Purple", "purple"),
                        ("Amber Radar", "amber"),
                    ],
                    value="dark",
                    id="theme-select"
                )

                yield Button("Run Scan", id="scan_btn", variant="primary")
                yield Button("Polygon Heatmap", id="polygon_btn")
                yield Button("Open HTML Report", id="export_btn")
                yield Button("Open Polygon Report", id="polygon_report_btn")

            with Vertical(id="right"):
                yield Static("Awaiting Scan...", id="results")

                table = DataTable(id="poi-table")
                table.add_columns("POI", "Type")
                yield table

                yield Static("Satellite / Export Info Pending...", id="satellite-box")
                yield Static(PLANET_LOGO, id="planet-logo")

        yield Footer()

    def on_select_changed(self, event: Select.Changed) -> None:
        if event.select.id != "theme-select":
            return

        self.theme_name = event.value
        self.query_one("#hero", Static).update(
            f"{THEMES[self.theme_name]}\nSatellite • Intelligence • Reconnaissance"
        )

    async def on_button_pressed(self, event: Button.Pressed) -> None:
        results = self.query_one("#results", Static)
        sat = self.query_one("#satellite-box", Static)

        lat = float(self.query_one("#lat", Input).value)
        lon = float(self.query_one("#lon", Input).value)
        radius = int(self.query_one("#radius", Input).value)

        try:
            if event.button.id == "scan_btn":
                address = reverse_geocode(lat, lon)
                weather = get_weather(lat, lon)
                pois = get_pois(lat, lon, radius)

                png = save_satellite_screenshot(lat, lon)

                payload = {
                    "geo": address,
                    "weather": weather,
                    "pois": pois
                }

                html = generate_html_report(payload, png)
                pdf = generate_pdf_report(
                    "LocView Scan Report",
                    [{"lat": lat, "lon": lon, "poi_count": len(pois)}]
                )

                self.last_scan = payload
                self.last_png = png
                self.last_html = html
                self.last_pdf = pdf

                results.update(
                    f"Address:\n{address.get('display_name','Unknown')}\n\n"
                    f"Temp: {weather.get('temperature','?')}°C\n"
                    f"Wind: {weather.get('windspeed','?')} km/h"
                )

                table = self.query_one("#poi-table", DataTable)
                table.clear()

                for poi in pois[:15]:
                    tags = poi.get("tags", {})
                    table.add_row(
                        tags.get("name", "Unnamed"),
                        tags.get("amenity", tags.get("shop", "POI"))
                    )

                sat.update(
                    f"PNG Export:\n{png}\n\n"
                    f"Google Maps:\n{google_maps_url(lat, lon)}\n\n"
                    f"Google Earth:\n{google_earth_url(lat, lon)}\n\n"
                    f"HTML Report:\n{html}\n\n"
                    f"PDF Report:\n{pdf}"
                )

                open_browser(html)

            elif event.button.id == "export_btn":
                if self.last_html:
                    open_browser(self.last_html)
                    sat.update(f"Opened Report:\n{self.last_html}")
                else:
                    sat.update("Run scan first.")


            elif event.button.id == "polygon_report_btn":
                if self.last_polygon_report:
                    open_browser(self.last_polygon_report)
                    sat.update(
                        f"Opened Polygon Report:\n{self.last_polygon_report}"
                    )
                else:
                    sat.update("Run polygon scan first.")

            elif event.button.id == "polygon_btn":
                data = scan_bbox(
                    lat - 0.01,
                    lon - 0.01,
                    lat + 0.01,
                    lon + 0.01,
                    step=0.01,
                    radius=radius
                )

                polygon_report = generate_polygon_report(data)
                heatmap = generate_heatmap_report(data)

                self.last_polygon_report = polygon_report
                self.last_heatmap = heatmap

                open_browser(heatmap)

                sat.update(
                    f"Polygon Heatmap Generated:\n{heatmap}\n\n"
                    f"Polygon Report:\n{polygon_report}"
                )

        except Exception as e:
            results.update(f"[ERROR]\n{e}")


def run_dashboard():
    Dashboard().run()
