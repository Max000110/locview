from geopy.distance import geodesic

def route_estimate(a,b):
    a=tuple(map(float,a.split(",")))
    b=tuple(map(float,b.split(",")))
    print({"distance_km": round(geodesic(a,b).km,2)})
