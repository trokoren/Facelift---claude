"""Builds FACELIFT/Resources/climate.json: typical UV, humidity and air quality per city.

Run once (GitHub Actions: "Build climate data"); the app ships the file and never calls a
weather service. Sources, all free for commercial use:
  - Cities: GeoNames cities15000 (CC BY 4.0, credit "GeoNames").
  - UV and humidity: NASA POWER climatology, long-term yearly averages (public domain,
    credit "NASA POWER").
  - Air quality (US only): EPA AirData annual AQI by metro area, median AQI averaged over
    2022 to 2024 (public domain), placed with Census metro area centers.

Output rows: [name, region, country, lat, lon, uv, humidity, aqi or null].
"""

import csv
import io
import json
import math
import sys
import time
import urllib.request
import zipfile
from concurrent.futures import ThreadPoolExecutor

US_MIN_POP = 30_000
WORLD_MIN_POP = 500_000
OUT = sys.argv[1] if len(sys.argv) > 1 else "climate.json"


def get(url, tries=4):
    for attempt in range(tries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "facelift-climate-build/1.0"})
            with urllib.request.urlopen(req, timeout=90) as r:
                return r.read()
        except Exception as e:  # noqa: BLE001
            if attempt == tries - 1:
                raise
            print(f"retry {url}: {e}", flush=True)
            time.sleep(3 * (attempt + 1))


def unzip_text(data, suffix):
    z = zipfile.ZipFile(io.BytesIO(data))
    name = next(n for n in z.namelist() if n.endswith(suffix))
    return z.read(name).decode("utf-8", errors="replace")


def km(a_lat, a_lon, b_lat, b_lon):
    p = math.pi / 180
    h = (math.sin((b_lat - a_lat) * p / 2) ** 2
         + math.cos(a_lat * p) * math.cos(b_lat * p) * math.sin((b_lon - a_lon) * p / 2) ** 2)
    return 12742 * math.asin(math.sqrt(h))


# --- Cities -------------------------------------------------------------------------------

text = unzip_text(get("https://download.geonames.org/export/dump/cities15000.zip"), ".txt")
cities = []
for line in text.splitlines():
    f = line.split("\t")
    if len(f) < 15:
        continue
    cc, pop, code = f[8], int(f[14] or 0), f[7]
    if code in ("PPLX", "PPLH", "PPLQ", "PPLW"):  # city sections, historical, abandoned
        continue
    if (cc == "US" and pop >= US_MIN_POP) or (cc != "US" and pop >= WORLD_MIN_POP):
        cities.append({"name": f[2] or f[1], "region": f[10] if cc == "US" else "", "cc": cc,
                       "lat": float(f[4]), "lon": float(f[5]), "pop": pop})
cities.sort(key=lambda c: -c["pop"])
print(f"cities: {len(cities)} ({sum(c['cc'] == 'US' for c in cities)} US)", flush=True)

# --- NASA POWER: yearly UV and humidity ------------------------------------------------------

cache = {}


def cell(c):
    return (round(c["lat"] * 2) / 2, round(c["lon"] * 2) / 2)


def nasa(key):
    lat, lon = key
    url = ("https://power.larc.nasa.gov/api/temporal/climatology/point?parameters=RH2M,ALLSKY_SFC_UV_INDEX"
           f"&community=RE&longitude={lon}&latitude={lat}&format=JSON")
    try:
        p = json.loads(get(url))["properties"]["parameter"]
        uv = p["ALLSKY_SFC_UV_INDEX"]
        rh = p["RH2M"]
        months = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
        good = lambda v: v is not None and v > -900  # noqa: E731
        return {
            "uv_ann": uv["ANN"] if good(uv["ANN"]) else None,
            "uv_max": max((uv[m] for m in months if good(uv[m])), default=None),
            "rh": rh["ANN"] if good(rh["ANN"]) else None,
        }
    except Exception as e:  # noqa: BLE001
        print(f"nasa failed {key}: {e}", flush=True)
        return None


keys = sorted({cell(c) for c in cities})
print(f"NASA cells: {len(keys)}", flush=True)
with ThreadPoolExecutor(max_workers=4) as pool:
    for i, (k, v) in enumerate(zip(keys, pool.map(nasa, keys))):
        cache[k] = v
        if i % 100 == 0:
            print(f"  {i}/{len(keys)}", flush=True)

# --- EPA: US air quality by metro ------------------------------------------------------------

centers = {}
for year in ("2024", "2023"):
    try:
        gaz = unzip_text(get(f"https://www2.census.gov/geo/docs/maps-data/data/gazetteer/{year}_Gazetteer/{year}_Gaz_cbsa_national.zip"), ".txt")
        rows = list(csv.reader(io.StringIO(gaz), delimiter="\t"))
        head = [h.strip() for h in rows[0]]
        for r in rows[1:]:
            d = dict(zip(head, [x.strip() for x in r]))
            centers.setdefault(d["GEOID"], (float(d["INTPTLAT"]), float(d["INTPTLONG"]), d["NAME"]))
    except Exception as e:  # noqa: BLE001
        print(f"gazetteer {year} failed: {e}", flush=True)
print(f"metro centers: {len(centers)}", flush=True)

aqi_years = {}
for year in ("2022", "2023", "2024"):
    try:
        data = unzip_text(get(f"https://aqs.epa.gov/aqsweb/airdata/annual_aqi_by_cbsa_{year}.zip"), ".csv")
        for d in csv.DictReader(io.StringIO(data)):
            aqi_years.setdefault(d["CBSA Code"], []).append(float(d["Median AQI"]))
    except Exception as e:  # noqa: BLE001
        print(f"EPA {year} failed: {e}", flush=True)

metros = []
for code, values in aqi_years.items():
    if code in centers:
        lat, lon, name = centers[code]
        places, _, states = name.partition(", ")
        metros.append({"lat": lat, "lon": lon, "aqi": sum(values) / len(values),
                       "places": {p.strip().lower() for p in places.split("-")},
                       "states": {s.strip()[:2] for s in states.split("-")}})
print(f"metros with AQI: {len(metros)}", flush=True)


def us_aqi(c):
    named = [m for m in metros if c["name"].lower() in m["places"] and c["region"] in m["states"]]
    if named:
        return named[0]["aqi"]
    best = min(metros, key=lambda m: km(c["lat"], c["lon"], m["lat"], m["lon"]), default=None)
    if best and km(c["lat"], c["lon"], best["lat"], best["lon"]) <= 100:
        return best["aqi"]
    return None


# --- Output -----------------------------------------------------------------------------------

rows, missing = [], 0
for c in cities:
    n = cache.get(cell(c))
    if not n or n["uv_ann"] is None or n["rh"] is None:
        missing += 1
        continue
    aqi = us_aqi(c) if c["cc"] == "US" else None
    rows.append([c["name"], c["region"], c["cc"], round(c["lat"], 2), round(c["lon"], 2),
                 round(n["uv_ann"], 1), round(n["uv_max"], 1) if n["uv_max"] is not None else None,
                 round(n["rh"]), round(aqi) if aqi is not None else None])

with open(OUT, "w") as f:
    json.dump({"fields": ["name", "region", "country", "lat", "lon", "uv_year", "uv_peak_month", "humidity", "aqi"],
               "sources": "GeoNames (CC BY 4.0), NASA POWER, US EPA AirData",
               "cities": rows}, f, separators=(",", ":"))

print(f"wrote {len(rows)} cities, skipped {missing} without NASA data", flush=True)
for name in ("Denver", "Miami", "Seattle", "Phoenix", "Los Angeles", "New York City", "London", "Dubai", "Tokyo"):
    print([r for r in rows if r[0] == name][:1], flush=True)
