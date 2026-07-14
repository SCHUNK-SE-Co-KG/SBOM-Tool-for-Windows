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

echo [1/3] Python tests...
python -m pip install -q -r tests\requirements.txt -r security\requirements.txt
python -m pytest tests\test_security.py -q
if errorlevel 1 exit /b 1

echo.
echo [2/3] Pester tests (PowerShell)...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Pester -Script 'tests\test_sbom.ps1' -PassThru | ForEach-Object { if ($_.FailedCount -gt 0) { exit 1 } }"
if errorlevel 1 exit /b 1

echo.
echo [3/3] CVE scanner (optional)...
python security\cve_scanner.py >nul 2>&1
echo   CVE scan finished (exit code ignored for local dev)

echo.
echo   All tests passed.
exit /b 0
