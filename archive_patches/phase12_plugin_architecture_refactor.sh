#!/usr/bin/env bash
set -e

########################################
# Provider Plugin Framework
########################################
mkdir -p locview/providers/plugins

cat > locview/providers/plugins/base.py <<'PYEOF'
class ProviderPlugin:
    name = "base"

    def fetch(self, *args, **kwargs):
        raise NotImplementedError
PYEOF

########################################
# Geocode Plugin
########################################
cat > locview/providers/plugins/geocode_plugin.py <<'PYEOF'
from locview.providers.plugins.base import ProviderPlugin
from locview.providers.geocode import reverse_geocode


class GeocodePlugin(ProviderPlugin):
    name = "geocode"

    def fetch(self, lat, lon):
        return reverse_geocode(lat, lon)
PYEOF

########################################
# Weather Plugin
########################################
cat > locview/providers/plugins/weather_plugin.py <<'PYEOF'
from locview.providers.plugins.base import ProviderPlugin
from locview.providers.weather import get_weather


class WeatherPlugin(ProviderPlugin):
    name = "weather"

    def fetch(self, lat, lon):
        return get_weather(lat, lon)
PYEOF

########################################
# POI Plugin
########################################
cat > locview/providers/plugins/poi_plugin.py <<'PYEOF'
from locview.providers.plugins.base import ProviderPlugin
from locview.providers.poi import get_pois


class POIPlugin(ProviderPlugin):
    name = "poi"

    def fetch(self, lat, lon, radius=1000):
        return get_pois(lat, lon, radius)
PYEOF

########################################
# Plugin Registry
########################################
cat > locview/providers/plugins/registry.py <<'PYEOF'
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
PYEOF

########################################
# Plugin Test Command Integration
########################################
python - <<'PYEOF'
from pathlib import Path

p = Path("locview/main.py")
text = p.read_text()

if "from locview.providers.plugins.registry import list_plugins" not in text:
    text = text.replace(
        "from locview.intel.risk import assess_risk",
        "from locview.intel.risk import assess_risk\nfrom locview.providers.plugins.registry import list_plugins"
    )

if 'sub.add_parser("plugins")' not in text:
    text = text.replace(
        'sub.add_parser("tui")',
        'sub.add_parser("plugins")\n    sub.add_parser("tui")'
    )

if 'elif args.cmd == "plugins":' not in text:
    dispatch = '''
    elif args.cmd == "plugins":
        print("[bold cyan]Loaded Provider Plugins[/bold cyan]")
        for plugin in list_plugins():
            print("-", plugin)
'''
    text = text.replace(
        'elif args.cmd == "tui":',
        dispatch + '\n\n    elif args.cmd == "tui":'
    )

p.write_text(text)
PYEOF

########################################
# Reinstall
########################################
pip install -e .

echo "[+] Plugin Architecture Refactor Complete"
