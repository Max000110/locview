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
