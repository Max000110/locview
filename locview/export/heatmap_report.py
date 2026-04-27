import os
import time
import json

EXPORT_DIR = "/storage/emulated/0/Documents/LocViewReports"
os.makedirs(EXPORT_DIR, exist_ok=True)

def generate_heatmap_report(points):
    ts = int(time.time())
    out_path = os.path.join(EXPORT_DIR, f"locview_heatmap_{ts}.html")

    heat_data = [
        [p["lat"], p["lon"], p.get("score", p.get("poi_count", 0))]
        for p in points
    ]

    html = f"""
<html>
<head>
<title>LocView Heatmap</title>
<link rel="stylesheet" href="https://unpkg.com/leaflet/dist/leaflet.css"/>
<script src="https://unpkg.com/leaflet/dist/leaflet.js"></script>
<script src="https://unpkg.com/leaflet.heat/dist/leaflet-heat.js"></script>
<style>
body {{ margin:0; background:#0b0f14; }}
#map {{ width:100%; height:100vh; }}
</style>
</head>
<body>
<div id="map"></div>
<script>
const heatData = {json.dumps(heat_data)};
const centerLat = heatData.reduce((a,b)=>a+b[0],0)/heatData.length;
const centerLon = heatData.reduce((a,b)=>a+b[1],0)/heatData.length;

const map = L.map('map').setView([centerLat, centerLon], 14);

L.tileLayer(
 'https://{{s}}.tile.openstreetmap.org/{{z}}/{{x}}/{{y}}.png',
 {{maxZoom:19}}
).addTo(map);

L.heatLayer(
 heatData,
 {{radius:25, blur:20, maxZoom:17}}
).addTo(map);
</script>
</body>
</html>
"""

    with open(out_path, "w", encoding="utf-8") as f:
        f.write(html)

    print(f"[HEATMAP SAVED] {out_path}")
    return out_path
