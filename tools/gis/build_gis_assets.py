#!/usr/bin/env python3
"""Builds the GIS assets bundled into the FixBurgh app.

Downloads public open data, simplifies it, and writes compact GeoJSON to
assets/gis/ plus a manifest recording sources and fetch time.

  python3 tools/gis/build_gis_assets.py

Standard library only, so it runs anywhere Python 3.9+ is installed.

Sources (see docs/data-sources.md):
  * Allegheny County municipal boundaries (Allegheny County GIS via WPRDC)
  * Allegheny County-owned road centerlines (Allegheny County GIS via WPRDC)
  * PennDOT RMS roadway segments, Allegheny County (CTY_CODE 02), state
    (JURIS 1) and Turnpike (JURIS 2) roads only
"""

from __future__ import annotations

import datetime as dt
import json
import math
import pathlib
import urllib.parse
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "gis"

MUNI_URL = (
    "https://data.wprdc.org/dataset/2fa577d6-1a6b-46a8-8165-27fecac1dee5/"
    "resource/b0cb0249-d1ba-45b7-9918-dc86fa8af04c/download/muni_boundaries.geojson"
)
COUNTY_ROADS_URL = (
    "https://data.wprdc.org/dataset/582f82cb-800b-42b4-85a5-883ce46fceab/"
    "resource/449c2c8e-120e-478a-87de-beb089c395cf/download/co_centerlines.geojson"
)
PENNDOT_URL = (
    "https://gis.penndot.pa.gov/gis/rest/services/opendata/roadwaysegments/MapServer/0/query"
)

# Simplification tolerances in degrees (~1 degree latitude = 111 km).
POLYGON_TOLERANCE = 0.00003  # ~3 m
LINE_TOLERANCE = 0.00002  # ~2 m
DECIMALS = 5  # ~1 m


def fetch_json(url: str, params: dict | None = None) -> dict:
    if params:
        url = f"{url}?{urllib.parse.urlencode(params)}"
    req = urllib.request.Request(url, headers={"User-Agent": "FixBurgh-gis-build/1.0"})
    with urllib.request.urlopen(req, timeout=120) as resp:
        return json.load(resp)


def _perp_distance(p, a, b) -> float:
    # Scale longitude by cos(latitude) so distances are roughly isotropic.
    k = math.cos(math.radians(a[1]))
    px, py = p[0] * k, p[1]
    ax, ay = a[0] * k, a[1]
    bx, by = b[0] * k, b[1]
    dx, dy = bx - ax, by - ay
    if dx == 0 and dy == 0:
        return math.hypot(px - ax, py - ay)
    t = max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy)))
    return math.hypot(px - (ax + t * dx), py - (ay + t * dy))


def simplify(points: list, tol: float) -> list:
    """Iterative Douglas-Peucker."""
    if len(points) < 3:
        return points
    keep = [False] * len(points)
    keep[0] = keep[-1] = True
    stack = [(0, len(points) - 1)]
    while stack:
        start, end = stack.pop()
        max_d, idx = 0.0, -1
        for i in range(start + 1, end):
            d = _perp_distance(points[i], points[start], points[end])
            if d > max_d:
                max_d, idx = d, i
        if max_d > tol and idx != -1:
            keep[idx] = True
            stack.append((start, idx))
            stack.append((idx, end))
    return [p for p, k in zip(points, keep) if k]


def round_pts(points: list) -> list:
    out = []
    for x, y, *_ in points:
        pt = [round(x, DECIMALS), round(y, DECIMALS)]
        if not out or out[-1] != pt:
            out.append(pt)
    return out


def simplify_ring(ring: list) -> list | None:
    r = round_pts(simplify(ring, POLYGON_TOLERANCE))
    if r[0] != r[-1]:
        r.append(r[0])
    return r if len(r) >= 4 else None


def simplify_polygon_geom(geom: dict) -> dict:
    polys = [geom["coordinates"]] if geom["type"] == "Polygon" else geom["coordinates"]
    out = []
    for poly in polys:
        rings = [r for r in (simplify_ring(ring) for ring in poly) if r]
        if rings:
            out.append(rings)
    return {"type": "MultiPolygon", "coordinates": out}


def simplify_line_geom(geom: dict) -> dict:
    lines = [geom["coordinates"]] if geom["type"] == "LineString" else geom["coordinates"]
    out = []
    for line in lines:
        s = round_pts(simplify(line, LINE_TOLERANCE))
        if len(s) >= 2:
            out.append(s)
    return {"type": "MultiLineString", "coordinates": out}


def build_municipalities() -> dict:
    data = fetch_json(MUNI_URL)
    feats = []
    for f in data["features"]:
        p = f["properties"]
        name = p["LABEL"].strip()
        # The source TYPE field is truncated to 10 characters ("MUNICIPALI").
        kind = {"municipali": "municipality"}.get(p["TYPE"].strip().lower(), p["TYPE"].strip().lower())
        if kind == "city" and "city" not in name.lower():
            name = f"City of {name}"
        feats.append({
            "type": "Feature",
            "properties": {
                "id": str(p["MUNICODE"]).strip(),
                "name": name,
                "type": kind,
                "fips": p.get("FIPS"),
            },
            "geometry": simplify_polygon_geom(f["geometry"]),
        })
    feats.sort(key=lambda f: f["properties"]["name"])
    if len(feats) != 130:
        raise SystemExit(f"Expected 130 municipalities, got {len(feats)}")
    return {"type": "FeatureCollection", "features": feats}


def build_county_roads() -> dict:
    data = fetch_json(COUNTY_ROADS_URL)
    feats = []
    for f in data["features"]:
        if not f.get("geometry"):
            continue
        p = f["properties"]
        feats.append({
            "type": "Feature",
            "properties": {
                "name": (p.get("LegalName") or p.get("LocalName") or "").strip(),
                "route": (p.get("RouteNo") or "").strip(),
            },
            "geometry": simplify_line_geom(f["geometry"]),
        })
    return {"type": "FeatureCollection", "features": feats}


def build_state_roads() -> dict:
    feats, offset = [], 0
    while True:
        page = fetch_json(PENNDOT_URL, {
            "where": "CTY_CODE='02' AND JURIS IN ('1','2')",
            "outFields": "ST_RT_NO,STREET_NAME,TRAF_RT_NO,JURIS",
            "outSR": 4326,
            "resultOffset": offset,
            "resultRecordCount": 2000,
            "orderByFields": "OBJECTID",
            "f": "geojson",
        })
        batch = page.get("features", [])
        for f in batch:
            if not f.get("geometry"):
                continue
            p = f["properties"]
            feats.append({
                "type": "Feature",
                "properties": {
                    "owner": "turnpike" if p["JURIS"] == "2" else "penndot",
                    "sr": (p.get("ST_RT_NO") or "").strip(),
                    "name": (p.get("STREET_NAME") or "").strip().title(),
                    "route": (p.get("TRAF_RT_NO") or "").strip().lstrip("0"),
                },
                "geometry": simplify_line_geom(f["geometry"]),
            })
        if len(batch) < 2000:
            break
        offset += 2000
    return {"type": "FeatureCollection", "features": feats}


def write(name: str, fc: dict) -> int:
    path = OUT / name
    path.write_text(json.dumps(fc, separators=(",", ":")))
    size = path.stat().st_size
    print(f"  {name}: {len(fc['features'])} features, {size / 1024:.0f} KB")
    return size


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    print("Building GIS assets...")
    sizes = {
        "municipalities.geojson": write("municipalities.geojson", build_municipalities()),
        "county_roads.geojson": write("county_roads.geojson", build_county_roads()),
        "state_roads.geojson": write("state_roads.geojson", build_state_roads()),
    }
    manifest = {
        "version": dt.date.today().isoformat(),
        "generatedAt": dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds"),
        "sources": {
            "municipalities.geojson": MUNI_URL,
            "county_roads.geojson": COUNTY_ROADS_URL,
            "state_roads.geojson": PENNDOT_URL + " (CTY_CODE='02' AND JURIS IN ('1','2'))",
        },
        "bytes": sizes,
    }
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"Total {sum(sizes.values()) / 1024 / 1024:.2f} MB")


if __name__ == "__main__":
    main()
