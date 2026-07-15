# SBOM Tool for Windows — Kurzanleitung (DE)

Portable Tools zur SBOM-Erfassung und zum Vergleich auf Windows 10/11 (CRA / BSI TR-03183-2, CycloneDX 1.6).

---

## Voraussetzungen

- Windows 10 oder 11
- PowerShell 5.1 (vorinstalliert)
- Keine Installation, kein Internet nötig
- Admin-Rechte optional (ohne Admin werden weniger Treiber erfasst)

---

## 1. SBOM erstellen

1. Ordner entpacken oder klonen (z. B. von [Releases](https://github.com/SCHUNK-SE-Co-KG/SBOM-Tool-for-Windows/releases))
2. **`SBOM-Create.cmd`** per Doppelklick starten
3. Warten bis Scan fertig — HTML-Report öffnet sich automatisch
4. Ergebnisse liegen in **`sbom-output\`**:
   - `HOSTNAME-sbom-DATUM.cdx.json` — CycloneDX (maschinenlesbar)
   - `HOSTNAME-sbom-DATUM.html` — interaktiver Report (DE/EN, Hell/Dunkel)
   - `HOSTNAME-sbom-DATUM.txt` — Textzusammenfassung

**Tipp:** Ältere SBOM als Baseline kopieren und archivieren, bevor du ein neues Image oder Update ausrollst.

---

## 2. SBOM vergleichen

1. **`SBOM-Compare.html`** im Browser öffnen (Doppelklick)
2. **Quelle 1** = ältere / Baseline-SBOM (`.cdx.json`)
3. **Quelle 2** = aktuelle SBOM (`.cdx.json`)
4. Optional: **`SBOM-Approved-Differences.json`** laden (genehmigte Versionsunterschiede)
5. Auf **Vergleichen** klicken

### Ampelfarben

| Farbe | Bedeutung |
|-------|-----------|
| Grün | Unverändert |
| Orange | Versionsänderung |
| Lila | Genehmigte Versionsänderung |
| Rot | Neu hinzugefügt |
| Grau | Entfernt |

### Genehmigte Unterschiede

- Orange Zeilen können als **genehmigt** markiert werden
- Regeln per **Export JSON** speichern → `SBOM-Approved-Differences.json`
- Beim nächsten Vergleich diese Datei wieder laden

---

## 3. Ordner auf USB / Zielrechner

Mindestens diese Dateien mitnehmen:

```
SBOM-Create.cmd
Get-WindowsSBOM.ps1
SBOM-Compare.html
SBOM-Approved-Differences.json   (optional, falls Regeln vorhanden)
assets\logos\                    (für Darstellung in HTML)
```

`sbom-output\` wird beim Scan automatisch angelegt.

---

## Fehlerbehebung

| Problem | Lösung |
|---------|--------|
| CMD schließt sofort | PowerShell-Ausführungsrichtlinie: CMD nutzt `-ExecutionPolicy Bypass` — Ordner nicht verschieben während Scan läuft |
| HTML-Vergleich zeigt nichts | Beide Dateien müssen gültige CycloneDX-JSON sein (`.cdx.json`) |
| Leerer Treiber-Block | Scan mit Admin-Rechten wiederholen |

---

## Kontakt

**SCHUNK Electronic Solutions GmbH**  
https://www.ses-support.de · electronic-solutions@de.schunk.com
