from geopy.distance import geodesic

from locview.providers.geocode import reverse_geocode
from locview.providers.weather import get_weather
from locview.providers.poi import get_pois


def compare_locations(coords: list, radius=1000):
    results = []

    for lat, lon in coords:
        geo = reverse_geocode(lat, lon)
        weather = get_weather(lat, lon)
        pois = get_pois(lat, lon, radius)

        results.append({
            "lat": lat,
            "lon": lon,
            "geo": geo,
            "weather": weather,
            "pois": pois,
            "poi_count": len(pois)
        })

    distances = []

    for i in range(len(coords)):
        for j in range(i + 1, len(coords)):
            d = geodesic(coords[i], coords[j]).km
            distances.append(
                f"{coords[i]} ↔ {coords[j]} = {d:.2f} km"
            )

    return {
        "locations": results,
        "distances": distances
    }
