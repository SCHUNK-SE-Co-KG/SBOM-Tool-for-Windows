# SBOM Tool for Windows — Quick Guide (EN)

Portable tools to generate and compare SBOMs on Windows 10/11 (CRA / BSI TR-03183-2, CycloneDX 1.6).

---

## Requirements

- Windows 10 or 11
- PowerShell 5.1 (pre-installed)
- No installation or internet required
- Admin rights optional (fewer drivers without admin)

---

## 1. Generate an SBOM

1. Unzip or clone the folder (e.g. from [Releases](https://github.com/SCHUNK-SE-Co-KG/SBOM-Tool-for-Windows/releases))
2. Double-click **`SBOM-Create.cmd`**
3. Wait for the scan to finish — the HTML report opens automatically
4. Output is written to **`sbom-output\`**:
   - `HOSTNAME-sbom-DATE.cdx.json` — CycloneDX (machine-readable)
   - `HOSTNAME-sbom-DATE.html` — interactive report (DE/EN, light/dark)
   - `HOSTNAME-sbom-DATE.txt` — text summary

**Tip:** Archive a baseline SBOM before rolling out a new image or update.

---

## 2. Compare SBOMs

1. Open **`SBOM-Compare.html`** in your browser (double-click)
2. **Source 1** = older / baseline SBOM (`.cdx.json`)
3. **Source 2** = current SBOM (`.cdx.json`)
4. Optional: load **`SBOM-Approved-Differences.json`** (approved version changes)
5. Click **Compare**

### Traffic lights

| Color | Meaning |
|-------|---------|
| Green | Unchanged |
| Orange | Version change |
| Purple | Approved version change |
| Red | Newly added |
| Gray | Removed |

### Approved differences

- Mark orange rows as **approved**
- **Export JSON** → master file `SBOM-Approved-Differences.json`
- **Import JSON** → replaces all rules
- **Merge JSON** → append rules from another file (skips duplicates)

**Master from several machines:** each person exports rules — load one file, click **Merge JSON**, pick the other file, then **Export JSON**.

**Manual JSON editing:** see the comment in `SBOM-Approved-Differences.json`. Short: `anyVersion: true` = any version change for that software name is approved (no fixed from/to versions).

---

## 3. Portable copy (USB / target PC)

Minimum files to copy:

```
SBOM-Create.cmd
Get-WindowsSBOM.ps1
SBOM-Compare.html
SBOM-Approved-Differences.json   (optional, if you have rules)
assets\logos\                    (for HTML branding)
```

`sbom-output\` is created automatically when you run a scan.

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| CMD window closes immediately | Do not move the folder while a scan is running; CMD uses `-ExecutionPolicy Bypass` |
| Compare shows nothing | Both files must be valid CycloneDX JSON (`.cdx.json`) |
| Empty driver section | Re-run the scan with administrator rights |

---

## Contact

**SCHUNK Electronic Solutions GmbH**  
https://www.ses-support.de · electronic-solutions@de.schunk.com
