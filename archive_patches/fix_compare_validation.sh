#!/usr/bin/env bash
set -e

python - <<'PYEOF'
from pathlib import Path
p = Path("locview/main.py")
text = p.read_text()

old = '''
    for raw in args.coords:
        lat, lon = raw.split(",")
        coords.append((float(lat), float(lon)))
'''

new = '''
    for raw in args.coords:
        try:
            lat, lon = raw.split(",")
            coords.append((float(lat.strip()), float(lon.strip())))
        except Exception:
            print(f"[ERROR] Invalid coordinate format: {raw}")
            print('Expected format: "lat,lon"')
            return
'''

p.write_text(text.replace(old, new))
PYEOF

pip install -e .

echo "[+] Compare Input Validation Added"
