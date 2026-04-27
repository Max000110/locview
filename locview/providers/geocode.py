import requests
from locview.utils.logger import get_logger

log = get_logger("geocode")


def reverse_geocode(lat, lon):
    try:
        r = requests.get(
            "https://nominatim.openstreetmap.org/reverse",
            params={
                "lat": lat,
                "lon": lon,
                "format": "json"
            },
            headers={
                "User-Agent": "LocView/1.1"
            },
            timeout=10
        )

        r.raise_for_status()

        data = r.json()

        log.info(f"Reverse geocode success: {lat},{lon}")

        return data

    except Exception as e:
        log.exception(f"Reverse geocode failed: {lat},{lon}")
        return {
            "display_name": "Unknown",
            "address": {}
        }
