#!/usr/bin/env bash
set -e

########################################
# Create Geofence Module
########################################
mkdir -p locview/alerts

cat > locview/alerts/geofence.py <<'PYEOF'
import math
import json
import os
import time

GEOFENCE_DB = os.path.expanduser("~/.locview/geofences.json")
os.makedirs(os.path.dirname(GEOFENCE_DB), exist_ok=True)


def haversine(lat1, lon1, lat2, lon2):
    R = 6371000
    p1 = math.radians(lat1)
    p2 = math.radians(lat2)
    d1 = math.radians(lat2 - lat1)
    d2 = math.radians(lon2 - lon1)

    a = math.sin(d1 / 2) ** 2 + \
        math.cos(p1) * math.cos(p2) * math.sin(d2 / 2) ** 2

    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


def load_geofences():
    if not os.path.exists(GEOFENCE_DB):
        return []
    with open(GEOFENCE_DB) as f:
        return json.load(f)


def save_geofences(data):
    with open(GEOFENCE_DB, "w") as f:
        json.dump(data, f, indent=2)


def add_geofence(name, lat, lon, radius):
    data = load_geofences()
    data.append({
        "name": name,
        "lat": lat,
        "lon": lon,
        "radius": radius,
        "created": int(time.time())
    })
    save_geofences(data)


def check_geofences(lat, lon):
    hits = []
    for fence in load_geofences():
        dist = haversine(lat, lon, fence["lat"], fence["lon"])
        if dist <= fence["radius"]:
            hits.append({
                "name": fence["name"],
                "distance": round(dist, 2),
                "radius": fence["radius"]
            })
    return hits
PYEOF

########################################
# Patch CLI Integration
########################################
python - <<'PYEOF'
from pathlib import Path

p = Path("locview/main.py")
text = p.read_text()

if "from locview.alerts.geofence" not in text:
    text = text.replace(
        "from locview.export.pdf_report import generate_pdf_report",
        "from locview.export.pdf_report import generate_pdf_report\nfrom locview.alerts.geofence import add_geofence, check_geofences"
    )

if 'sub.add_parser("geofence-add"' not in text:
    insert = '''
    gf_add = sub.add_parser("geofence-add")
    gf_add.add_argument("--name", required=True)
    gf_add.add_argument("--lat", type=float, required=True)
    gf_add.add_argument("--lon", type=float, required=True)
    gf_add.add_argument("--radius", type=int, required=True)

    gf_check = sub.add_parser("geofence-check")
    gf_check.add_argument("--lat", type=float, required=True)
    gf_check.add_argument("--lon", type=float, required=True)
'''
    text = text.replace('polygon.add_argument("--step", type=float, default=0.005)', 
                        'polygon.add_argument("--step", type=float, default=0.005)\n' + insert)

dispatch_insert = '''
    elif args.command == "geofence-add":
        add_geofence(args.name, args.lat, args.lon, args.radius)
        print("[green]Geofence Added Successfully[/green]")

    elif args.command == "geofence-check":
        hits = check_geofences(args.lat, args.lon)
        if not hits:
            print("[yellow]No Geofence Triggered[/yellow]")
        else:
            print("[bold red]Triggered Geofences:[/bold red]")
            for h in hits:
                print(f"- {h['name']} ({h['distance']}m / {h['radius']}m)")
'''
    text = text.replace(
        'elif args.command == "polygon":',
        dispatch_insert + '\n\n    elif args.command == "polygon":'
    )

p.write_text(text)
PYEOF

########################################
# Reinstall
########################################
pip install -e .

echo "[+] Geofencing Alerts Integrated"
