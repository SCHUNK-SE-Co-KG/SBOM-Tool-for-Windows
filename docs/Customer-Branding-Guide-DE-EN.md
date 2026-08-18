# Kunden-Branding / Customer Branding

Kurzanleitung für Logo und Organisationsdaten im portablen SBOM-Bericht.

Short guide for the logo and organization details in the portable SBOM report.

---

## Deutsch

### Dateien

Die Dateien liegen direkt neben `SBOM-Create.cmd`:

- `Customer-Info.example.txt` ist die Vorlage für die Anschrift.
- `Customer-Logo.example.svg` ist eine Beispiel-Logo-Datei.
- `Customer-Info.txt` und `Customer-Logo.svg` sind die aktiven Kundendateien.

### Einrichtung

1. Kopieren Sie `Customer-Info.example.txt` nach `Customer-Info.txt`.
2. Öffnen Sie `Customer-Info.txt` als UTF-8-Textdatei.
3. Ersetzen Sie die Beispielwerte hinter `=`.
4. Kopieren Sie Ihr Logo nach `Customer-Logo.svg` oder verwenden Sie `Customer-Logo.png`, `.jpg` oder `.jpeg`.
5. Starten Sie `SBOM-Create.cmd`.

Für Logos gilt: Die maximale Dateigröße beträgt 5 MB. Eine feste Pixelgrenze gibt es nicht; empfohlen wird ein sauberes Seitenverhältnis von ungefähr 3:1 und eine Ausgangsgröße von etwa 1200 x 400 Pixeln. Das Logo wird im Bericht proportional verkleinert.

Beispiel:

```text
Name=Beispiel GmbH
AddressLine1=Musterstraße 12
AddressLine2=12345 Musterstadt
Country=Deutschland
Phone=+49 123 456789
Email=info@beispiel.de
URL=https://www.beispiel.de
```

### Ergebnis

- Das Logo wird direkt als Data-URI in den HTML-Bericht eingebettet.
- Der Bericht bleibt dadurch ohne externe Logo-Datei vollständig nutzbar.
- Der Kundenname erscheint als Organisation im SBOM und im Bericht.
- Anschrift und Kontaktdaten erscheinen in der Fußzeile des HTML-Berichts.
- SCHUNK Electronic Solutions GmbH bleibt als Hersteller des Tools erkennbar.

### Hinweise

- Die Kundendateien sind optional. Fehlen sie, bleibt der Bericht neutral.
- Das Logo darf höchstens 5 MB groß sein.
- Eine feste Pixelgrenze gibt es nicht; empfohlen werden ungefähr 1200 x 400 Pixel bei einem Seitenverhältnis von etwa 3:1.
- Nur vertrauenswürdige Logo- und Textdateien verwenden.
- Kundendaten können personenbezogene oder vertrauliche Informationen enthalten.
- Aktive Kundendateien sind nicht Teil des Tool-Integritätsmanifests, weil sie angepasst werden sollen.
- Die `.example`-Dateien sind nur Vorlagen und werden nicht automatisch verwendet.

### Update auf eine neue Toolversion

1. Sichern Sie vor dem Update `Customer-Info.txt`, `Customer-Logo.*`, `SBOM-Approved-Differences.json` und wichtige Dateien aus `sbom-output`.
2. Entpacken Sie die neue Version in einen neuen Ordner. Überschreiben Sie den alten Toolordner nicht.
3. Kopieren Sie die gesicherten Kundendateien und die Whitelist in den neuen Toolordner.
4. Prüfen Sie die neue Version mit `_internal/integrity/Verify-SBOM-Tool.cmd`.
5. Führen Sie einen Testscan aus und prüfen Sie Logo, Anschrift und Whitelist, bevor Sie den alten Ordner archivieren.

---

## English

### Files

The files are placed directly beside `SBOM-Create.cmd`:

- `Customer-Info.example.txt` is the address template.
- `Customer-Logo.example.svg` is an example logo file.
- `Customer-Info.txt` and `Customer-Logo.svg` are the active customer files.

### Setup

1. Copy `Customer-Info.example.txt` to `Customer-Info.txt`.
2. Open `Customer-Info.txt` as a UTF-8 text file.
3. Replace the example values after `=`.
4. Copy your logo to `Customer-Logo.svg`, or use `Customer-Logo.png`, `.jpg`, or `.jpeg`.
5. Run `SBOM-Create.cmd`.

The maximum logo file size is 5 MB. There is no fixed pixel limit; a clean aspect ratio of about 3:1 and an input size of approximately 1200 x 400 pixels are recommended. The logo is scaled down proportionally in the report.

Example:

```text
Name=Example Ltd.
AddressLine1=Example Street 12
AddressLine2=12345 Example City
Country=Germany
Phone=+49 123 456789
Email=info@example.com
URL=https://www.example.com
```

### Result

- The logo is embedded directly as a data URI in the HTML report.
- The report therefore remains fully usable without an external logo file.
- The customer name appears as the organization in the SBOM and report.
- Address and contact details appear in the HTML report footer.
- SCHUNK Electronic Solutions GmbH remains identified as the tool developer.

### Notes

- Customer files are optional. Without them, the report remains neutral.
- The logo must not exceed 5 MB.
- There is no fixed pixel limit; approximately 1200 x 400 pixels with an aspect ratio of about 3:1 is recommended.
- Use only trusted logo and text files.
- Customer data may contain personal or confidential information.
- Active customer files are excluded from the tool integrity manifest because they are intended to be customized.
- The `.example` files are templates only and are not used automatically.

### Updating to a new tool version

1. Before updating, back up `Customer-Info.txt`, `Customer-Logo.*`, `SBOM-Approved-Differences.json`, and important files from `sbom-output`.
2. Extract the new version into a new folder. Do not overwrite the old tool folder.
3. Copy the backed-up customer files and whitelist into the new tool folder.
4. Verify the new version with `_internal/integrity/Verify-SBOM-Tool.cmd`.
5. Run a test scan and check the logo, address, and whitelist before archiving the old folder.
