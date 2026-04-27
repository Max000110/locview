import requests
def get_elevation(lat, lon):
    r = requests.get(
        f"https://api.open-meteo.com/v1/elevation?latitude={lat}&longitude={lon}"
    ).json()
    return r.get("elevation")
