import requests

def nearby_pois(lat, lon, radius):
    query = f"""
    [out:json][timeout:25];
    (
      node(around:{radius},{lat},{lon})[amenity];
      node(around:{radius},{lat},{lon})[tourism];
      node(around:{radius},{lat},{lon})[shop];
    );
    out 20;
    """

    try:
        r = requests.post(
            "https://overpass-api.de/api/interpreter",
            data=query,
            headers={"User-Agent": "locview/1.0"},
            timeout=30
        )

        if not r.text.strip():
            return []

        if "rate_limited" in r.text.lower():
            return []

        return r.json().get("elements", [])

    except Exception:
        return []
