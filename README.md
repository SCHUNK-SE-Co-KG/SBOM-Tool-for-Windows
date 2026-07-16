# SBOM Tool for Windows

**Portable Software Bill of Materials generator for installed Windows systems — CRA / BSI TR-03183-2 compliant (CycloneDX 1.6)**

![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)
![Tests](https://github.com/SCHUNK-SE-Co-KG/SBOM-Tool-for-Windows/actions/workflows/tests.yml/badge.svg?branch=main)
![Trivy Scan](https://github.com/SCHUNK-SE-Co-KG/SBOM-Tool-for-Windows/actions/workflows/trivy-scan.yml/badge.svg?branch=main)
![CVE-Scan](https://github.com/SCHUNK-SE-Co-KG/SBOM-Tool-for-Windows/actions/workflows/cve-scan.yml/badge.svg?branch=main)
![Release](https://badgen.net/github/release/SCHUNK-SE-Co-KG/SBOM-Tool-for-Windows/green)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-5391FE.svg)
![CycloneDX](https://img.shields.io/badge/CycloneDX-1.6-green.svg)

Developed by **SCHUNK Electronic Solutions GmbH** for CRA compliance on Windows machines, workstations, and build images.

---

## User guides

| Topic | Document (DE + EN) |
|-------|-------------------|
| SBOM erstellen / Create | [docs/SBOM-Create-Guide-DE-EN.pdf](docs/SBOM-Create-Guide-DE-EN.pdf) |
| SBOM vergleichen / Compare | [docs/SBOM-Compare-Guide-DE-EN.pdf](docs/SBOM-Compare-Guide-DE-EN.pdf) |

**Quick start:** double-click `SBOM-Create.cmd` to scan · open `SBOM-Compare.html` in a browser to compare two `.cdx.json` files.

---

## End-user files

```
SBOM-Create.cmd                 # One-click full SBOM scan
Get-WindowsSBOM.ps1             # PowerShell engine (called by CMD)
SBOM-Compare.html               # Browser-based SBOM compare (no install)
SBOM-Approved-Differences.json  # Optional approved-version rules
assets/logos/                   # SCHUNK branding for HTML reports
```

Output per scan: `sbom-output\` → `.cdx.json`, `.html`, `.txt`

---

## Features

| Feature | Description |
|---------|-------------|
| Windows SBOM scan | OS, patches, registry apps, Store apps, features, drivers |
| CycloneDX 1.6 | BSI TR-03183-2 v2.1.0 compliant JSON |
| HTML report | Sortable tables, search, DE/EN, light/dark |
| SBOM compare | Traffic-light diff in the browser |
| Portable | Copy folder to USB — no install required |

---

## PowerShell (advanced)

```powershell
.\Get-WindowsSBOM.ps1 -All
.\Get-WindowsSBOM.ps1 -OutputDir "C:\SBOM" -IncludeDrivers
```

---

## Developer / CI

| Area | Location |
|------|----------|
| Tests | `tests/` — `run_tests.bat` |
| Security scans | `security/` — CVE/Trivy via GitHub Actions (artifacts) |
| Workflows | `.github/workflows/` — tests, CVE, Trivy, release on tags |
| Changelog | [CHANGELOG.md](CHANGELOG.md) |

```cmd
cd tests
run_tests.bat
```

`Compare-WindowsSBOM.ps1` remains for automated tests and CLI use; end users compare via `SBOM-Compare.html`.

---

## CRA context

| CRA requirement | Tool support |
|-----------------|--------------|
| SBOM / component documentation | CycloneDX 1.6 JSON with name, version, supplier, PURL, hashes |
| Vulnerability identification | SBOM diff comparator + optional CVE/Trivy scans of repo dependencies |
| Traceability | Timestamped reports, hostname-based filenames |

> SBOM creation and comparison only — full CRA compliance needs additional organizational processes.

---

## License

**GNU General Public License v3.0** — see [LICENSE](LICENSE).

```
SBOM Tool for Windows
Copyright (C) 2026 SCHUNK SE & Co. KG
```

**SCHUNK Electronic Solutions GmbH** · Am Tannwald 17, 78112 St. Georgen im Schwarzwald  
https://www.ses-support.de · electronic-solutions@de.schunk.com
