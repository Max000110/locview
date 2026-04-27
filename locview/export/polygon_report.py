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
            <td>{point.get('score', 0)}</td>
            <td>{point.get('classification', 'N/A')}</td>
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
                <th>POI Count</th><th>Score</th><th>Classification</th>
            </tr>
            {rows}
        </table>
    </body>
    </html>
    """

    with open(out_path, "w", encoding="utf-8") as f:
        f.write(html)

    return out_path
