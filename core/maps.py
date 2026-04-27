import os

def maps_links(lat, lon):
    return {
        "google_maps": f"https://www.google.com/maps?q={lat},{lon}",
        "google_earth": f"https://earth.google.com/web/@{lat},{lon},500a",
        "satellite": f"https://maps.google.com/?q={lat},{lon}&t=k"
    }

def open_in_browser(url):
    os.system(f'termux-open-url "{url}"')
