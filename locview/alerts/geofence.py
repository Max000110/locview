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
