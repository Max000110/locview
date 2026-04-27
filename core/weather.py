import requests
def get_weather(lat, lon):
    return requests.get(
        f"https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}&current_weather=true"
    ).json().get("current_weather", {})
