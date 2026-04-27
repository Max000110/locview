from locview.providers.plugins.base import ProviderPlugin
from locview.providers.geocode import reverse_geocode


class GeocodePlugin(ProviderPlugin):
    name = "geocode"

    def fetch(self, lat, lon):
        return reverse_geocode(lat, lon)
