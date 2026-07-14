#!/usr/bin/env python3
"""
CVE-Scanner for SBOM-Tool-for-Windows.

Scans Python dependencies (tests/requirements.txt, security/requirements.txt)
against the Google OSV API (https://osv.dev).

Usage:
    python security/cve_scanner.py
    python security/cve_scanner.py --json-only
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")

try:
    import requests
except ImportError:
    sys.exit("Error: install requests — pip install -r security/requirements.txt")

ROOT_DIR = Path(__file__).resolve().parent.parent
REPORT_DIR = ROOT_DIR / "security" / "reports"
REQUIREMENT_FILES = [
    ROOT_DIR / "tests" / "requirements.txt",
    ROOT_DIR / "security" / "requirements.txt",
]

OSV_QUERY_URL = "https://api.osv.dev/v1/query"
OSV_BATCH_URL = "https://api.osv.dev/v1/querybatch"
OSV_VULN_URL = "https://api.osv.dev/v1/vulns"
REPO_NAME = "SCHUNK-SE-Co-KG/SBOM-Tool-for-Windows"
CVSS_HIGH_THRESHOLD = 7.0

SEVERITY_LABEL_SCORES = {
    "CRITICAL": 9.0,
    "HIGH": 7.5,
    "MODERATE": 5.0,
    "MEDIUM": 5.0,
    "LOW": 2.5,
}


@dataclass
class Dependency:
    name: str
    version: str
    ecosystem: str
    source: str


@dataclass
class Vulnerability:
    vuln_id: str
    summary: str
    severity: str
    cvss_score: float
    affected_package: str
    affected_versions: str
    fixed_version: str
    references: list[str] = field(default_factory=list)
    aliases: list[str] = field(default_factory=list)


@dataclass
class ScanResult:
    timestamp: str
    repository: str
    dependencies_scanned: int
    vulnerabilities_found: int
    high_severity_count: int = 0
    dependencies: list[Dependency] = field(default_factory=list)
    vulnerabilities: list[Vulnerability] = field(default_factory=list)


def extract_python_dependencies(req_path: Path) -> list[Dependency]:
    if not req_path.exists():
        return []
    deps: list[Dependency] = []
    req_re = re.compile(r"^(?P<name>[A-Za-z0-9_-]+)(?:[><=!~]+(?P<version>[A-Za-z0-9_.]+))?")
    for line in req_path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or ";" in line.split("#")[0]:
            continue
        m = req_re.match(line.split(";")[0].strip())
        if m:
            deps.append(
                Dependency(
                    name=m.group("name"),
                    version=m.group("version") or "",
                    ecosystem="PyPI",
                    source=str(req_path.relative_to(ROOT_DIR)),
                )
            )
    return deps


def _build_osv_query(dep: Dependency) -> dict:
    q: dict = {"package": {"name": dep.name, "ecosystem": dep.ecosystem}}
    if dep.version:
        q["version"] = dep.version
    return q


def query_osv_batch(deps: list[Dependency]) -> list[list[dict]]:
    if not deps:
        return []
    queries = [_build_osv_query(d) for d in deps]
    try:
        resp = requests.post(OSV_BATCH_URL, json={"queries": queries}, timeout=30)
        resp.raise_for_status()
        return [r.get("vulns", []) for r in resp.json().get("results", [])]
    except requests.RequestException:
        results: list[list[dict]] = []
        for dep in deps:
            try:
                resp = requests.post(OSV_QUERY_URL, json=_build_osv_query(dep), timeout=15)
                resp.raise_for_status()
                results.append(resp.json().get("vulns", []))
            except requests.RequestException:
                results.append([])
        return results


def _compute_cvss_score(vuln: dict, severity_str: str) -> float:
    db_severity = vuln.get("database_specific", {}).get("severity", "").upper()
    if db_severity in SEVERITY_LABEL_SCORES:
        return SEVERITY_LABEL_SCORES[db_severity]
    upper = severity_str.upper()
    for label, score in SEVERITY_LABEL_SCORES.items():
        if label in upper:
            return score
    return 0.0


def _extract_fixed_version(affected: dict) -> str:
    for rng in affected.get("ranges", []):
        for event in rng.get("events", []):
            if "fixed" in event:
                return event["fixed"]
    return "-"


def parse_vulnerabilities(dep: Dependency, vulns: list[dict]) -> list[Vulnerability]:
    results: list[Vulnerability] = []
    for v in vulns:
        severity = "UNKNOWN"
        for s in v.get("severity", []):
            if s.get("score"):
                severity = s["score"]
                break
        fixed_version = "-"
        affected_versions = ""
        for aff in v.get("affected", []):
            if aff.get("package", {}).get("name") == dep.name:
                affected_versions = ", ".join(aff.get("versions", [])[:10])
                fixed_version = _extract_fixed_version(aff)
                break
        results.append(
            Vulnerability(
                vuln_id=v.get("id", "?"),
                summary=(v.get("summary") or v.get("details") or "No description")[:300],
                severity=severity,
                cvss_score=_compute_cvss_score(v, severity),
                affected_package=f"{dep.ecosystem}:{dep.name}@{dep.version}",
                affected_versions=affected_versions,
                fixed_version=fixed_version,
                references=[r.get("url", "") for r in v.get("references", []) if r.get("url")][:5],
                aliases=v.get("aliases", []),
            )
        )
    return results


def generate_markdown_report(result: ScanResult) -> str:
    lines = [
        "# CVE-Scan Report – SBOM Tool for Windows",
        "",
        f"**Scan time:** {result.timestamp}  ",
        f"**Repository:** {result.repository}  ",
        f"**Dependencies scanned:** {result.dependencies_scanned}  ",
        f"**Vulnerabilities found:** {result.vulnerabilities_found}",
        "",
    ]
    if result.vulnerabilities_found == 0:
        lines.append("> No known vulnerabilities found.")
    else:
        lines.append(f"> {result.vulnerabilities_found} vulnerability/vulnerabilities found.")
    lines.extend(["", "## Scanned dependencies", "", "| Package | Version | Source |", "|---------|---------|--------|"])
    for d in result.dependencies:
        lines.append(f"| {d.name} | {d.version or '-'} | {d.source} |")
    lines.append("")
    if result.vulnerabilities:
        lines.append("## Vulnerabilities")
        lines.append("")
        for v in result.vulnerabilities:
            cves = ", ".join(a for a in v.aliases if a.startswith("CVE-")) or "-"
            marker = " HIGH" if v.cvss_score >= CVSS_HIGH_THRESHOLD else ""
            lines.extend([
                f"### {v.vuln_id}",
                "",
                f"- **Package:** {v.affected_package}",
                f"- **CVSS:** {v.cvss_score:.1f}{marker}",
                f"- **CVE:** {cves}",
                f"- **Summary:** {v.summary}",
                f"- **Fix version:** {v.fixed_version}",
                "",
            ])
    lines.extend(["---", "*Generated by `security/cve_scanner.py` via [OSV.dev](https://osv.dev).*", ""])
    return "\n".join(lines)


def write_alert_output(result: ScanResult) -> None:
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    alert_path = REPORT_DIR / "alert_high_severity.txt"
    if result.high_severity_count > 0:
        body = [
            f"CVE Alert: {result.high_severity_count} high-severity finding(s)",
            f"Repository: {result.repository}",
            f"Scan: {result.timestamp}",
            "",
        ]
        for v in result.vulnerabilities:
            if v.cvss_score >= CVSS_HIGH_THRESHOLD:
                body.append(f"  {v.vuln_id} CVSS {v.cvss_score:.1f} — {v.affected_package}")
        alert_path.write_text("\n".join(body), encoding="utf-8")
        gh_output = os.environ.get("GITHUB_OUTPUT")
        if gh_output:
            with open(gh_output, "a", encoding="utf-8") as f:
                f.write("high_severity=true\n")
                f.write(f"high_count={result.high_severity_count}\n")
    else:
        if alert_path.exists():
            alert_path.unlink()
        gh_output = os.environ.get("GITHUB_OUTPUT")
        if gh_output:
            with open(gh_output, "a", encoding="utf-8") as f:
                f.write("high_severity=false\n")


def run_scan() -> ScanResult:
    all_deps: list[Dependency] = []
    seen: set[str] = set()
    for path in REQUIREMENT_FILES:
        for dep in extract_python_dependencies(path):
            key = f"{dep.name}:{dep.version}"
            if key not in seen:
                seen.add(key)
                all_deps.append(dep)

    batch = query_osv_batch(all_deps)
    all_vulns: list[Vulnerability] = []
    for dep, vulns in zip(all_deps, batch):
        all_vulns.extend(parse_vulnerabilities(dep, vulns))

    high = [v for v in all_vulns if v.cvss_score >= CVSS_HIGH_THRESHOLD]
    return ScanResult(
        timestamp=datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        repository=REPO_NAME,
        dependencies_scanned=len(all_deps),
        vulnerabilities_found=len(all_vulns),
        high_severity_count=len(high),
        dependencies=all_deps,
        vulnerabilities=all_vulns,
    )


def main() -> None:
    parser = argparse.ArgumentParser(description="CVE scanner for SBOM Tool dependencies")
    parser.add_argument("--json-only", action="store_true")
    args = parser.parse_args()

    result = run_scan()
    if args.json_only:
        print(json.dumps(asdict(result), indent=2, ensure_ascii=False))
        return

    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    (REPORT_DIR / "cve_report.json").write_text(
        json.dumps(asdict(result), indent=2, ensure_ascii=False), encoding="utf-8"
    )
    (REPORT_DIR / "cve_report.md").write_text(generate_markdown_report(result), encoding="utf-8")
    write_alert_output(result)

    if result.vulnerabilities_found > 0:
        sys.exit(1)
    sys.exit(0)


if __name__ == "__main__":
    main()
