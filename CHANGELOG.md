# Changelog

## [1.4.1] - 2026-10-19

### Fixed
- CycloneDX 1.6 schema compliance: `acknowledgement` for `LicenseRef-*`/`NOASSERTION` licenses is now written inside the `license` object instead of next to it. Previously Dependency-Track 5.2 rejected the BOM with "Schema validation failed". SPDX `expression` entries are unchanged.

### Added
- Pester tests for `acknowledgement` placement in license entries

### Upgrade note
- SBOMs generated with v1.4.0 must be regenerated.

## [1.4.0] - 2026-08-18

### Added
- Versioned whitelist exports with stable document ID, revision, and merge-base snapshot
- Three-way whitelist merge for parallel additions, updates, and deletions
- Visible merge-conflict resolution; unresolved conflicts block export
- Per-component `bsi:hashStatus` and explicit hash-coverage reporting
- `DisplayIcon` executable discovery to improve application hash coverage
- Store executable and driver INF hash evidence with explicit hash-target metadata
- Per-source collection status and offline SBOM structural validation
- Stable component identity for same-name installations from different registry sources
- Automated headless-browser regression tests for identity and three-way merge behavior
- Offline SHA-256 runtime-file manifest and verification launcher
- Optional portable customer branding from `Customer-Info.txt` and an embedded `Customer-Logo.*`
- Inactive SCHUNK customer-branding examples for downstream deployments
- Bilingual customer-branding documentation in Markdown and Word format

### Changed
- Legacy whitelists without revision metadata use backward-compatible additive merge
- HTML/TXT compliance summaries report measured SHA-512 coverage instead of blanket hash success
- Supplier, filename, license, and hash completeness are measured in generated reports
- .NET runtime documentation now reflects registry-based discovery instead of a separate collector
- Compliance wording distinguishes BSI alignment from formal conformity assessment
- Generated reports use customer organization data when configured; SCHUNK remains identified as the tool developer
- Technical CLI, integrity tooling, and fixed logo assets are grouped under `_internal/` for a cleaner portable root folder
- The CMD launcher is the primary scan entry point; the PowerShell generator is grouped under `_internal/generator/` for advanced use
- Customer branding documentation describes logo size limits, backups, and version-update migration

### Release notes
- This release keeps the portable offline workflow and browser-only comparison unchanged for end users.
- Existing whitelists without revision metadata remain supported.
- Before updating, back up customer branding, whitelist data, and required reports; install v1.4.0 in a new folder.

## [1.3.0] - 2026-07-16

### Added
- **Illustrated user guides (PDF)** — bilingual DE/EN, step-by-step:
  - `docs/SBOM-Create-Guide-DE-EN.pdf` — scan workflow, HTML report, admin tip for drivers
  - `docs/SBOM-Compare-Guide-DE-EN.pdf` — compare, colours, approve rules, Import/Merge/Export JSON, team workflow
- **Save As export** in `SBOM-Compare.html` — `showSaveFilePicker` with browser-download fallback

### Changed
- README links to PDF guides (DOCX/build assets stay local only)
- `.gitignore`: `docs/` tracks **PDFs only** on GitHub
- Compare sidebar hints updated for Export JSON behaviour
- Release badge in README (shields.io, works on public repos)

### Removed
- Legacy markdown guides `docs/GUIDE.de.md` and `docs/GUIDE.en.md` (replaced by PDF guides)

## [1.2.2] - 2026-07-15

### Added
- **Merge JSON** in `SBOM-Compare.html` — combine approved-rules files without duplicates
- Template `SBOM-Approved-Differences.json` documents `anyVersion` and rule fields

## [1.2.1] - 2026-07-15

### Changed
- English filenames: `SBOM-Create.cmd`, `SBOM-Compare.html`, `docs/GUIDE.de.md`

## [1.2.0] - 2026-07-15

### Added
- User guides: `docs/ANLEITUNG.de.md` and `docs/GUIDE.en.md`

### Removed
- `SBOM-Vergleichen.cmd` — compare via `SBOM-Vergleichen.html` in the browser
- `SBOM-Win-Create.cmd` — duplicate launcher (use `SBOM-Erstellen.cmd`)
- shields.io release badge (broken on private repos)
- Committed security scan reports (now CI artifacts only)

### Changed
- README slimmed down; user docs linked at the top

## [1.1.1] - 2026-07-15

### Removed
- CodeQL workflow (required GitHub Advanced Security / Code Security settings)
- Dependabot configuration (required org/repo Dependabot settings)
- CVE monthly report workflow (required issue creation and write permissions)
- GitHub settings guide (`docs/GITHUB-SETTINGS.de.md`)
- Auto-commits of scan reports to the repository

### Changed
- CVE and Trivy workflows upload reports as **Actions artifacts** only
- Tests workflow: tool SBOM as artifact only (read-only `GITHUB_TOKEN`)

## [1.1.0] - 2026-07-15

### Added
- SCHUNK Corporate Identity UI (Light/Dark, DE/EN) for HTML reports and compare tool
- Logo assets under `assets/logos/`
- CI status badges in README
- PSScriptAnalyzer in Windows CI
- CycloneDX 1.6 schema validation tests
- Tool dependency SBOM (`security/generate_tool_sbom.py`)
- CodeQL workflow, Dependabot, automated release ZIP on tags
- GitHub settings guide (`docs/GITHUB-SETTINGS.de.md`)

### Changed
- Product version aligned to **1.1.0** (was internal v3.0 label)
- GitHub Actions upgraded to Node 24 runtimes
- TIA-style terminology removed from docs and UI

## [1.0.0] - 2026-07-15

### Added
- Initial release: Windows SBOM generator (CycloneDX 1.6, BSI TR-03183-2)
- SBOM compare tool with traffic-light diff
- CVE/OSV and Trivy security scanning
- Pester and pytest test suite
