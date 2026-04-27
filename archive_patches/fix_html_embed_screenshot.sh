#!/usr/bin/env bash
set -e

cat > locview/export/html_report.py <<'PYEOF'
import os
import time
import base64

EXPORT_DIR = "/storage/emulated/0/Documents/LocViewReports"
os.makedirs(EXPORT_DIR, exist_ok=True)


def encode_image_base64(path):
    if not path or not os.path.exists(path):
        return None

    with open(path, "rb") as f:
        return base64.b64encode(f.read()).decode()


def generate_html_report(scan_data: dict, screenshot_path: str = None):
    ts = int(time.time())
    out_path = os.path.join(EXPORT_DIR, f"locview_report_{ts}.html")

    geo = scan_data.get("geo", {})
    addr = geo.get("address", {})
    weather = scan_data.get("weather", {})
    pois = scan_data.get("pois", [])

    img_b64 = encode_image_base64(screenshot_path)

    img_html = ""
    if img_b64:
        img_html = f'''
        <img src="data:image/png;base64,{img_b64}"
             style="max-width:100%;border-radius:8px;">
        '''

    poi_rows = ""
    for poi in pois[:25]:
        tags = poi.get("tags", {})
        poi_rows += f"""
        <tr>
            <td>{tags.get('name', 'Unnamed')}</td>
            <td>{tags.get('amenity') or tags.get('tourism') or tags.get('shop') or 'POI'}</td>
        </tr>
        """

    html = f"""
    <html>
    <head>
        <title>LocView Report</title>
        <style>
            body {{
                font-family: Arial;
                background: #0b0f14;
                color: #e6edf3;
                padding: 30px;
            }}
            .card {{
                background: #161b22;
                padding: 20px;
                margin-bottom: 20px;
                border-radius: 12px;
            }}
            table {{
                width: 100%;
                border-collapse: collapse;
            }}
            td, th {{
                border: 1px solid #30363d;
                padding: 10px;
            }}
            th {{
                background: #21262d;
            }}
        </style>
    </head>
    <body>

        <h1>LocView Geospatial Intel Report</h1>

        <div class="card">
            <h2>Location Details</h2>
            <p><b>Address:</b> {geo.get("display_name","Unknown")}</p>
            <p><b>Country:</b> {addr.get("country","N/A")}</p>
            <p><b>State:</b> {addr.get("state","N/A")}</p>
            <p><b>City:</b> {addr.get("city","N/A")}</p>
            <p><b>ZIP:</b> {addr.get("postcode","N/A")}</p>
        </div>

        <div class="card">
            <h2>Weather</h2>
            <p><b>Temperature:</b> {weather.get("temperature","N/A")}°C</p>
            <p><b>Wind Speed:</b> {weather.get("windspeed","N/A")} km/h</p>
        </div>

        <div class="card">
            <h2>Satellite Preview</h2>
            {img_html}
        </div>

        <div class="card">
            <h2>Nearby POIs</h2>
            <table>
                <tr><th>Name</th><th>Type</th></tr>
                {poi_rows}
            </table>
        </div>

    </body>
    </html>
    """

    with open(out_path, "w", encoding="utf-8") as f:
        f.write(html)

    return out_path
PYEOF

pip install -e .

echo "[+] HTML Report Screenshot Embedding Fixed"
