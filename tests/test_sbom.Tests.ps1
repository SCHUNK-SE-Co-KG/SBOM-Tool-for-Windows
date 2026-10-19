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
        @('_internal/generator/Get-WindowsSBOM.ps1', '_internal/cli/Compare-WindowsSBOM.ps1') | ForEach-Object {
            Test-Path (Join-Path $script:RepoRoot $_) | Should -Be $true
        }
    }

    It 'contains the main browser entry point and optional launcher' {
        @('SBOM-Compare.html', 'SBOM-Create.cmd') | ForEach-Object {
            Test-Path (Join-Path $script:RepoRoot $_) | Should -Be $true
        }
    }

    It 'contains inactive customer branding examples' {
        @('Customer-Info.example.txt', 'Customer-Logo.example.svg') | ForEach-Object {
            Test-Path (Join-Path $script:RepoRoot $_) | Should -Be $true
        }
    }

    It 'opens only the report produced by a successful scan' {
        $launcher = Get-Content (Join-Path $script:RepoRoot 'SBOM-Create.cmd') -Raw
        $launcher | Should -Match '-OpenReport'
        $launcher | Should -Match 'if errorlevel 1 goto :scan_error'
        $launcher | Should -Not -Match 'dir /b /o-d'
        $launcher | Should -Match 'Get-WindowsSBOM\.ps1'
    }
}

Describe 'Approved differences template' {
    It 'ships without active approval rules' {
        $path = Join-Path $script:RepoRoot 'SBOM-Approved-Differences.json'
        $approved = Get-Content $path -Raw | ConvertFrom-Json
        $approved.version | Should -Be 1
        $approved.documentId | Should -Match '^urn:uuid:'
        $approved.revision | Should -Be 0
        @($approved.rules).Count | Should -Be 0
    }
}

Describe 'PowerShell syntax' {
    It 'Get-WindowsSBOM.ps1 parses without errors' {
        $path = Join-Path $script:RepoRoot '_internal/generator/Get-WindowsSBOM.ps1'
        $tokens = $null
        $errors = $null
        [void][System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors)
        @($errors).Count | Should -Be 0
    }

    It 'Compare-WindowsSBOM.ps1 parses without errors' {
        $path = Join-Path $script:RepoRoot '_internal/cli/Compare-WindowsSBOM.ps1'
        $tokens = $null
        $errors = $null
        [void][System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors)
        @($errors).Count | Should -Be 0
    }
}

Describe 'Portable customer branding' {
    BeforeAll {
        $script:GeneratorSource = Get-Content (Join-Path $script:RepoRoot '_internal/generator/Get-WindowsSBOM.ps1') -Raw
    }

    It 'loads optional customer files and embeds the logo' {
        $script:GeneratorSource | Should -Match 'Customer-Info\.txt'
        $script:GeneratorSource | Should -Match 'Customer-Logo\.\$_'
        $script:GeneratorSource | Should -Match 'data:\$mimeType;base64'
    }

    It 'does not hard-code SCHUNK customer address or report logo' {
        $script:GeneratorSource | Should -Not -Match 'Am Tannwald 17'
        $script:GeneratorSource | Should -Not -Match '\.\./assets/logos/SCHUNK'
        $script:GeneratorSource | Should -Match 'Tool developed by'
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

        & (Join-Path $script:RepoRoot '_internal/cli/Compare-WindowsSBOM.ps1') `
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

    It 'escapes script terminators embedded in SBOM data' {
        $baselineData = Get-Content (Join-Path $script:RepoRoot 'tests\fixtures\baseline.cdx.json') -Raw | ConvertFrom-Json
        $baselineData.components[0].name = '</script><script>alert(1)</script>'
        $baseline = Join-Path $TestDrive 'baseline-malicious.cdx.json'
        $baselineData | ConvertTo-Json -Depth 30 | Set-Content $baseline -Encoding UTF8
        $current = Join-Path $script:RepoRoot 'tests\fixtures\current.cdx.json'
        $approved = Join-Path $script:RepoRoot 'tests\fixtures\approved-differences.json'

        & (Join-Path $script:RepoRoot '_internal/cli/Compare-WindowsSBOM.ps1') `
            -Source1 $baseline `
            -Source2 $current `
            -ApprovedFile $approved `
            -OutputDir $TestDrive `
            -NoBrowser

        $report = Get-ChildItem $TestDrive -Filter 'sbom-compare-*.html' | Select-Object -First 1
        $content = Get-Content $report.FullName -Raw
        $content | Should -Not -Match '</script><script>alert'
        $content | Should -Match '\\u003c/script\\u003e'
    }

    It 'rejects files that are not CycloneDX SBOMs' {
        $invalid = Join-Path $TestDrive 'invalid.json'
        '{}' | Set-Content $invalid -Encoding UTF8
        $current = Join-Path $script:RepoRoot 'tests\fixtures\current.cdx.json'

        {
            & (Join-Path $script:RepoRoot '_internal/cli/Compare-WindowsSBOM.ps1') `
                -Source1 $invalid `
                -Source2 $current `
                -OutputDir $TestDrive `
                -NoBrowser
        } | Should -Throw '*CycloneDX*'
    }
}

Describe 'SBOM compare browser logic' {
    It 'passes identity and three-way merge self-tests in Edge' {
        $edge = @(
            (Join-Path ${env:ProgramFiles(x86)} 'Microsoft\Edge\Application\msedge.exe'),
            (Join-Path $env:ProgramFiles 'Microsoft\Edge\Application\msedge.exe')
        ) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
        $edge | Should -Not -BeNullOrEmpty

        $htmlPath = (Resolve-Path (Join-Path $script:RepoRoot 'SBOM-Compare.html')).Path
        $url = ([Uri]$htmlPath).AbsoluteUri + '#selftest'
        $runId = [Guid]::NewGuid().ToString('N')
        $profile = Join-Path $env:TEMP "edge-sbom-test-$runId"
        $stdout = Join-Path $env:TEMP "edge-sbom-test-$runId.out"
        $stderr = Join-Path $env:TEMP "edge-sbom-test-$runId.err"
        $process = Start-Process -FilePath $edge -ArgumentList @(
            '--headless=new', '--disable-gpu', '--no-sandbox', '--no-first-run',
            "--user-data-dir=$profile", '--dump-dom', $url
        ) -Wait -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
        $process.ExitCode | Should -Be 0
        (Get-Content $stdout -Raw) | Should -Match 'SELFTEST PASS'
        Remove-Item $stdout, $stderr -Force -ErrorAction SilentlyContinue
        Remove-Item $profile -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'Offline tool integrity' {
    It 'accepts the trusted runtime files' {
        { & (Join-Path $script:RepoRoot '_internal/integrity/Test-SBOM-ToolIntegrity.ps1') } | Should -Not -Throw
    }

    It 'rejects a modified runtime file' {
        $copyRoot = Join-Path $TestDrive 'tampered-tool'
        New-Item $copyRoot -ItemType Directory | Out-Null
        $manifest = Join-Path $script:RepoRoot '_internal/integrity/SBOM-Tool-SHA256.txt'
        $copyManifest = Join-Path $copyRoot '_internal/integrity/SBOM-Tool-SHA256.txt'
        New-Item (Split-Path $copyManifest) -ItemType Directory -Force | Out-Null
        Copy-Item $manifest $copyManifest
        foreach ($line in Get-Content $manifest) {
            if ($line -notmatch '^[0-9a-fA-F]{64} \*(.+)$') { continue }
            $relativePath = $Matches[1]
            $source = Join-Path $script:RepoRoot ($relativePath -replace '/', '\')
            $target = Join-Path $copyRoot ($relativePath -replace '/', '\')
            New-Item (Split-Path $target) -ItemType Directory -Force | Out-Null
            Copy-Item $source $target
        }
        Add-Content (Join-Path $copyRoot 'SBOM-Compare.html') '<!-- tampered -->'
        { & (Join-Path $copyRoot '_internal/integrity/Test-SBOM-ToolIntegrity.ps1') } | Should -Throw '*integrity check failed*'
    }

    It 'excludes mutable customer branding from the trusted manifest' {
        $manifest = Get-Content (Join-Path $script:RepoRoot '_internal/integrity/SBOM-Tool-SHA256.txt') -Raw
        $manifest | Should -Not -Match '\*Customer-Info\.txt'
        $manifest | Should -Not -Match '\*Customer-Logo\.(svg|png|jpg|jpeg)'
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

Describe 'CycloneDX license schema placement' {
    BeforeAll {
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            (Join-Path $script:RepoRoot '_internal\generator\Get-WindowsSBOM.ps1'), [ref]$null, [ref]$null)
        $fn = $ast.Find({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'New-CdxLicense' }, $true)
        . ([scriptblock]::Create($fn.Extent.Text))
    }

    It 'puts acknowledgement inside license for LicenseRef names' {
        $entry = New-CdxLicense -SpdxId 'LicenseRef-Proprietary-Microsoft'
        $entry.ContainsKey('acknowledgement') | Should -Be $false
        $entry.license.name | Should -Be 'LicenseRef-Proprietary-Microsoft'
        $entry.license.acknowledgement | Should -Be 'concluded'
    }

    It 'keeps acknowledgement beside expression for SPDX expressions' {
        $entry = New-CdxLicense -SpdxId 'MIT' -Acknowledgement 'declared'
        $entry.expression | Should -Be 'MIT'
        $entry.acknowledgement | Should -Be 'declared'
    }
}
