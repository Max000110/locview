import os

DEFAULT_CONFIG = {
    "default_radius": int(os.getenv("LOCVIEW_DEFAULT_RADIUS", "500")),
    "request_timeout": int(os.getenv("LOCVIEW_TIMEOUT", "20")),
    "debug": os.getenv("LOCVIEW_DEBUG", "false").lower() == "true",
    "maptiler_key": os.getenv("LOCVIEW_MAPTILER_KEY", ""),
}

def load_config():
    return DEFAULT_CONFIG.copy()
