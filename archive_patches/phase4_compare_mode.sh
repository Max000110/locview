#!/usr/bin/env bash
set -e

########################################
# Compare Engine
########################################
cat > locview/core/compare.py <<'PYEOF'
from geopy.distance import geodesic

from locview.providers.geocode import reverse_geocode
from locview.providers.weather import get_weather
from locview.providers.poi import get_pois


def compare_locations(coords: list, radius=1000):
    results = []

    for lat, lon in coords:
        geo = reverse_geocode(lat, lon)
        weather = get_weather(lat, lon)
        pois = get_pois(lat, lon, radius)

        results.append({
            "lat": lat,
            "lon": lon,
            "geo": geo,
            "weather": weather,
            "pois": pois,
            "poi_count": len(pois)
        })

    distances = []

    for i in range(len(coords)):
        for j in range(i + 1, len(coords)):
            d = geodesic(coords[i], coords[j]).km
            distances.append(
                f"{coords[i]} ↔ {coords[j]} = {d:.2f} km"
            )

    return {
        "locations": results,
        "distances": distances
    }
PYEOF

########################################
# Compare Report Exporter
########################################
cat > locview/export/compare_report.py <<'PYEOF'
import os
import time

EXPORT_DIR = "/storage/emulated/0/Documents/LocViewReports"
os.makedirs(EXPORT_DIR, exist_ok=True)


def generate_compare_report(data):
    ts = int(time.time())
    out_path = os.path.join(EXPORT_DIR, f"locview_compare_{ts}.html")

    blocks = ""

    for idx, loc in enumerate(data["locations"], start=1):
        geo = loc["geo"]
        addr = geo.get("address", {})
        weather = loc["weather"]

        blocks += f"""
        <div class='card'>
            <h2>Location {idx}</h2>
            <p><b>Coords:</b> {loc['lat']}, {loc['lon']}</p>
            <p><b>Address:</b> {geo.get('display_name','Unknown')}</p>
            <p><b>Country:</b> {addr.get('country','N/A')}</p>
            <p><b>State:</b> {addr.get('state','N/A')}</p>
            <p><b>ZIP:</b> {addr.get('postcode','N/A')}</p>
            <p><b>Temp:</b> {weather.get('temperature','N/A')}°C</p>
            <p><b>POI Count:</b> {loc['poi_count']}</p>
        </div>
        """

    distance_html = "<br>".join(data["distances"])

    html = f"""
    <html>
    <head>
        <style>
            body {{
                font-family: Arial;
                background: #0b0f14;
                color: #fff;
                padding: 20px;
            }}
            .card {{
                background: #161b22;
                padding: 20px;
                margin-bottom: 20px;
                border-radius: 10px;
            }}
        </style>
    </head>
    <body>
        <h1>LocView Compare Report</h1>

        {blocks}

        <div class='card'>
            <h2>Distance Matrix</h2>
            <p>{distance_html}</p>
        </div>
    </body>
    </html>
    """

    with open(out_path, "w", encoding="utf-8") as f:
        f.write(html)

    return out_path
PYEOF

########################################
# CLI Compare Command Integration
########################################
cat > locview/main.py <<'PYEOF'
import argparse
from rich import print

from locview.providers.geocode import reverse_geocode
from locview.providers.weather import get_weather
from locview.providers.poi import get_pois
from locview.utils.config import load_config
from locview.utils.platform import open_url
from locview.tui.dashboard import run_dashboard

from locview.core.compare import compare_locations
from locview.export.compare_report import generate_compare_report
from locview.utils.browser import open_browser


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


def cli_compare(args):
    coords = []

    for raw in args.coords:
        lat, lon = raw.split(",")
        coords.append((float(lat), float(lon)))

    result = compare_locations(coords, args.radius)

    report = generate_compare_report(result)

    print("[green]Compare Report Generated:[/green]", report)

    open_browser(report)


def main():
    cfg = load_config()

    parser = argparse.ArgumentParser(prog="locview")
    sub = parser.add_subparsers(dest="cmd")

    scan = sub.add_parser("scan")
    scan.add_argument("--lat", required=True)
    scan.add_argument("--lon", required=True)
    scan.add_argument("--radius", type=int, default=cfg["default_radius"])
    scan.add_argument("--open", action="store_true")

    compare = sub.add_parser("compare")
    compare.add_argument(
        "--coords",
        nargs="+",
        required=True,
        help='Format: "lat,lon" "lat,lon"'
    )
    compare.add_argument("--radius", type=int, default=1000)

    sub.add_parser("tui")

    args = parser.parse_args()

    if args.cmd == "scan":
        cli_scan(args)
    elif args.cmd == "compare":
        cli_compare(args)
    elif args.cmd == "tui":
        run_dashboard()
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
PYEOF

pip install -e .

echo "[+] Multi-Coordinate Compare Mode Added"
