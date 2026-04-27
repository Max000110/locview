#!/usr/bin/env bash
set -e

########################################
# AI / Heuristic Scoring Engine
########################################
mkdir -p locview/intel

cat > locview/intel/scoring.py <<'PYEOF'
def classify_score(score: float) -> str:
    if score >= 85:
        return "Prime"
    elif score >= 70:
        return "High Potential"
    elif score >= 50:
        return "Moderate"
    return "Low Density"


def score_location(pois: list) -> dict:
    categories = {
        "banking": 0,
        "food": 0,
        "education": 0,
        "transport": 0,
        "healthcare": 0,
        "emergency": 0,
        "shopping": 0,
        "hospitality": 0,
    }

    for poi in pois:
        tags = poi.get("tags", {})

        amenity = tags.get("amenity", "")
        tourism = tags.get("tourism", "")
        shop = tags.get("shop", "")

        if amenity in ["bank", "atm"]:
            categories["banking"] += 1

        if amenity in ["restaurant", "cafe", "fast_food"]:
            categories["food"] += 1

        if amenity in ["school", "college", "university"]:
            categories["education"] += 1

        if amenity in ["bus_station", "taxi", "parking"]:
            categories["transport"] += 1

        if amenity in ["hospital", "clinic", "pharmacy"]:
            categories["healthcare"] += 1

        if amenity in ["police", "fire_station"]:
            categories["emergency"] += 1

        if shop:
            categories["shopping"] += 1

        if tourism in ["hotel", "guest_house"]:
            categories["hospitality"] += 1

    weights = {
        "banking": 10,
        "food": 10,
        "education": 15,
        "transport": 15,
        "healthcare": 15,
        "emergency": 10,
        "shopping": 10,
        "hospitality": 15,
    }

    weighted_score = 0

    for key, count in categories.items():
        weighted_score += min(count * weights[key], weights[key])

    return {
        "score": weighted_score,
        "classification": classify_score(weighted_score),
        "breakdown": categories
    }
PYEOF

########################################
# Patch Polygon Scan Engine
########################################
python - <<'PYEOF'
from pathlib import Path

p = Path("locview/core/polygon_scan.py")
text = p.read_text()

if "from locview.intel.scoring import score_location" not in text:
    text = "from locview.intel.scoring import score_location\n" + text

old = '''
            results.append({
                "lat": lat,
                "lon": lon,
                "poi_count": len(pois),
                "pois": pois[:10]
            })
'''

new = '''
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

text = text.replace(old, new)

text = text.replace(
    'key=lambda x: x["poi_count"]',
    'key=lambda x: x["score"]'
)

p.write_text(text)
PYEOF

########################################
# Patch Polygon HTML Report
########################################
python - <<'PYEOF'
from pathlib import Path

p = Path("locview/export/polygon_report.py")
text = p.read_text()

old = '''
        rows += f"""
        <tr>
            <td>{point['lat']}</td>
            <td>{point['lon']}</td>
            <td>{point['poi_count']}</td>
        </tr>
        """
'''

new = '''
        rows += f"""
        <tr>
            <td>{point['lat']}</td>
            <td>{point['lon']}</td>
            <td>{point['poi_count']}</td>
            <td>{point.get('score', 0)}</td>
            <td>{point.get('classification', 'N/A')}</td>
        </tr>
        """
'''

text = text.replace(old, new)

text = text.replace(
    "<th>POI Count</th>",
    "<th>POI Count</th><th>Score</th><th>Classification</th>"
)

p.write_text(text)
PYEOF

########################################
# Patch Heatmap Weighting
########################################
python - <<'PYEOF'
from pathlib import Path

p = Path("locview/export/heatmap_report.py")
text = p.read_text()

text = text.replace(
    '        [p["lat"], p["lon"], p["poi_count"]]',
    '        [p["lat"], p["lon"], p.get("score", p["poi_count"])]'
)

p.write_text(text)
PYEOF

########################################
# Reinstall
########################################
pip install -e .

echo "[+] AI Location Scoring Engine Integrated"
