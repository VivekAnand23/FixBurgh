#!/usr/bin/env python3
"""Cross-checks municipal contacts against each municipality's own website.

  /usr/bin/python3 tools/directory/verify_contacts.py

For every municipal agency in assets/directory/agencies.json it downloads the
website's home page (and a /contact page if linked) and:
  * looks for the directory phone number on the site,
  * lists other phone numbers the site shows,
  * collects published email addresses on the municipality's own domain.

Writes tools/directory/verification_report.json for a human to review. Nothing
here edits the directory; confirmed fixes go in tools/directory/overrides.json.
"""

from __future__ import annotations

import concurrent.futures as cf
import html
import json
import pathlib
import re
import ssl
import urllib.parse
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[2]
AGENCIES = ROOT / "assets" / "directory" / "agencies.json"
REPORT = ROOT / "tools" / "directory" / "verification_report.json"

PHONE = re.compile(r"\(?\b(\d{3})\)?[\s.\-]?(\d{3})[\s.\-](\d{4})\b")
EMAIL = re.compile(r"[\w.+-]+@[\w-]+(?:\.[\w-]+)+")
LOCAL_AREA_CODES = {"412", "724", "878"}
CONTACT_LINK = re.compile(r'href="([^"]*contact[^"]*)"', re.I)

# Some small-town sites have expired certificates; we only read public pages.
_CTX = ssl.create_default_context()
_LOOSE = ssl.create_default_context()
_LOOSE.check_hostname = False
_LOOSE.verify_mode = ssl.CERT_NONE


def fetch(url: str) -> str:
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 FixBurgh-verify/1.0"})
    for ctx in (_CTX, _LOOSE):
        try:
            with urllib.request.urlopen(req, timeout=20, context=ctx) as r:
                return r.read(800_000).decode("utf-8", errors="ignore")
        except ssl.SSLError:
            continue
    return ""


def digits(p: str) -> str:
    return re.sub(r"\D", "", p)[-10:]


def check(agency: dict) -> dict:
    site = agency.get("website")
    out = {"id": agency["id"], "name": agency["name"], "phone": agency.get("phone"), "website": site}
    if not site:
        out["status"] = "no_website"
        return out
    pages = []
    try:
        home = fetch(site)
        pages.append(home)
        m = CONTACT_LINK.search(home)
        if m:
            pages.append(fetch(urllib.parse.urljoin(site, html.unescape(m.group(1)))))
    except Exception as e:  # noqa: BLE001 - report and move on
        out["status"] = f"fetch_error: {type(e).__name__}"
        return out
    text = html.unescape(" ".join(pages))
    if not text.strip():
        out["status"] = "empty"
        return out
    counts: dict[str, int] = {}
    for m in PHONE.finditer(text):
        n = "".join(m.groups())
        if n[:3] in LOCAL_AREA_CODES and len(set(n)) > 1:
            counts[n] = counts.get(n, 0) + 1
    phones = set(counts)
    want = digits(agency.get("phone") or "")
    domain = urllib.parse.urlparse(site).hostname or ""
    base = ".".join(domain.split(".")[-2:])
    emails = sorted(
        {
            e.lower().rstrip(".")
            for e in EMAIL.findall(text)
            if e.lower().split("@")[1].endswith(base)
            and not e.lower().endswith((".png", ".jpg", ".gif", ".webp"))
        }
    )
    out.update(
        status="phone_found" if want in phones else "phone_not_found",
        sitePhones=sorted(counts, key=lambda n: -counts[n])[:8],
        siteCounts=counts,
        emails=emails[:8],
    )
    return out


def main() -> None:
    data = json.loads(AGENCIES.read_text())
    munis = [a for a in data["agencies"] if a["type"] == "municipal"]
    with cf.ThreadPoolExecutor(max_workers=8) as pool:
        results = list(pool.map(check, munis))
    results.sort(key=lambda r: (r["status"], r["name"]))
    REPORT.write_text(json.dumps(results, indent=1) + "\n")
    from collections import Counter

    print(Counter(r["status"].split(":")[0] for r in results))
    print("with emails:", sum(bool(r.get("emails")) for r in results))


if __name__ == "__main__":
    main()
