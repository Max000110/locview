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
