@echo off
chcp 65001 >nul 2>&1
setlocal
cd /d "%~dp0.."

echo.
echo   SBOM Tool - Test Suite
echo   ======================
echo.

where python >nul 2>&1
if errorlevel 1 (
  echo Python nicht gefunden / Python not found
  exit /b 1
)

echo [1/2] Python tests...
python -m pip install -q -r tests\requirements.txt -r security\requirements.txt
python -m pytest tests\test_security.py -q
if errorlevel 1 exit /b 1

echo.
echo [2/2] Pester tests (PowerShell 5.1)...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12; " ^
  "Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser | Out-Null; " ^
  "Set-PSRepository PSGallery -InstallationPolicy Trusted; " ^
  "Install-Module Pester -RequiredVersion 5.7.1 -Force -SkipPublisherCheck -Scope CurrentUser; " ^
  "Import-Module Pester -RequiredVersion 5.7.1 -Force; " ^
  "$c = New-PesterConfiguration; $c.Run.Path = 'tests/test_sbom.Tests.ps1'; $c.Run.PassThru = $true; " ^
  "$r = Invoke-Pester -Configuration $c; if ($r.FailedCount -gt 0) { exit 1 }"
if errorlevel 1 exit /b 1

echo.
echo   All tests passed.
exit /b 0
