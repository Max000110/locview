from concurrent.futures import ThreadPoolExecutor
from rich import print
from rich.table import Table

from core.geocode import reverse_geocode, timezone_of, plus_code
from core.weather import get_weather
from core.elevation import get_elevation
from core.astronomy import get_sun
from core.poi import nearby_pois
from core.maps import maps_links, open_in_browser
from core.history import save_history
from core.export import export_json, export_html, export_pdf

def run_scan(args):
    lat=args.lat or input("Latitude: ")
    lon=args.lon or input("Longitude: ")

    with ThreadPoolExecutor() as ex:
        geo_f=ex.submit(reverse_geocode,lat,lon)
        weather_f=ex.submit(get_weather,lat,lon)
        elev_f=ex.submit(get_elevation,lat,lon)
        sun_f=ex.submit(get_sun,lat,lon)
        poi_f=ex.submit(nearby_pois,lat,lon,args.radius)

    geo=geo_f.result()
    weather=weather_f.result()
    elevation=elev_f.result()
    sun=sun_f.result()
    pois=poi_f.result()

    report={
        "geo": geo,
        "timezone": timezone_of(lat,lon),
        "plus_code": plus_code(lat,lon),
        "weather": weather,
        "elevation": elevation,
        "sun": sun,
        "pois": pois,
        **maps_links(lat,lon)
    }

    table = Table(title="LOCVIEW REPORT")
    table.add_column("Field", style="cyan")
    table.add_column("Value", style="green")

    addr = geo.get("address", {})

    table.add_row("Display Name", geo.get("display_name","N/A"))
    table.add_row("Country", addr.get("country","N/A"))
    table.add_row("State", addr.get("state","N/A"))
    table.add_row("City", addr.get("city") or addr.get("town") or "N/A")
    table.add_row("ZIP", addr.get("postcode","N/A"))
    table.add_row("Timezone", report["timezone"])
    table.add_row("Plus Code", report["plus_code"])
    table.add_row("Elevation", str(elevation))
    table.add_row("Temperature", str(weather.get("temperature","N/A")))
    table.add_row("Wind Speed", str(weather.get("windspeed","N/A")))
    table.add_row("Sunrise", sun.get("sunrise","N/A"))
    table.add_row("Sunset", sun.get("sunset","N/A"))
    table.add_row("Google Maps", report["google_maps"])
    table.add_row("Google Earth", report["google_earth"])
    table.add_row("Satellite", report["satellite"])

    print(table)

    print("\n[bold yellow]Nearby POIs[/bold yellow]")
    for poi in pois[:15]:
        tags = poi.get("tags", {})
        name = tags.get("name", "Unnamed")
        kind = (
            tags.get("amenity")
            or tags.get("tourism")
            or tags.get("shop")
            or "POI"
        )
        print(f"• {name} ({kind})")

    save_history(report)

    if args.json: export_json(report)
    if args.html: export_html(report)
    if args.pdf: export_pdf(report)
    if args.open: open_in_browser(report["google_maps"])
