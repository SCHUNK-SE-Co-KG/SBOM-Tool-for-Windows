# Changelog

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
