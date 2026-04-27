#!/usr/bin/env bash
set -e

########################################
# Heatmap Export Module
########################################
cat > locview/export/heatmap_report.py <<'PYEOF'
import os
import time
import json

EXPORT_DIR = "/storage/emulated/0/Documents/LocViewReports"
os.makedirs(EXPORT_DIR, exist_ok=True)


def generate_heatmap_report(points):
    ts = int(time.time())
    out_path = os.path.join(
        EXPORT_DIR,
        f"locview_heatmap_{ts}.html"
    )

    heat_data = [
        [p["lat"], p["lon"], p["poi_count"]]
        for p in points
    ]

    html = f"""
    <html>
    <head>
        <title>LocView Heatmap</title>

        <link rel="stylesheet"
              href="https://unpkg.com/leaflet/dist/leaflet.css"/>

        <script src="https://unpkg.com/leaflet/dist/leaflet.js"></script>
        <script src="https://unpkg.com/leaflet.heat/dist/leaflet-heat.js"></script>

        <style>
            body {{
                margin: 0;
                background: #0b0f14;
                color: white;
                font-family: Arial;
            }}

            #map {{
                width: 100%;
                height: 100vh;
            }}

            .title {{
                padding: 15px;
                font-size: 22px;
                font-weight: bold;
                background: #111827;
            }}
        </style>
    </head>

    <body>
        <div class="title">LocView Heatmap Visualization</div>
        <div id="map"></div>

        <script>
            const heatData = {json.dumps(heat_data)};

            const centerLat =
                heatData.reduce((a,b)=>a+b[0],0)/heatData.length;

            const centerLon =
                heatData.reduce((a,b)=>a+b[1],0)/heatData.length;

            const map = L.map('map').setView(
                [centerLat, centerLon], 14
            );

            L.tileLayer(
                'https://{{s}}.tile.openstreetmap.org/{{z}}/{{x}}/{{y}}.png',
                {{
                    maxZoom: 19
                }}
            ).addTo(map);

            L.heatLayer(
                heatData,
                {{
                    radius: 25,
                    blur: 20,
                    maxZoom: 17
                }}
            ).addTo(map);
        </script>
    </body>
    </html>
    """

    with open(out_path, "w", encoding="utf-8") as f:
        f.write(html)

    return out_path
PYEOF

########################################
# Polygon Scan Auto Heatmap Integration
########################################
python - <<'PYEOF'
from pathlib import Path

p = Path("locview/main.py")
text = p.read_text()

if "generate_heatmap_report" not in text:
    text = text.replace(
        "from locview.export.polygon_report import generate_polygon_report",
        "from locview.export.polygon_report import generate_polygon_report\nfrom locview.export.heatmap_report import generate_heatmap_report"
    )

old = '''
    report = generate_polygon_report(data)

    print("[green]Polygon Scan Report:[/green]", report)
    open_browser(report)
'''

new = '''
    report = generate_polygon_report(data)
    heatmap = generate_heatmap_report(data)

    print("[green]Polygon Scan Report:[/green]", report)
    print("[green]Heatmap Visualization:[/green]", heatmap)

    open_browser(heatmap)
'''

text = text.replace(old, new)

p.write_text(text)
PYEOF

pip install -e .

echo "[+] Heatmap Visualization Layer Added"
