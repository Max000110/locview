from locview.providers.plugins.base import ProviderPlugin
from locview.providers.weather import get_weather


class WeatherPlugin(ProviderPlugin):
    name = "weather"

    def fetch(self, lat, lon):
        return get_weather(lat, lon)
