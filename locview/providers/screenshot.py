import os
import time
import requests

from locview.utils.logger import get_logger
from locview.providers.maps import satellite_preview_url

log = get_logger("screenshot")

OUT_DIR = "/storage/emulated/0/Pictures/LocView"
os.makedirs(OUT_DIR, exist_ok=True)


def fetch_static_map(url: str):
    try:
        path = os.path.join(
            OUT_DIR,
            f"map_{int(time.time())}.png"
        )

        r = requests.get(url, timeout=20)
        r.raise_for_status()

        with open(path, "wb") as f:
            f.write(r.content)

        log.info(f"Screenshot saved: {path}")
        return path

    except Exception:
        log.exception("Screenshot fetch failed")
        return None


def save_satellite_screenshot(lat: float, lon: float):
    """
    Build static map URL then fetch screenshot.
    """
    try:
        url = satellite_preview_url(lat, lon)
        return fetch_static_map(url)

    except Exception:
        log.exception("Satellite screenshot pipeline failed")
        return None
