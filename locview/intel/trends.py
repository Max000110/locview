import sqlite3
import json
import os
from statistics import mean

DB_PATH = os.path.expanduser("~/.locview/history.db")


def get_scan_history_for_point(lat, lon, limit=10):
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    cur.execute("""
        SELECT timestamp, pois_json
        FROM scans
        WHERE lat = ? AND lon = ?
        ORDER BY timestamp DESC
        LIMIT ?
    """, (str(lat), str(lon), limit))

    rows = cur.fetchall()
    conn.close()

    return rows


def analyze_trend(lat, lon):
    rows = get_scan_history_for_point(lat, lon)

    if len(rows) < 2:
        return {
            "status": "insufficient_data"
        }

    counts = []

    for ts, pois_json in rows:
        pois = json.loads(pois_json)
        counts.append(len(pois))

    latest = counts[0]
    avg_old = mean(counts[1:])

    delta = latest - avg_old

    if delta > 5:
        trend = "Growing"
    elif delta < -5:
        trend = "Declining"
    else:
        trend = "Stable"

    return {
        "status": "ok",
        "latest_poi_count": latest,
        "historical_average": round(avg_old, 2),
        "delta": round(delta, 2),
        "trend": trend
    }
