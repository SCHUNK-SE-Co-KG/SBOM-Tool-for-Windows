#Requires -Version 5.1
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

$requiredFiles = @(
    "_internal/generator/Get-WindowsSBOM.ps1"
    "_internal/cli/Compare-WindowsSBOM.ps1"
    "SBOM-Compare.html"
    "SBOM-Create.cmd"
    "VERSION"
    "Customer-Info.example.txt"
    "Customer-Logo.example.svg"
    "_internal/integrity/New-SBOM-ToolChecksums.ps1"
    "_internal/integrity/Test-SBOM-ToolIntegrity.ps1"
    "_internal/integrity/Verify-SBOM-Tool.cmd"
    "_internal/assets/logos/SCHUNK_Logo_Dark.svg"
    "_internal/assets/logos/SCHUNK_Logo_Typenschild_Light.svg"
    "_internal/assets/logos/SCHUNK_Signet.png"
)
$binaryFiles = @("_internal/assets/logos/SCHUNK_Signet.png")

function Get-PortableSHA256([string]$Path, [string]$RelativePath) {
    if ($RelativePath -in $binaryFiles) {
        return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
    }
    $text = [System.IO.File]::ReadAllText($Path).Replace("`r`n", "`n").Replace("`r", "`n")
    $bytes = (New-Object System.Text.UTF8Encoding $false).GetBytes($text)
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($sha256.ComputeHash($bytes)) -replace '-', '').ToLowerInvariant() }
    finally { $sha256.Dispose() }
}

$manifest = Join-Path $PSScriptRoot "SBOM-Tool-SHA256.txt"
if (-not (Test-Path $manifest -PathType Leaf)) { throw "Checksum manifest missing: $manifest" }

$entries = @{}
foreach ($line in Get-Content -LiteralPath $manifest) {
    if (-not $line.Trim()) { continue }
    if ($line -notmatch '^([0-9a-fA-F]{64}) \*(.+)$') { throw "Invalid checksum line: $line" }
    $relativePath = $Matches[2]
    if ($entries.ContainsKey($relativePath)) { throw "Duplicate checksum entry: $relativePath" }
    $entries[$relativePath] = $Matches[1].ToLowerInvariant()
}

$failures = [System.Collections.ArrayList]::new()
foreach ($relativePath in $requiredFiles) {
    if (-not $entries.ContainsKey($relativePath)) {
        [void]$failures.Add("Manifest entry missing: $relativePath")
        continue
    }
    $path = Join-Path $RepoRoot ($relativePath -replace '/', '\')
    if (-not (Test-Path $path -PathType Leaf)) {
        [void]$failures.Add("File missing: $relativePath")
        continue
    }
    $actual = Get-PortableSHA256 $path $relativePath
    if ($actual -ne $entries[$relativePath]) { [void]$failures.Add("Hash mismatch: $relativePath") }
}

foreach ($relativePath in $entries.Keys) {
    if ($relativePath -notin $requiredFiles) { [void]$failures.Add("Unexpected manifest entry: $relativePath") }
}

if ($failures.Count) {
    $failures | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    throw "Tool integrity check failed with $($failures.Count) error(s)."
}

Write-Host "SBOM tool integrity verified ($($requiredFiles.Count) files)." -ForegroundColor Green