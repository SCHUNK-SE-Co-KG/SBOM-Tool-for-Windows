BeforeAll {
    if ($env:GITHUB_WORKSPACE) {
        $script:RepoRoot = $env:GITHUB_WORKSPACE
    }
    elseif ($PSScriptRoot) {
        $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    }
    else {
        $script:RepoRoot = (Get-Location).Path
    }
    Write-Host "RepoRoot: $script:RepoRoot"
}

Describe 'Script inventory' {
    It 'contains main PowerShell scripts' {
        @('Get-WindowsSBOM.ps1', 'Compare-WindowsSBOM.ps1') | ForEach-Object {
            Test-Path (Join-Path $script:RepoRoot $_) | Should -Be $true
        }
    }

    It 'contains launcher files' {
        @('SBOM-Erstellen.cmd', 'SBOM-Vergleichen.cmd', 'SBOM-Vergleichen.html') | ForEach-Object {
            Test-Path (Join-Path $script:RepoRoot $_) | Should -Be $true
        }
    }
}

Describe 'PowerShell syntax' {
    It 'Get-WindowsSBOM.ps1 parses without errors' {
        $path = Join-Path $script:RepoRoot 'Get-WindowsSBOM.ps1'
        $tokens = $null
        $errors = $null
        [void][System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors)
        @($errors).Count | Should -Be 0
    }

    It 'Compare-WindowsSBOM.ps1 parses without errors' {
        $path = Join-Path $script:RepoRoot 'Compare-WindowsSBOM.ps1'
        $tokens = $null
        $errors = $null
        [void][System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors)
        @($errors).Count | Should -Be 0
    }
}

Describe 'SBOM compare report' {
    It 'generates HTML compare report from fixtures' {
        $baseline = Join-Path $script:RepoRoot 'tests\fixtures\baseline.cdx.json'
        $current  = Join-Path $script:RepoRoot 'tests\fixtures\current.cdx.json'
        $approved = Join-Path $script:RepoRoot 'tests\fixtures\approved-differences.json'
        $outDir   = Join-Path $script:RepoRoot 'tests\test-results'
        if (-not (Test-Path $outDir)) {
            New-Item -ItemType Directory -Path $outDir -Force | Out-Null
        }

        & (Join-Path $script:RepoRoot 'Compare-WindowsSBOM.ps1') `
            -Source1 $baseline `
            -Source2 $current `
            -ApprovedFile $approved `
            -OutputDir $outDir `
            -NoBrowser

        $report = Get-ChildItem $outDir -Filter 'sbom-compare-*.html' |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1
        $report | Should -Not -BeNullOrEmpty
        $content = Get-Content $report.FullName -Raw
        $content | Should -Match '__PRELOADED__'
        $content | Should -Match '7-Zip 24.08'
        $content | Should -Match 'New Application'
    }
}

Describe 'CycloneDX fixtures' {
    It 'baseline fixture is valid CycloneDX 1.6 JSON' {
        $json = Get-Content (Join-Path $script:RepoRoot 'tests\fixtures\baseline.cdx.json') -Raw | ConvertFrom-Json
        $json.bomFormat | Should -Be 'CycloneDX'
        $json.specVersion | Should -Be '1.6'
        @($json.components).Count | Should -BeGreaterThan 0
    }
}
