import logging
from diskcache import Cache

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(message)s"
)

cache = Cache(".locview_cache")
