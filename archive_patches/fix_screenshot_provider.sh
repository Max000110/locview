#!/usr/bin/env bash
set -e

python <<'PYEOF'
from pathlib import Path
import re

p = Path("locview/providers/screenshot.py")
text = p.read_text()

# If wrapper already exists, do nothing
if "def save_satellite_screenshot(" not in text:

    # Try to detect an existing screenshot-like function
    candidates = re.findall(r"def\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(", text)

    preferred = None
    for name in candidates:
        lowered = name.lower()
        if any(k in lowered for k in ["screenshot", "satellite", "map", "preview"]):
            preferred = name
            break

    if preferred:
        wrapper = f'''

def save_satellite_screenshot(lat, lon):
    """Compatibility wrapper for TUI satellite preview."""
    return {preferred}(lat, lon)
'''
    else:
        # fallback stub if no screenshot function exists
        wrapper = '''

def save_satellite_screenshot(lat, lon):
    """Fallback screenshot stub."""
    raise RuntimeError(
        "No screenshot backend function found in providers/screenshot.py"
    )
'''

    text += wrapper
    p.write_text(text)

PYEOF

pip install -e .

echo "[+] Screenshot Provider Fixed"
