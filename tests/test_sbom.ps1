$RepoRoot = if ($env:GITHUB_WORKSPACE) {
    $env:GITHUB_WORKSPACE
} elseif ($PSScriptRoot) {
    (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
} else {
    (Get-Location).Path
}

Describe 'Script inventory' {
    It 'contains main PowerShell scripts' {
        @('Get-WindowsSBOM.ps1', 'Compare-WindowsSBOM.ps1') | ForEach-Object {
            Test-Path (Join-Path $RepoRoot $_) | Should Be $true
        }
    }

    It 'contains launcher files' {
        @('SBOM-Erstellen.cmd', 'SBOM-Vergleichen.cmd', 'SBOM-Vergleichen.html') | ForEach-Object {
            Test-Path (Join-Path $RepoRoot $_) | Should Be $true
        }
    }
}

Describe 'PowerShell syntax' {
    It 'Get-WindowsSBOM.ps1 parses without errors' {
        $path = Join-Path $RepoRoot 'Get-WindowsSBOM.ps1'
        $tokens = $null
        $errors = $null
        [void][System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors)
        @($errors).Count | Should Be 0
    }

    It 'Compare-WindowsSBOM.ps1 parses without errors' {
        $path = Join-Path $RepoRoot 'Compare-WindowsSBOM.ps1'
        $tokens = $null
        $errors = $null
        [void][System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors)
        @($errors).Count | Should Be 0
    }
}

Describe 'SBOM compare report' {
    It 'generates HTML compare report from fixtures' {
        $baseline = Join-Path $RepoRoot 'tests\fixtures\baseline.cdx.json'
        $current  = Join-Path $RepoRoot 'tests\fixtures\current.cdx.json'
        $approved = Join-Path $RepoRoot 'tests\fixtures\approved-differences.json'
        $outDir   = Join-Path $RepoRoot 'tests\test-results'
        if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }

        & (Join-Path $RepoRoot 'Compare-WindowsSBOM.ps1') `
            -Source1 $baseline `
            -Source2 $current `
            -ApprovedFile $approved `
            -OutputDir $outDir `
            -NoBrowser

        $report = Get-ChildItem $outDir -Filter 'sbom-compare-*.html' |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1
        ($null -ne $report) | Should Be $true
        $content = Get-Content $report.FullName -Raw
        ($content -match '__PRELOADED__') | Should Be $true
        ($content -match '7-Zip 24.08') | Should Be $true
        ($content -match 'New Application') | Should Be $true
    }
}

Describe 'CycloneDX fixtures' {
    It 'baseline fixture is valid CycloneDX 1.6 JSON' {
        $json = Get-Content (Join-Path $RepoRoot 'tests\fixtures\baseline.cdx.json') -Raw | ConvertFrom-Json
        $json.bomFormat | Should Be 'CycloneDX'
        $json.specVersion | Should Be '1.6'
        (@($json.components).Count -gt 0) | Should Be $true
    }
}
