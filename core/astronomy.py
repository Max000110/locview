import requests
def get_sun(lat, lon):
    return requests.get(
        f"https://api.sunrise-sunset.org/json?lat={lat}&lng={lon}&formatted=0"
    ).json().get("results", {})
