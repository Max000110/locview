#!/usr/bin/env bash
set -e

########################################
# Threat / Risk Overlay Engine
########################################
mkdir -p locview/intel

cat > locview/intel/risk.py <<'PYEOF'
def classify_risk(score: int) -> str:
    if score >= 80:
        return "Low Risk"
    elif score >= 55:
        return "Moderate Risk"
    return "High Risk"


def assess_risk(pois: list) -> dict:
    score = 50

    for poi in pois:
        tags = poi.get("tags", {})
        amenity = tags.get("amenity", "")

        if amenity in ["police", "fire_station", "hospital"]:
            score += 10

        if amenity in ["bar", "nightclub"]:
            score -= 8

        if amenity in ["atm", "bank"]:
            score -= 2

        if amenity in ["school", "university"]:
            score += 3

    score = max(0, min(100, score))

    return {
        "risk_score": score,
        "risk_level": classify_risk(score)
    }
PYEOF

########################################
# Patch Scan Command Risk Output
########################################
python - <<'PYEOF'
from pathlib import Path

p = Path("locview/main.py")
text = p.read_text()

if "from locview.intel.risk import assess_risk" not in text:
    text = text.replace(
        "from locview.live.tracker import live_track",
        "from locview.live.tracker import live_track\nfrom locview.intel.risk import assess_risk"
    )

old = '''
    print("\\n[bold yellow]POIs[/bold yellow]")
    for poi in pois[:10]:
        tags = poi.get("tags", {})
        print("-", tags.get("name", "Unnamed"))
'''

new = '''
    risk = assess_risk(pois)

    print(f"[bold red]Risk Level:[/bold red] {risk['risk_level']}")
    print(f"[bold red]Risk Score:[/bold red] {risk['risk_score']}/100")

    print("\\n[bold yellow]POIs[/bold yellow]")
    for poi in pois[:10]:
        tags = poi.get("tags", {})
        print("-", tags.get("name", "Unnamed"))
'''

text = text.replace(old, new)

p.write_text(text)
PYEOF

########################################
# Patch Polygon Scan Risk Support
########################################
python - <<'PYEOF'
from pathlib import Path

p = Path("locview/core/polygon_scan.py")
text = p.read_text()

if "from locview.intel.risk import assess_risk" not in text:
    text = text.replace(
        "from locview.intel.scoring import score_location",
        "from locview.intel.scoring import score_location\nfrom locview.intel.risk import assess_risk"
    )

old = '''
            intel = score_location(pois)

            results.append({
                "lat": lat,
                "lon": lon,
                "poi_count": len(pois),
                "pois": pois[:10],
                "score": intel["score"],
                "classification": intel["classification"],
                "breakdown": intel["breakdown"]
            })
'''

new = '''
            intel = score_location(pois)
            risk = assess_risk(pois)

            results.append({
                "lat": lat,
                "lon": lon,
                "poi_count": len(pois),
                "pois": pois[:10],
                "score": intel["score"],
                "classification": intel["classification"],
                "breakdown": intel["breakdown"],
                "risk_score": risk["risk_score"],
                "risk_level": risk["risk_level"]
            })
'''

text = text.replace(old, new)

p.write_text(text)
PYEOF

########################################
# Reinstall
########################################
pip install -e .

echo "[+] Threat / Risk Overlay Integrated"
