import requests
import time
from locview.utils.logger import get_logger

log = get_logger("http")

def request(method, url, retries=3, backoff=1, **kwargs):
    for attempt in range(1, retries + 1):
        try:
            r = requests.request(method, url, **kwargs)
            r.raise_for_status()
            return r
        except Exception:
            log.exception(f"HTTP failure attempt {attempt}: {url}")
            if attempt == retries:
                raise
            time.sleep(backoff * attempt)
