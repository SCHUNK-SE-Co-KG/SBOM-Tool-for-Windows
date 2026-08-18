# Security Policy / Sicherheitsrichtlinie

## Supported versions / Unterstützte Versionen

| Version | Supported / Unterstützt |
|---------|------------------------|
| 1.4.x   | Yes / Ja               |
| 1.3.x   | No / Nein              |
| < 1.3   | No / Nein              |

We maintain security fixes for the **latest release** only. Download the current release from [Releases](https://github.com/SCHUNK-SE-Co-KG/SBOM-Tool-for-Windows/releases).

---

## Reporting a vulnerability / Schwachstelle melden

**Please do not open public GitHub issues for security vulnerabilities.**

| | |
|---|---|
| **Preferred** | Email: **Informationssicherheit@de.schunk.com** |
| **Subject** | `[SBOM-Tool-for-Windows] Security report` |
| **Language** | German or English |

Include where possible:

- Affected version (e.g. v1.3.0)
- Component (e.g. `Get-WindowsSBOM.ps1`, `SBOM-Compare.html`)
- Steps to reproduce
- Impact assessment
- Proof-of-concept (if any)

### What to expect / Was Sie erwarten können

- **Acknowledgement** within 5 business days / **Eingangsbestätigung** innerhalb von 5 Werktagen
- **Status update** as we investigate / **Status-Update** während der Prüfung
- **Coordinated disclosure** — we ask that you do not publish details before a fix or agreed timeline / **Koordinierte Offenlegung** — bitte keine Veröffentlichung vor Fix oder abgestimmtem Zeitplan

We do not operate a bug bounty program for this open-source tool.

---

## Scope / Geltungsbereich

**In scope**

- This repository: PowerShell scripts, HTML/JS compare tool, CMD launcher, CI workflows
- Vulnerabilities that affect users running the portable tool on Windows

**Out of scope**

- Vulnerabilities in third-party software listed in generated SBOMs (report to the respective vendor)
- Misconfiguration of customer systems or missing organizational CRA processes
- Social engineering

---

## Secure use / Sichere Nutzung

- Run scans only on systems you are authorised to inventory.
- Treat generated `.cdx.json` / HTML reports as **internal asset data** (installed software inventory).
- Download releases only from the official GitHub releases page or your organisation’s verified mirror.
- Verify ZIP integrity via GitHub release assets (SHA-256 digest shown in release metadata when available).
- On offline systems, run `_internal/integrity/Verify-SBOM-Tool.cmd` before scanning and compare against the trusted `_internal/integrity/SBOM-Tool-SHA256.txt` manifest.
- The mutable whitelist and active `Customer-Info.txt` / `Customer-Logo.*` branding are deliberately excluded from the tool manifest. Control whitelist changes through the documented revision/merge workflow and protect customer branding files from unauthorised changes.

---

## Maintainer / Verantwortlich

**SCHUNK Electronic Solutions GmbH**  
https://www.ses-support.de
