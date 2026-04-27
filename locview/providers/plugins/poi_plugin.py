from locview.providers.plugins.base import ProviderPlugin
from locview.providers.poi import get_pois


class POIPlugin(ProviderPlugin):
    name = "poi"

    def fetch(self, lat, lon, radius=1000):
        return get_pois(lat, lon, radius)
