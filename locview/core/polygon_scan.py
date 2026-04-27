import time
from locview.providers.poi import get_pois
from locview.intel.scoring import score_location
from locview.intel.risk import assess_risk


def frange(start, stop, step):
    while start <= stop:
        yield round(start, 6)
        start += step


def scan_bbox(lat_min, lon_min, lat_max, lon_max, step=0.01, radius=500):
    results = []

    for lat in frange(lat_min, lat_max, step):
        for lon in frange(lon_min, lon_max, step):

            pois = get_pois(lat, lon, radius)

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

            # Rate limiting to avoid 429/504
            time.sleep(2)

    return sorted(
        results,
        key=lambda x: x["score"],
        reverse=True
    )
