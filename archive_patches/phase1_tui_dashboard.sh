#!/usr/bin/env bash
set -e

mkdir -p locview/locview/tui

########################################
# TUI Dashboard
########################################
cat > locview/locview/tui/dashboard.py <<'PYEOF'
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
    }

    #left {
        width: 35%;
        border: round cyan;
        padding: 1;
    }

    #right {
        width: 65%;
        border: round green;
        padding: 1;
    }

    Input {
        margin: 1 0;
    }

    Button {
        margin-top: 1;
    }
    """

    def compose(self) -> ComposeResult:
        yield Header()

        with Horizontal(id="main"):
            with Vertical(id="left"):
                yield Static("LOCVIEW SCAN PANEL")
                yield Input(placeholder="Latitude", id="lat")
                yield Input(placeholder="Longitude", id="lon")
                yield Button("Run Scan", id="scan")

            with Vertical(id="right"):
                yield Static("Results", id="results")
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

        if not lat or not lon:
            self.query_one("#results", Static).update("Latitude/Longitude required")
            return

        geo = reverse_geocode(lat, lon)
        weather = get_weather(lat, lon)
        pois = get_pois(lat, lon, 1000)

        addr = geo.get("display_name", "Unknown")
        temp = weather.get("temperature", "N/A")
        wind = weather.get("windspeed", "N/A")

        result_text = f"""
Address:
{addr}

Weather:
Temperature: {temp}°C
Wind Speed: {wind} km/h
"""

        self.query_one("#results", Static).update(result_text)

        table = self.query_one("#poi_table", DataTable)
        table.clear()

        for poi in pois[:15]:
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

########################################
# Patch main.py
########################################
cat > locview/locview/main.py <<'PYEOF'
import argparse
from rich import print

from locview.providers.geocode import reverse_geocode
from locview.providers.weather import get_weather
from locview.providers.poi import get_pois
from locview.utils.config import load_config
from locview.utils.platform import open_url
from locview.tui.dashboard import run_dashboard


def cli_scan(args):
    geo = reverse_geocode(args.lat, args.lon)
    weather = get_weather(args.lat, args.lon)
    pois = get_pois(args.lat, args.lon, args.radius)

    print("[bold cyan]LOCVIEW REPORT[/bold cyan]")
    print(geo.get("display_name", "Unknown"))
    print(weather)

    print("\n[bold yellow]POIs[/bold yellow]")
    for poi in pois[:10]:
        tags = poi.get("tags", {})
        print("-", tags.get("name", "Unnamed"))

    if args.open:
        open_url(f"https://www.google.com/maps?q={args.lat},{args.lon}")


def main():
    cfg = load_config()

    parser = argparse.ArgumentParser(prog="locview")
    sub = parser.add_subparsers(dest="cmd")

    scan = sub.add_parser("scan")
    scan.add_argument("--lat", required=True)
    scan.add_argument("--lon", required=True)
    scan.add_argument("--radius", type=int, default=cfg["default_radius"])
    scan.add_argument("--open", action="store_true")

    sub.add_parser("tui")

    args = parser.parse_args()

    if args.cmd == "scan":
        cli_scan(args)
    elif args.cmd == "tui":
        run_dashboard()
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
PYEOF

echo "[+] Phase 1 TUI Dashboard Added"
echo "[+] Reinstall with: pip install -e ."
