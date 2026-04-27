from geopy.distance import geodesic

def compare_coords(file):
    coords=[]
    with open(file) as f:
        for line in f:
            lat,lon=map(float,line.strip().split(","))
            coords.append((lat,lon))

    for i in range(len(coords)-1):
        print(
            f"{coords[i]} -> {coords[i+1]} = "
            f"{round(geodesic(coords[i],coords[i+1]).km,2)} km"
        )
