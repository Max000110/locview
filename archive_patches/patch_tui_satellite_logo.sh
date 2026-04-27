#!/usr/bin/env bash
set -e

python <<'PYEOF'
from pathlib import Path
import re

p = Path("locview/tui/dashboard.py")
text = p.read_text()

# ------------------------------------------------------------------
# Inject PLANET_LOGO constant if missing
# ------------------------------------------------------------------
if "PLANET_LOGO =" not in text:
    text = text.replace(
        "THEMES = {",
        '''PLANET_LOGO = r"""
⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⣀⣀⣀
⠀⠀⠀⠀⠀⣠⣶⣿⣿⣿⣿⣿⣿⣷⣄
⠀⠀⠀⠀⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷
⠀⠀⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧
⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⠀⠀⠀⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿
⠀⠀⠀⠀⠙⢿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠋
"""

THEMES = {'''
    )

# ------------------------------------------------------------------
# Ensure screenshot import exists
# ------------------------------------------------------------------
if "save_satellite_screenshot" not in text:
    text = text.replace(
        "from locview.providers.poi import get_pois",
        "from locview.providers.poi import get_pois\nfrom locview.providers.screenshot import save_satellite_screenshot"
    )

# ------------------------------------------------------------------
# Add CSS for planet logo if missing
# ------------------------------------------------------------------
if "#planet-logo" not in text:
    text = text.replace(
        "DataTable {",
        '''
    #planet-logo {
        color: lime;
        content-align: center middle;
        height: 12;
        margin-top: 1;
    }

    DataTable {'''
    )

# ------------------------------------------------------------------
# Replace fake satellite placeholder with real layout
# ------------------------------------------------------------------
text = re.sub(
    r'yield Static\(\s*"🪐 SATELLITE PREVIEW.*?id="satellite-box"\s*\)',
    '''yield Static(
                    "Satellite / Export Info Pending...",
                    id="satellite-box"
                )

                yield Static(
                    PLANET_LOGO,
                    id="planet-logo"
                )''',
    text,
    flags=re.S
)

# ------------------------------------------------------------------
# Replace satellite update block
# ------------------------------------------------------------------
text = re.sub(
    r'sat\.update\(\s*f?"🪐 SATELLITE PREVIEW.*?\)',
    '''screenshot_path = save_satellite_screenshot(lat, lon)

            google_maps = f"https://maps.google.com/?q={lat},{lon}"
            google_earth = f"https://earth.google.com/web/@{lat},{lon},500a"
            html_report = "/storage/emulated/0/Documents/LocViewReports/"

            sat.update(
                f"""PNG Export:
{screenshot_path}

Google Maps:
{google_maps}

Google Earth:
{google_earth}

HTML Reports Folder:
{html_report}
"""
            )''',
    text,
    flags=re.S
)

p.write_text(text)
PYEOF

pip install -e .

echo "[+] TUI Satellite/Logo Patch Applied"
