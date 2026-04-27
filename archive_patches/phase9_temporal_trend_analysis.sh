#!/usr/bin/env bash
set -e

########################################
# Trend Analysis Engine
########################################
mkdir -p locview/intel

cat > locview/intel/trends.py <<'PYEOF'
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
PYEOF

########################################
# Patch CLI Integration
########################################
python - <<'PYEOF'
from pathlib import Path

p = Path("locview/main.py")
text = p.read_text()

if "from locview.intel.trends import analyze_trend" not in text:
    text = text.replace(
        "from locview.alerts.geofence import add_geofence, check_geofences",
        "from locview.alerts.geofence import add_geofence, check_geofences\nfrom locview.intel.trends import analyze_trend"
    )

if 'trend_cmd = sub.add_parser("trend")' not in text:
    inject = '''
    trend_cmd = sub.add_parser("trend")
    trend_cmd.add_argument("--lat", type=float, required=True)
    trend_cmd.add_argument("--lon", type=float, required=True)
'''
    text = text.replace(
        'sub.add_parser("tui")',
        inject + '\n    sub.add_parser("tui")'
    )

if 'elif args.cmd == "trend":' not in text:
    dispatch = '''
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

echo "[+] Temporal Trend Analysis Integrated"
