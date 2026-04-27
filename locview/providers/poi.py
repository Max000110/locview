import time
import requests
from locview.utils.logger import get_logger

log = get_logger("poi")

OVERPASS_ENDPOINTS = [
    "https://overpass-api.de/api/interpreter",
    "https://lz4.overpass-api.de/api/interpreter",
    "https://z.overpass-api.de/api/interpreter",
]


def get_pois(lat, lon, radius=500):
    query = f"""
[out:json][timeout:20];
(
  node(around:{radius},{lat},{lon})[amenity];
  node(around:{radius},{lat},{lon})[tourism];
  node(around:{radius},{lat},{lon})[shop];
);
out body 200;
"""

    for idx, endpoint in enumerate(OVERPASS_ENDPOINTS, start=1):
        try:
            r = requests.post(
                endpoint,
                data={"data": query},
                headers={
                    "User-Agent": "LocView/1.1",
                    "Accept": "application/json"
                },
                timeout=30
            )

            r.raise_for_status()

            data = r.json().get("elements", [])

            log.info(
                f"POI fetch success via mirror {idx}: "
                f"{lat},{lon} count={len(data)}"
            )

            return data

        except Exception:
            log.exception(
                f"POI mirror {idx} failed: {endpoint}"
            )

            time.sleep(idx * 2)

    log.error(
        f"All POI mirrors failed for {lat},{lon}"
    )

    return []
