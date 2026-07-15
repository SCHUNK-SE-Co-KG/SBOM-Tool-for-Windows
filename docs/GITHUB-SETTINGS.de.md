# GitHub-Einstellungen — SBOM Tool for Windows

Kurzanleitung, wo du die CI-/Security-Einstellungen findest und was bereits automatisch gesetzt wurde.

Repo: https://github.com/SCHUNK-SE-Co-KG/SBOM-Tool-for-Windows

---

## Bereits per API aktiviert (Stand 1.1)

| Einstellung | Status |
|-------------|--------|
| Dependabot Security Updates | **aktiv** |
| Dependabot (`.github/dependabot.yml`) | **aktiv** — wöchentliche PRs |
| GitHub Actions Workflows | **im Repo** — Tests, Trivy, CVE, CodeQL, Release |
| Repository-Beschreibung & Topics | **gesetzt** |

> **Hinweis Enterprise:** Write permissions for workflows sind ggf. org-weit gesperrt.  
> Siehe Abschnitt *Actions-Berechtigungen* unten.

---

## Org-Admin nötig (Code Security / GHAS)

Diese Features sind auf dem Repo aktuell **disabled**, weil sie eine **GitHub Advanced Security (GHAS)**-Lizenz auf Organisationsebene brauchen:

| Feature | Pfad in GitHub |
|---------|----------------|
| **Code Security (Code scanning / CodeQL Upload)** | Organisation: **Settings → Code security and analysis → GitHub Advanced Security** → Repositories auswählen |
| **Secret scanning** | gleiche Seite, unter Advanced Security |
| **Secret scanning push protection** | gleiche Seite |

### Nach Aktivierung durch Org-Admin

1. Repo → **Settings → Code security and analysis**
2. **Code scanning** → Enable (oder Default setup von CodeQL)
3. In `.github/workflows/codeql.yml` ändern:
   ```yaml
   upload: true   # statt false
   ```
4. Commit + Push

---

## Repo-Einstellungen (du als Maintainer)

### Actions erlauben

**Settings → Actions → General**

- *Workflow permissions:* **Read and write** (für Report-Commits durch CI)  
  Falls ausgegraut: Enterprise-Admin muss unter **Enterprise → Policies → Actions** Schreibrechte für Workflows freigeben.
- *Allow GitHub Actions to create and approve pull requests:* optional aktivieren (Dependabot)

### Dependabot

**Settings → Code security and analysis**

- **Dependabot alerts** → Enable  
- **Dependabot security updates** → Enable (sollte bereits an sein)

### Branch protection (optional, empfohlen für `main`)

**Settings → Branches → Add branch protection rule**

- Branch: `main`
- Require status checks: **Tests** (windows-tests + python-tests)
- Require pull request before merging (optional)

### Releases & Tags

- Ab **v1.1.0** erzeugt `.github/workflows/release.yml` automatisch ein ZIP bei jedem Tag `v*`
- Manuell: **Releases → Draft a new release → Choose tag `v1.1.0`**

---

## Wo finde ich die Badges / CI-Ergebnisse?

| Was | Wo |
|-----|-----|
| Workflow-Läufe | Repo → **Actions** |
| Dependabot-PRs | Repo → **Pull requests** (Label `dependencies`) |
| CVE-Issues | Repo → **Issues** (Labels `cve-alert`, `cve-monthly-report`) |
| Trivy/CVE-Reports im Code | Ordner `security/reports/` |
| CodeQL (wenn GHAS aktiv) | Repo → **Security → Code scanning** |

---

## Kontakt bei fehlenden Rechten

**Code Security / Secret scanning** kann nur ein **Organisation-Owner** oder **Security-Manager** freischalten.  
Bitte an GitHub-Org-Admin von SCHUNK-SE-Co-KG wenden mit Link zu diesem Repo.
