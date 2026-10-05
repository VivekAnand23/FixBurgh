# Data sources

FixBurgh's smart routing uses public open data. `tools/gis/build_gis_assets.py`
downloads it, simplifies it and writes compact GeoJSON to `assets/gis/`, which is
bundled into the app so routing works offline. `assets/gis/manifest.json`
records the source URLs and build date.

Verified on October 4, 2026.

| Asset | Source | Features | Bundled size |
|---|---|---|---|
| `municipalities.geojson` | Allegheny County Municipal Boundaries, Allegheny County GIS via WPRDC ([dataset](https://data.wprdc.org/dataset/allegheny-county-municipal-boundaries)) | 130 | ~280 KB |
| `county_roads.geojson` | Allegheny County Owned Roads Centerlines, Allegheny County GIS via WPRDC ([dataset](https://data.wprdc.org/dataset/allegheny-county-owned-roads-centerlines)) | 367 (~383 miles) | ~220 KB |
| `state_roads.geojson` | PennDOT RMS roadway segments ([MapServer layer 0](https://gis.penndot.pa.gov/gis/rest/services/opendata/roadwaysegments/MapServer/0)), filtered to `CTY_CODE='02'` (Allegheny) and `JURIS IN ('1','2')` | 3,911 | ~1.2 MB |

## Field notes

### Municipal boundaries
- `MUNICODE` is used as the municipality ID (`100` = City of Pittsburgh).
- The source `TYPE` field is truncated to 10 characters (`MUNICIPALI`); the
  build script maps it to `municipality`.
- City names are normalized to "City of X".

### PennDOT roadway segments
The RMS layer includes more than state roads. Ownership comes from two fields:

| `JURIS` | `GOVT_LVL_CTRL` (HPMS ownership) | Meaning | Count in Allegheny |
|---|---|---|---|
| `1` | `1` State highway agency | **PennDOT state road** | 3,877 |
| `2` | `31` State toll authority | **PA Turnpike** | 46 |
| `5` | `2` County highway agency | County road (federal-aid only) | 462 |
| `5` | `3` Town or township agency | Local road | 67 |
| `5` | `4` City or municipal agency | Local road (e.g. Grant St) | 875 |

Only `JURIS` 1 and 2 are bundled as state roads. County ownership comes from
the County's own centerlines dataset, which is complete (the RMS county rows
cover only federal-aid roads).

Key fields kept: `ST_RT_NO` (state route, e.g. `0051`), `STREET_NAME`,
`TRAF_RT_NO` (signed route number).

### Live queries
For a fresher answer when online, the same layer supports spatial queries:

```
.../roadwaysegments/MapServer/0/query?geometry=<lng>,<lat>&geometryType=esriGeometryPoint
  &inSR=4326&distance=25&units=esriSRUnit_Meter&outFields=ST_RT_NO,STREET_NAME,JURIS
  &returnGeometry=false&f=json
```

## Licensing and attribution
WPRDC lists these Allegheny County datasets without a specific license; PennDOT
publishes its open data for public use. The app shows attribution under
Profile > Data sources. Re-check terms before each store release.

## Rebuilding

```bash
python3 tools/gis/build_gis_assets.py
```

On macOS, if the python.org build of Python fails with
`CERTIFICATE_VERIFY_FAILED`, use `/usr/bin/python3` or run that Python's
`Install Certificates.command` once.

## Office directory

`tools/directory/build_agency_directory.py` writes `assets/directory/agencies.json`:

- **130 municipalities**: phone, mailing address and website from Allegheny
  County's official municipality directory
  ([munimap](https://apps.alleghenycounty.us/website/munimap.asp), one
  `profile.asp?muni=N` page each). Directory names are matched to boundary
  `MUNICODE`s by name and municipality type.
- **Curated offices**: PennDOT District 11 (1-800-FIX-ROAD), PA Turnpike,
  Allegheny County Public Works (412-350-INFO, option 2), City of Pittsburgh
  311 (412-255-2621). Each has a `source` URL.

The county directory is maintained by the municipalities and contains some
errors (for example, at least one 724 area code for a 412 municipality).
Re-run the script and spot-check numbers before each release; users can flag
a wrong office in the app.

```bash
/usr/bin/python3 tools/directory/build_agency_directory.py
```
