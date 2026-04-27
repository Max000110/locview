import os
import yaml

CONFIG_PATH = os.path.expanduser("~/.locview/config.yaml")


def get_api_key():
    try:
        with open(CONFIG_PATH) as f:
            cfg = yaml.safe_load(f) or {}
        return cfg.get("locationiq_key", "")
    except Exception:
        return ""


def satellite_preview_url(lat, lon, zoom=16):
    key = get_api_key()
    return (
        f"https://maps.locationiq.com/v3/staticmap"
        f"?key={key}"
        f"&center={lat},{lon}"
        f"&zoom={zoom}"
        f"&size=800x400"
        f"&markers=icon:large-red-cutout|{lat},{lon}"
    )


def google_maps_url(lat, lon):
    return f"https://www.google.com/maps?q={lat},{lon}"


def google_earth_url(lat, lon):
    return f"https://earth.google.com/web/@{lat},{lon},500a"
