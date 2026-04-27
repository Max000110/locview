import requests
from timezonefinder import TimezoneFinder
from openlocationcode import openlocationcode as olc

def reverse_geocode(lat, lon):
    r = requests.get(
        f"https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat={lat}&lon={lon}",
        headers={"User-Agent":"locview"}
    )
    return r.json()

def timezone_of(lat, lon):
    return TimezoneFinder().timezone_at(lat=float(lat), lng=float(lon))

def plus_code(lat, lon):
    return olc.encode(float(lat), float(lon))
