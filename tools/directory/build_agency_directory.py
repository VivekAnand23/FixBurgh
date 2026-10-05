#!/usr/bin/env python3
"""Builds assets/directory/agencies.json, the office directory used by
smart routing.

  /usr/bin/python3 tools/directory/build_agency_directory.py

Municipal contacts come from Allegheny County's official municipality
directory (apps.alleghenycounty.us/website/munimap.asp, one profile page per
municipality). State, County and City of Pittsburgh offices are curated in
STATIC_AGENCIES below. Every record keeps its source URL and the date it was
fetched so stale entries can be re-verified.

Standard library only. Requests are spaced out to be polite to the server.
"""

from __future__ import annotations

import datetime as dt
import html
import json
import pathlib
import re
import time
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "directory" / "agencies.json"
BOUNDARIES = ROOT / "assets" / "gis" / "municipalities.geojson"
BASE = "https://apps.alleghenycounty.us/website/"

# Offices that are not individual municipalities. Verified Oct 2026; re-check
# before each store release (see docs/data-sources.md).
STATIC_AGENCIES = [
    {
        "id": "penndot-d11",
        "name": "PennDOT District 11",
        "type": "state",
        "phone": "1-800-349-7623",
        "phoneLabel": "1-800-FIX-ROAD",
        "website": "https://www.penndot.pa.gov/RegionalOffices/district-11/Pages/default.aspx",
        "webFormUrl": "https://www.penndot.pa.gov/about-us/customer-care-center",
        "hours": "24/7 for road hazards",
        "source": "https://www.penndot.pa.gov/about-us/customer-care-center",
    },
    {
        "id": "pa-turnpike",
        "name": "Pennsylvania Turnpike Commission",
        "type": "state",
        "phone": "1-800-331-3414",
        "website": "https://www.paturnpike.com/contact-us",
        "source": "https://www.paturnpike.com/contact-us",
    },
    {
        "id": "allegheny-dpw",
        "name": "Allegheny County Department of Public Works",
        "type": "county",
        "phone": "412-350-4636",
        "phoneLabel": "412-350-INFO (option 2)",
        "website": "https://www.alleghenycounty.us/Projects-and-Initiatives/Public-Works",
        "hours": "Weekdays",
        "source": "https://nevilletownship.us/how-to-report-a-road-concern-to-penndot-or-allegheny-county/",
    },
    {
        "id": "pittsburgh-311",
        "name": "City of Pittsburgh 311",
        "type": "311",
        "phone": "412-255-2621",
        "phoneLabel": "311 (or 412-255-2621)",
        "website": "https://www.pittsburghpa.gov/311",
        "webFormUrl": "https://pgh.311.request.com",
        "hours": "Mon-Fri 7am-7pm",
        "municipalityIds": ["100"],
        "source": "https://www.pittsburghpa.gov/311",
    },
]


def fetch(url: str) -> str:
    req = urllib.request.Request(url, headers={"User-Agent": "FixBurgh-directory-build/1.0"})
    with urllib.request.urlopen(req, timeout=60) as resp:
        return resp.read().decode("utf-8", errors="ignore")


def text_lines(page: str) -> list[str]:
    page = re.sub(r"<script.*?</script>|<style.*?</style>|<!--.*?-->", "", page, flags=re.S)
    page = re.sub(r"<[^>]+>", "\n", page)
    page = html.unescape(page)
    return [re.sub(r"\s+", " ", l).strip() for l in page.split("\n") if l.strip()]


def norm(name: str) -> str:
    """Matches 'Borough of Ben Avon Hts.' to 'Ben Avon Heights Borough'.

    Keeps the kind (borough, township...) because several names exist twice,
    e.g. Baldwin Borough and Baldwin Township.
    """
    n = name.lower().replace(".", "").replace("'", "")
    kinds = re.findall(r"\b(borough|township|municipality|city|town)\b", n)
    n = re.sub(r"\b(borough|township|municipality|city|town|of)\b", " ", n)
    n = re.sub(r"\bhts\b", "heights", n)
    n = re.sub(r"\bmt\b", "mount", n)
    n = re.sub(r"\s+", " ", n).strip()
    return f"{n}|{kinds[0] if kinds else ''}"


def parse_profile(page: str, url: str) -> dict:
    lines = text_lines(page)
    name = lines[lines.index("Municipality:") + 1] if "Municipality:" in lines else ""
    rec: dict = {"name": name, "source": url}
    if "Community Contact" in lines:
        block = lines[lines.index("Community Contact") + 1:]
        addr = []
        for l in block:
            if l.startswith("Phone:"):
                rec["phone"] = l.split(":", 1)[1].strip()
            elif l.startswith(("Fax:", "US Census")):
                break
            elif not rec.get("phone"):
                addr.append(l)
        # First line is the contact person; the rest is the mailing address.
        if len(addr) > 1:
            rec["address"] = ", ".join(addr[1:])
    links = re.findall(r'href="(https?://[^"]+)"', page)
    site = next(
        (h for h in links if "allegheny" not in h.lower() and "cog" not in h.lower()
         and "census" not in h.lower() and "state.pa" not in h.lower()),
        None,
    )
    if site:
        rec["website"] = site
    return rec


def main() -> None:
    boundaries = json.loads(BOUNDARIES.read_text())
    by_norm = {norm(f["properties"]["name"]): f["properties"] for f in boundaries["features"]}
    # Fallback for names whose kind differs between sources (e.g. Penn Hills is
    # a "Township" in the directory but a "Municipality" in the boundaries).
    base_counts: dict[str, list] = {}
    for key, props in by_norm.items():
        base_counts.setdefault(key.split("|")[0].replace(" ", ""), []).append(props)
    by_base = {b: ps[0] for b, ps in base_counts.items() if len(ps) == 1}
    agencies = list(STATIC_AGENCIES)
    missing = []
    today = dt.date.today().isoformat()
    for i in range(1, 140):
        url = f"{BASE}profile.asp?muni={i}"
        try:
            rec = parse_profile(fetch(url), url)
        except Exception as e:  # noqa: BLE001 - keep going, report at the end
            print(f"  muni={i}: {e}")
            continue
        if not rec["name"]:
            continue
        key = norm(rec["name"])
        props = by_norm.get(key) or by_base.get(key.split("|")[0].replace(" ", ""))
        if not props:
            missing.append(rec["name"])
            continue
        agencies.append({
            "id": f"muni-{props['id']}",
            "name": props["name"],
            "type": "municipal",
            "municipalityIds": [props["id"]],
            **{k: v for k, v in rec.items() if k in ("phone", "address", "website", "source")},
            "lastVerifiedAt": today,
        })
        time.sleep(0.3)

    for a in STATIC_AGENCIES:
        a.setdefault("lastVerifiedAt", today)
    covered = {m for a in agencies for m in a.get("municipalityIds", [])}
    uncovered = [p["name"] for p in by_norm.values() if p["id"] not in covered]
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps({"generatedAt": today, "agencies": agencies}, indent=1) + "\n")
    print(f"Wrote {len(agencies)} agencies; {len(covered)} of {len(by_norm)} municipalities covered")
    if missing:
        print("Directory names not matched to a boundary:", missing)
    if uncovered:
        print("Municipalities without a contact:", uncovered)


if __name__ == "__main__":
    main()
