#!/usr/bin/env bash
set -e

########################################
# Polygon / Bounding Box Scan Engine
########################################
cat > locview/core/polygon_scan.py <<'PYEOF'
from locview.providers.poi import get_pois


def frange(start, stop, step):
    vals = []
    x = start
    while x <= stop:
        vals.append(round(x, 6))
        x += step
    return vals


def scan_bbox(lat_min, lon_min, lat_max, lon_max, step=0.01, radius=500):
    results = []

    lat_points = frange(lat_min, lat_max, step)
    lon_points = frange(lon_min, lon_max, step)

    for lat in lat_points:
        for lon in lon_points:
            pois = get_pois(lat, lon, radius)

            results.append({
                "lat": lat,
                "lon": lon,
                "poi_count": len(pois),
                "pois": pois[:10]
            })

    return sorted(
        results,
        key=lambda x: x["poi_count"],
        reverse=True
    )
PYEOF

########################################
# Polygon Scan Report Export
########################################
cat > locview/export/polygon_report.py <<'PYEOF'
import os
import time

EXPORT_DIR = "/storage/emulated/0/Documents/LocViewReports"
os.makedirs(EXPORT_DIR, exist_ok=True)


def generate_polygon_report(data):
    ts = int(time.time())
    out_path = os.path.join(
        EXPORT_DIR,
        f"locview_polygon_{ts}.html"
    )

    rows = ""

    for point in data[:50]:
        rows += f"""
        <tr>
            <td>{point['lat']}</td>
            <td>{point['lon']}</td>
            <td>{point['poi_count']}</td>
        </tr>
        """

    html = f"""
    <html>
    <head>
        <style>
            body {{
                font-family: Arial;
                background: #0b0f14;
                color: white;
                padding: 20px;
            }}
            table {{
                width: 100%;
                border-collapse: collapse;
            }}
            td, th {{
                border: 1px solid #333;
                padding: 10px;
            }}
        </style>
    </head>
    <body>
        <h1>LocView Polygon / Area Scan Report</h1>

        <table>
            <tr>
                <th>Latitude</th>
                <th>Longitude</th>
                <th>POI Count</th>
            </tr>
            {rows}
        </table>
    </body>
    </html>
    """

    with open(out_path, "w", encoding="utf-8") as f:
        f.write(html)

    return out_path
PYEOF

########################################
# CLI Integration
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

from locview.core.polygon_scan import scan_bbox
from locview.export.polygon_report import generate_polygon_report

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
        try:
            lat, lon = raw.split(",")
            coords.append((float(lat.strip()), float(lon.strip())))
        except Exception:
            print(f"[ERROR] Invalid coordinate format: {raw}")
            return

    result = compare_locations(coords, args.radius)
    report = generate_compare_report(result)

    print("[green]Compare Report Generated:[/green]", report)
    open_browser(report)


def cli_polygon(args):
    data = scan_bbox(
        args.lat_min,
        args.lon_min,
        args.lat_max,
        args.lon_max,
        args.step,
        args.radius
    )

    report = generate_polygon_report(data)

    print("[green]Polygon Scan Report:[/green]", report)
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
    compare.add_argument("--coords", nargs="+", required=True)
    compare.add_argument("--radius", type=int, default=1000)

    polygon = sub.add_parser("polygon")
    polygon.add_argument("--lat-min", type=float, required=True)
    polygon.add_argument("--lon-min", type=float, required=True)
    polygon.add_argument("--lat-max", type=float, required=True)
    polygon.add_argument("--lon-max", type=float, required=True)
    polygon.add_argument("--step", type=float, default=0.01)
    polygon.add_argument("--radius", type=int, default=500)

    sub.add_parser("tui")

    args = parser.parse_args()

    if args.cmd == "scan":
        cli_scan(args)
    elif args.cmd == "compare":
        cli_compare(args)
    elif args.cmd == "polygon":
        cli_polygon(args)
    elif args.cmd == "tui":
        run_dashboard()
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
PYEOF

pip install -e .

echo "[+] Polygon / Area Scan Mode Added"
