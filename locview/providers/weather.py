import requests
from locview.utils.logger import get_logger

log = get_logger("weather")


def get_weather(lat, lon):
    try:
        r = requests.get(
            "https://api.open-meteo.com/v1/forecast",
            params={
                "latitude": lat,
                "longitude": lon,
                "current_weather": True
            },
            timeout=10
        )

        r.raise_for_status()

        data = r.json()["current_weather"]

        log.info(f"Weather fetch success: {lat},{lon}")

        return data

    except Exception:
        log.exception(f"Weather fetch failed: {lat},{lon}")
        return {}
