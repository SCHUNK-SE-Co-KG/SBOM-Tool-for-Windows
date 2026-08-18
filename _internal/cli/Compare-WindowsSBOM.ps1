#Requires -Version 5.1
<#
.SYNOPSIS
    Vergleicht zwei CycloneDX SBOM-Dateien und erzeugt einen interaktiven HTML-Report.
    Compares two CycloneDX SBOM files and generates an interactive HTML report.

.PARAMETER Source1
    Baseline / alte SBOM (.cdx.json). Ohne Angabe: Dateiauswahl-Dialog.
    Baseline / old SBOM (.cdx.json). If omitted: file picker dialog.

.PARAMETER Source2
    Neue SBOM (.cdx.json). Ohne Angabe: Dateiauswahl-Dialog.
    New SBOM (.cdx.json). If omitted: file picker dialog.

.PARAMETER ApprovedFile
    JSON mit genehmigten Versionsunterschieden.
    JSON file with approved version differences.

.PARAMETER OutputDir
    Zielverzeichnis fuer den HTML-Report.
    Target directory for the HTML report.

.EXAMPLE
    .\Compare-WindowsSBOM.ps1
    .\Compare-WindowsSBOM.ps1 -Source1 .\sbom-output\alt.cdx.json -Source2 .\sbom-output\neu.cdx.json
#>

[CmdletBinding()]
param(
    [string]$Source1,
    [string]$Source2,
    [string]$ApprovedFile,
    [string]$OutputDir,
    [switch]$NoBrowser
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$RepoRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)
if (-not $OutputDir) {
    $OutputDir = Join-Path $RepoRoot "sbom-output"
}
if (-not $ApprovedFile) {
    $ApprovedFile = Join-Path $RepoRoot "SBOM-Approved-Differences.json"
}
$TemplateFile = Join-Path $RepoRoot "SBOM-Compare.html"

function Select-SbomFile {
    param([string]$Title)
    Add-Type -AssemblyName System.Windows.Forms
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Title = $Title
    $dlg.Filter = "CycloneDX JSON (*.cdx.json;*.json)|*.cdx.json;*.json|Alle Dateien (*.*)|*.*"
    $dlg.InitialDirectory = if (Test-Path (Join-Path $RepoRoot "sbom-output")) {
        (Join-Path $RepoRoot "sbom-output")
    } else { $RepoRoot }
    if ($dlg.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
        throw "Abgebrochen -/- Cancelled"
    }
    return $dlg.FileName
}

function Read-JsonFile {
    param([string]$Path)
    if (-not (Test-Path $Path)) { throw "Datei nicht gefunden -/- File not found: $Path" }
    $raw = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
    try {
        return ($raw | ConvertFrom-Json -ErrorAction Stop)
    } catch {
        throw "Ungueltige JSON-Datei -/- Invalid JSON file: $Path ($($_.Exception.Message))"
    }
}

function Read-SbomFile {
    param([string]$Path)
    $bom = Read-JsonFile $Path
    if (-not $bom.PSObject.Properties['bomFormat'] -or $bom.bomFormat -ne 'CycloneDX') {
        throw "Keine CycloneDX-SBOM -/- Not a CycloneDX SBOM: $Path"
    }
    if (-not $bom.PSObject.Properties['specVersion']) {
        throw "CycloneDX-Version fehlt -/- CycloneDX version missing: $Path"
    }
    if (-not $bom.PSObject.Properties['components']) {
        throw "Komponentenliste fehlt -/- Components list missing: $Path"
    }
    return $bom
}

function Read-ApprovedFile {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        return [PSCustomObject]@{ version = 1; rules = @() }
    }
    $approved = Read-JsonFile $Path
    if (-not $approved.PSObject.Properties['rules']) {
        throw "Whitelist ohne rules-Liste -/- Whitelist has no rules list: $Path"
    }
    foreach ($rule in @($approved.rules)) {
        if (-not $rule.PSObject.Properties['name'] -or [string]::IsNullOrWhiteSpace([string]$rule.name)) {
            throw "Whitelist-Regel ohne Namen -/- Whitelist rule without name: $Path"
        }
        if ($rule.PSObject.Properties['match'] -and $rule.match -notin @('exact', 'wildcard')) {
            throw "Ungueltiger Whitelist-Match -/- Invalid whitelist match: $($rule.match)"
        }
    }
    return $approved
}

function ConvertTo-SafeJavaScriptJson {
    param($Value, [int]$Depth = 100)
    $json = $Value | ConvertTo-Json -Compress -Depth $Depth
    return $json.Replace('&', '\u0026').Replace('<', '\u003c').Replace('>', '\u003e')
}

function Get-SbomLabel {
    param($Bom, [string]$FilePath)
    $hostLabel = $env:COMPUTERNAME
    $ts = ""
    if ($Bom.metadata -and $Bom.metadata.component) {
        $comp = $Bom.metadata.component
        if ($comp.name -match '^([A-Z0-9_-]+)') { $hostLabel = $Matches[1] }
    }
    if ($Bom.metadata.timestamp) { $ts = $Bom.metadata.timestamp }
    return [ordered]@{
        file     = (Split-Path $FilePath -Leaf)
        path     = $FilePath
        host     = $hostLabel
        timestamp = $ts
        componentCount = @($Bom.components).Count
    }
}

Write-Host ""
Write-Host "  SCHUNK SBOM Vergleich -/- SBOM Compare" -ForegroundColor Cyan
Write-Host "  ======================================" -ForegroundColor Cyan
Write-Host ""

if (-not $Source1) {
    Write-Host "  Quelle 1 (Baseline) waehlen... -/- Select source 1 (baseline)..." -ForegroundColor Yellow
    $Source1 = Select-SbomFile "SBOM Quelle 1 / Source 1 (Baseline)"
}
if (-not $Source2) {
    Write-Host "  Quelle 2 (Neu) waehlen... -/- Select source 2 (new)..." -ForegroundColor Yellow
    $Source2 = Select-SbomFile "SBOM Quelle 2 / Source 2 (New)"
}

Write-Host "  Quelle 1 -/- Source 1: $(Split-Path $Source1 -Leaf)" -ForegroundColor DarkGray
Write-Host "  Quelle 2 -/- Source 2: $(Split-Path $Source2 -Leaf)" -ForegroundColor DarkGray
Write-Host ""

if (-not (Test-Path $TemplateFile)) {
    throw "Vorlage fehlt -/- Template missing: $TemplateFile"
}

$bom1 = Read-SbomFile $Source1
$bom2 = Read-SbomFile $Source2
$approved = Read-ApprovedFile $ApprovedFile

$meta = [ordered]@{
    generated = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    source1   = Get-SbomLabel $bom1 $Source1
    source2   = Get-SbomLabel $bom2 $Source2
    approvedFile = (Split-Path $ApprovedFile -Leaf)
}

$bom1Json = ConvertTo-SafeJavaScriptJson $bom1
$bom2Json = ConvertTo-SafeJavaScriptJson $bom2
$approvedJson = ConvertTo-SafeJavaScriptJson $approved
$metaJson = ConvertTo-SafeJavaScriptJson $meta -Depth 6
$preloadJson = "{""bom1"":$bom1Json,""bom2"":$bom2Json,""approved"":$approvedJson,""meta"":$metaJson}"

$html = [System.IO.File]::ReadAllText($TemplateFile, [System.Text.Encoding]::UTF8)
$inject = "<script>window.__PRELOADED__=$preloadJson;</script>"
if ($html -match '<!-- PRELOAD -->') {
    $html = $html -replace '<!-- PRELOAD -->', $inject
} else {
    $html = $html -replace '</head>', "$inject`n</head>"
}
# Reports in sbom-output/ need relative path to internal assets
$html = $html -replace 'src="_internal/assets/', 'src="../_internal/assets/'
$html = $html -replace 'href="_internal/assets/', 'href="../_internal/assets/'

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$s1Tag = ($meta.source1.host -replace '[^\w\-]', '')
$s2Tag = ($meta.source2.host -replace '[^\w\-]', '')
$dateSuffix = Get-Date -Format "yyyyMMdd-HHmmss"
$outFile = Join-Path $OutputDir "sbom-compare-${s1Tag}-vs-${s2Tag}-$dateSuffix.html"

$utf8 = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($outFile, $html, $utf8)

Write-Host "  Report erstellt -/- Report created:" -ForegroundColor Green
Write-Host "  $outFile" -ForegroundColor Yellow
Write-Host ""

if (-not $NoBrowser) {
    Start-Process $outFile
}
