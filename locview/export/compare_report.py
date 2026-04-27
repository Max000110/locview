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
