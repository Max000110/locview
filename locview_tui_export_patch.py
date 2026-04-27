from pathlib import Path
import re

p = Path("locview/tui/dashboard.py")
src = p.read_text()

if "generate_html_report" not in src:
    src = src.replace(
        "from locview.providers.screenshot import save_satellite_screenshot",
        "from locview.providers.screenshot import save_satellite_screenshot\n"
        "from locview.providers.maps import google_maps_url, google_earth_url\n"
        "from locview.export.html_report import generate_html_report\n"
        "from locview.export.pdf_report import generate_pdf_report"
    )

pattern = re.compile(
    r'screenshot_path = save_satellite_screenshot\(lat, lon\).*?sat\.update\(\s*f?""".*?"""\s*\)',
    re.S
)

replacement = '''screenshot_path = save_satellite_screenshot(lat, lon)

            scan_payload = {
                "geo": address if isinstance(address, dict) else {"display_name": addr},
                "weather": weather,
                "pois": pois
            }

            html_report = generate_html_report(scan_payload, screenshot_path)

            pdf_report = generate_pdf_report(
                "LocView Scan Report",
                [{
                    "lat": lat,
                    "lon": lon,
                    "poi_count": len(pois)
                }]
            )

            sat.update(
                f"""PNG Export:
{screenshot_path}

Google Maps:
{google_maps_url(lat, lon)}

Google Earth:
{google_earth_url(lat, lon)}

HTML Report:
{html_report}

PDF Report:
{pdf_report}
"""
            )'''

src = pattern.sub(replacement, src)

p.write_text(src)
print("[+] Full Export Tracking Patched")
