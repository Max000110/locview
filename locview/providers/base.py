import requests

def safe_get_json(url, **kwargs):
    try:
        r = requests.get(url, timeout=20, **kwargs)
        r.raise_for_status()
        return r.json()
    except:
        return {}

def safe_post_json(url, **kwargs):
    try:
        r = requests.post(url, timeout=30, **kwargs)
        r.raise_for_status()
        if not r.text.strip():
            return {}
        return r.json()
    except:
        return {}
