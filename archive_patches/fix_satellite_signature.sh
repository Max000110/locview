#!/usr/bin/env bash
set -e

python <<'PYEOF'
from pathlib import Path
import re

p = Path("locview/providers/screenshot.py")
text = p.read_text()

pattern = r"def save_satellite_screenshot\(lat, lon\):.*?(?=\ndef |\Z)"

replacement = '''
def save_satellite_screenshot(lat, lon):
    """Universal compatibility wrapper."""
    try:
        return fetch_static_map(lat, lon)
    except TypeError:
        try:
            return fetch_static_map((lat, lon))
        except TypeError:
            return fetch_static_map({
                "lat": lat,
                "lon": lon
            })
'''

text = re.sub(pattern, replacement, text, flags=re.S)

p.write_text(text)
PYEOF

pip install -e .

echo "[+] Satellite Signature Fixed"
