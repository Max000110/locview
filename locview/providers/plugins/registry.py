from locview.providers.plugins.geocode_plugin import GeocodePlugin
from locview.providers.plugins.weather_plugin import WeatherPlugin
from locview.providers.plugins.poi_plugin import POIPlugin

PLUGINS = {
    "geocode": GeocodePlugin(),
    "weather": WeatherPlugin(),
    "poi": POIPlugin(),
}


def get_plugin(name):
    return PLUGINS.get(name)


def list_plugins():
    return list(PLUGINS.keys())
