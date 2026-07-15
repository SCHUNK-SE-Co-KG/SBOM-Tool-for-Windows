# Changelog

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
