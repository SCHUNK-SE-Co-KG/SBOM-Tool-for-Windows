# SBOM Tool for Windows

**Portable Software Bill of Materials generator for installed Windows systems — aligned with CRA / BSI TR-03183-2 (CycloneDX 1.6)**

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
| Kunden-Branding / Customer branding | [docs/Customer-Branding-Guide-DE-EN.md](docs/Customer-Branding-Guide-DE-EN.md) |
| Kunden-Branding Word / Customer branding Word | [docs/Customer-Branding-Guide-DE-EN.docx](docs/Customer-Branding-Guide-DE-EN.docx) |

**Quick start:** double-click `SBOM-Create.cmd` to scan · open `SBOM-Compare.html` in a browser to compare two `.cdx.json` files.

### Offline comparison and whitelist workflow

1. Create the delivery SBOM and keep it as the baseline.
2. Create a current SBOM on the offline machine.
3. Open `SBOM-Compare.html`, load both SBOMs and the current master whitelist.
4. Review changes: approved version changes are purple; unapproved version changes are orange.
5. Approve agreed changes, use **Merge JSON** to combine the colleague's whitelist with the current master, resolve displayed conflicts, then use **Export JSON** to create the next master revision.

**Import JSON** replaces the current working rules. **Merge JSON** performs a three-way merge when both files share a `documentId` and the colleague file contains a `base` snapshot. Independent additions, updates, and deletions are combined. Parallel changes to the same rule are shown as conflicts; export remains blocked until each conflict is resolved with **Keep master** or **Use colleague**. Older whitelist files without revision metadata remain supported through additive merge. An explicitly loaded whitelist is authoritative and is not mixed with older browser-local approvals.

Every export contains the next `revision` and the loaded master as its `base`. Therefore, always load the newest master first and merge the returned colleague file into it. The shipped `SBOM-Approved-Differences.json` is intentionally empty at revision 0.

---

## End-user files

```
SBOM-Create.cmd                 # Primary scan entry point
SBOM-Compare.html               # Browser-based SBOM compare (no install)
SBOM-Approved-Differences.json  # Optional approved-version rules
Customer-Info.example.txt       # Customer organization/address template
Customer-Logo.example.svg       # Customer logo template
_internal/                       # PowerShell generator, CLI, integrity tools, and fixed assets
```

Registry-based inventory includes .NET runtimes only where they are registered in the Windows uninstall keys. Each report lists whether every source was collected, skipped, partially readable, or failed.

---

## Features

| Feature | Description |
|---------|-------------|
| Windows SBOM scan | OS, patches, registry apps, Store apps, features, drivers |
| CycloneDX 1.6 | BSI TR-03183-2 v2.1.0 aligned JSON |
| Hash evidence | SHA-512 where a concrete file is available; per-component `bsi:hashStatus` otherwise |
| HTML report | Sortable tables, search, DE/EN, light/dark |
| SBOM compare | Traffic-light diff in the browser |
| Portable | Copy folder to USB — no install required |

### Portable customer branding

Customer branding is optional and requires no installation. Keep the files beside `SBOM-Create.cmd`:

1. Copy `Customer-Info.example.txt` to `Customer-Info.txt` and edit the UTF-8 `key=value` fields.
2. Copy `Customer-Logo.example.svg` to `Customer-Logo.svg`, or provide `Customer-Logo.png`, `.jpg`, or `.jpeg`.
3. Run the scan normally.

The customer logo is embedded directly in every generated HTML report as a data URI, so reports remain standalone. The customer name is written to the CycloneDX `manufacture` and `supplier` metadata; address and contact details appear in the HTML footer. Logos are limited to 5 MB. If the customer files are absent, the report stays neutral. SCHUNK Electronic Solutions GmbH remains identified as the tool developer and tool-component supplier.

The enforced maximum logo file size is 5 MB. There is no fixed pixel limit; approximately 1200 x 400 pixels with an aspect ratio of about 3:1 is recommended. Before installing a new tool version, back up `Customer-Info.txt`, `Customer-Logo.*`, `SBOM-Approved-Differences.json`, and important `sbom-output` reports. Extract the new version into a new folder, copy the backed-up files into it, verify the tool, and run a test scan before retiring the old folder.

Active `Customer-Info.txt` and `Customer-Logo.*` files are intentionally ignored by Git and excluded from the integrity manifest because deployments are expected to customize them. The `.example` files remain protected reference templates.

### Offline integrity check

Run `_internal/integrity/Verify-SBOM-Tool.cmd` before use. It verifies the immutable runtime files against `_internal/integrity/SBOM-Tool-SHA256.txt`. Text is normalised to UTF-8/LF so Git's Windows line-ending conversion does not cause false alarms; binary assets are checked byte-for-byte. The whitelist is intentionally excluded because approvals are expected to change. Checksums detect accidental or unauthorised file changes only when the manifest came from a trusted source; digital signing remains the stronger authenticity control.

---

## PowerShell (advanced)

```powershell
.\_internal\generator\Get-WindowsSBOM.ps1 -All
.\_internal\generator\Get-WindowsSBOM.ps1 -OutputDir "C:\SBOM" -IncludeDrivers
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

`_internal/cli/Compare-WindowsSBOM.ps1` remains for automated tests and CLI use; end users compare via `SBOM-Compare.html`.

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
