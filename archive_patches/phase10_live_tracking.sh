#!/usr/bin/env bash
set -e

########################################
# Live Tracking Engine
########################################
mkdir -p locview/live

cat > locview/live/tracker.py <<'PYEOF'
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
PYEOF

########################################
# Patch CLI Integration
########################################
python - <<'PYEOF'
from pathlib import Path

p = Path("locview/main.py")
text = p.read_text()

if "from locview.live.tracker import live_track" not in text:
    text = text.replace(
        "from locview.intel.trends import analyze_trend",
        "from locview.intel.trends import analyze_trend\nfrom locview.live.tracker import live_track"
    )

if 'track_cmd = sub.add_parser("track")' not in text:
    inject = '''
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
'''
    text = text.replace(
        'sub.add_parser("tui")',
        inject + '\n    sub.add_parser("tui")'
    )

if 'elif args.cmd == "track":' not in text:
    dispatch = '''
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
'''
    text = text.replace(
        'elif args.cmd == "tui":',
        dispatch + '\n\n    elif args.cmd == "tui":'
    )

p.write_text(text)
PYEOF

########################################
# Reinstall
########################################
pip install -e .

echo "[+] Real-Time GPS Live Tracking Integrated"
