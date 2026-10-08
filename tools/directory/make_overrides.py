#!/usr/bin/env python3
"""Turns verification_report.json into overrides.json.

  /usr/bin/python3 tools/directory/make_overrides.py

Rules, in order:
  1. Directory phone appears on the municipality's own site: keep it.
  2. Otherwise, if the site lists local numbers: use the one it shows most.
  3. Otherwise, drop the directory phone when other municipalities share it
     (it is a manager's or consultant's line, not the office), and flag the
     record for manual checking.
Emails come only from the municipality's own domain, preferring general
office addresses.

Review overrides.json (it lists the source for every change) before
rebuilding the directory with build_agency_directory.py.
"""

from __future__ import annotations

import collections
import datetime as dt
import json
import pathlib
import re

HERE = pathlib.Path(__file__).resolve().parent
REPORT = HERE / "verification_report.json"
OUT = HERE / "overrides.json"

PREFERRED = ("info", "office", "admin", "borough", "township", "secretary",
             "contact", "publicworks", "public.works", "manager", "clerk")


def digits(p: str | None) -> str:
    if not p:
        return ""
    return re.sub(r"\D", "", re.split(r"x|ext|ex\.", p, flags=re.I)[0])[-10:]


def fmt(n: str) -> str:
    return f"{n[:3]}-{n[3:6]}-{n[6:]}"


# Addresses for other departments or groups, not the municipal office.
EXCLUDED = ("police", "fire", "chief", "club", "court", "library", "rec", "park",
            "tax", "school", "webmaster", "noreply", "no-reply", "events", "news",
            "ems", "pool", "senior", "zoning", "code")


def best_email(emails: list[str]) -> str | None:
    usable = [e for e in emails if not any(w in e.split("@")[0] for w in EXCLUDED)]
    for word in PREFERRED:
        for e in usable:
            if word in e.split("@")[0]:
                return e
    return None


def main() -> None:
    report = json.loads(REPORT.read_text())
    shared = {n for n, c in collections.Counter(digits(r["phone"]) for r in report).items() if c > 1}
    overrides: dict[str, dict] = {}
    summary = collections.Counter()
    for r in report:
        o: dict = {}
        site = r.get("website")
        if r["status"] == "phone_found":
            summary["phone confirmed on site"] += 1
        elif r.get("sitePhones"):
            o["phone"] = fmt(r["sitePhones"][0])
            o["phoneSource"] = site
            o["was"] = r["phone"]
            summary["phone replaced from site"] += 1
        elif digits(r["phone"]) in shared:
            o["phone"] = None
            o["was"] = r["phone"]
            o["needsCheck"] = "Directory number is shared with other municipalities; site unreadable."
            summary["shared phone dropped"] += 1
        else:
            o["needsCheck"] = f"Could not read {site or 'website'} to confirm the phone."
            summary["unconfirmed"] += 1
        email = best_email(r.get("emails") or [])
        if email:
            o["email"] = email
            o["emailSource"] = site
            summary["email added"] += 1
        if o:
            overrides[r["id"]] = o
    OUT.write_text(json.dumps(
        {"generatedAt": dt.date.today().isoformat(), "overrides": overrides},
        indent=1,
    ) + "\n")
    for k, v in summary.items():
        print(f"{k}: {v}")


if __name__ == "__main__":
    main()
