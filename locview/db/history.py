import os
import sqlite3
import json
import time

DB_PATH = os.path.expanduser("~/.locview/history.db")


def init_db():
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)

    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    cur.execute("""
    CREATE TABLE IF NOT EXISTS scans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp INTEGER,
        lat TEXT,
        lon TEXT,
        radius INTEGER,
        geo_json TEXT,
        weather_json TEXT,
        pois_json TEXT,
        screenshot_path TEXT
    )
    """)

    conn.commit()
    conn.close()


def save_scan(lat, lon, radius, geo, weather, pois, screenshot):
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    cur.execute("""
    INSERT INTO scans (
        timestamp, lat, lon, radius,
        geo_json, weather_json, pois_json,
        screenshot_path
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        int(time.time()),
        lat,
        lon,
        radius,
        json.dumps(geo),
        json.dumps(weather),
        json.dumps(pois),
        screenshot
    ))

    conn.commit()
    conn.close()


def get_recent_scans(limit=10):
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    cur.execute("""
    SELECT id, timestamp, lat, lon, radius
    FROM scans
    ORDER BY timestamp DESC
    LIMIT ?
    """, (limit,))

    rows = cur.fetchall()
    conn.close()

    return rows
