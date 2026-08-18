#Requires -Version 5.1
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

$files = @(
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

$lines = foreach ($relativePath in $files) {
    $path = Join-Path $RepoRoot ($relativePath -replace '/', '\')
    if (-not (Test-Path $path -PathType Leaf)) { throw "Runtime file missing: $relativePath" }
    $hash = Get-PortableSHA256 $path $relativePath
    "$hash *$relativePath"
}

$manifest = Join-Path $PSScriptRoot "SBOM-Tool-SHA256.txt"
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllLines($manifest, $lines, $utf8NoBom)
Write-Host "Checksum manifest written: $manifest" -ForegroundColor Green