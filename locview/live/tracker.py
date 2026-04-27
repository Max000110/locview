import time
from rich import print
from locview.alerts.geofence import check_geofences
from locview.intel.trends import analyze_trend


def live_track(path_points, interval=3):
    print("[bold cyan]Starting Live Tracking Session[/bold cyan]\n")

    for idx, (lat, lon) in enumerate(path_points, start=1):
        print(f"[green]Point #{idx}[/green] -> {lat}, {lon}")

        hits = check_geofences(lat, lon)
        if hits:
            print("[bold red]Geofence Alerts:[/bold red]")
            for h in hits:
                print(
                    f" - {h['name']} "
                    f"({h['distance']}m / {h['radius']}m)"
                )

        trend = analyze_trend(lat, lon)

        if trend.get("status") == "ok":
            print(
                f"[yellow]Trend:[/yellow] "
                f"{trend['trend']} "
                f"(Δ {trend['delta']})"
            )

        print("-" * 40)
        time.sleep(interval)
