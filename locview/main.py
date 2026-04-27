import argparse
from rich import print

from locview.providers.geocode import reverse_geocode
from locview.providers.weather import get_weather
from locview.providers.poi import get_pois
from locview.utils.config import load_config
from locview.utils.platform import open_url
from locview.utils.browser import open_browser

from locview.tui.dashboard import run_dashboard

from locview.core.compare import compare_locations
from locview.core.polygon_scan import scan_bbox

from locview.export.compare_report import generate_compare_report
from locview.export.polygon_report import generate_polygon_report
from locview.export.heatmap_report import generate_heatmap_report
from locview.export.pdf_report import generate_pdf_report

from locview.alerts.geofence import add_geofence, check_geofences
from locview.intel.trends import analyze_trend
from locview.live.tracker import live_track
from locview.intel.risk import assess_risk
from locview.providers.plugins.registry import list_plugins


def cli_scan(args):
    geo = reverse_geocode(args.lat, args.lon)
    weather = get_weather(args.lat, args.lon)
    pois = get_pois(args.lat, args.lon, args.radius)

    print("[bold cyan]LOCVIEW REPORT[/bold cyan]")
    print(geo.get("display_name", "Unknown"))
    print(weather)

    risk = assess_risk(pois)

    print(f"[bold red]Risk Level:[/bold red] {risk['risk_level']}")
    print(f"[bold red]Risk Score:[/bold red] {risk['risk_score']}/100")

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
    heatmap = generate_heatmap_report(data)
    pdf = generate_pdf_report("LocView Polygon Area Scan", data)

    print("[green]Polygon Scan Report:[/green]", report)
    print("[green]Heatmap Visualization:[/green]", heatmap)
    print("[green]PDF Report:[/green]", pdf)

    open_browser(heatmap)


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

    gf_add = sub.add_parser("geofence-add")
    gf_add.add_argument("--name", required=True)
    gf_add.add_argument("--lat", type=float, required=True)
    gf_add.add_argument("--lon", type=float, required=True)
    gf_add.add_argument("--radius", type=int, required=True)

    gf_check = sub.add_parser("geofence-check")
    gf_check.add_argument("--lat", type=float, required=True)
    gf_check.add_argument("--lon", type=float, required=True)

    
    trend_cmd = sub.add_parser("trend")
    trend_cmd.add_argument("--lat", type=float, required=True)
    trend_cmd.add_argument("--lon", type=float, required=True)

    
    track_cmd = sub.add_parser("track")
    track_cmd.add_argument(
        "--points",
        nargs="+",
        required=True,
        help='Format: "lat,lon" "lat,lon"'
    )
    track_cmd.add_argument(
        "--interval",
        type=int,
        default=3
    )

    sub.add_parser("plugins")
    sub.add_parser("tui")

    args = parser.parse_args()

    if args.cmd == "scan":
        cli_scan(args)

    elif args.cmd == "compare":
        cli_compare(args)

    elif args.cmd == "polygon":
        cli_polygon(args)

    elif args.cmd == "geofence-add":
        add_geofence(args.name, args.lat, args.lon, args.radius)
        print("[green]Geofence Added[/green]")

    elif args.cmd == "geofence-check":
        hits = check_geofences(args.lat, args.lon)

        if not hits:
            print("[yellow]No Geofence Triggered[/yellow]")
        else:
            print("[bold red]Triggered Geofences:[/bold red]")
            for h in hits:
                print(
                    f"- {h['name']} "
                    f"({h['distance']}m / {h['radius']}m)"
                )

    
    elif args.cmd == "trend":
        result = analyze_trend(args.lat, args.lon)

        if result["status"] == "insufficient_data":
            print("[yellow]Insufficient history for trend analysis[/yellow]")
        else:
            print("[bold cyan]Trend Analysis[/bold cyan]")
            print(f"Latest POIs: {result['latest_poi_count']}")
            print(f"Historical Avg: {result['historical_average']}")
            print(f"Delta: {result['delta']}")
            print(f"Trend: {result['trend']}")


    
    elif args.cmd == "track":
        parsed = []

        for raw in args.points:
            try:
                lat, lon = raw.split(",")
                parsed.append((
                    float(lat.strip()),
                    float(lon.strip())
                ))
            except Exception:
                print(f"[ERROR] Invalid point: {raw}")
                return

        live_track(parsed, args.interval)


    
    elif args.cmd == "plugins":
        print("[bold cyan]Loaded Provider Plugins[/bold cyan]")
        for plugin in list_plugins():
            print("-", plugin)


    elif args.cmd == "tui":
        run_dashboard()

    else:
        parser.print_help()


if __name__ == "__main__":
    main()
