@echo off
chcp 65001 >nul 2>&1
title SCHUNK Windows SBOM Generator - CRA konform -/- compliant

echo.
echo   ============================================================
echo    SCHUNK Windows SBOM Generator v3.0
echo    CRA / BSI TR-03183-2 v2.1.0 konform -/- compliant
echo   ============================================================
echo.
echo   Starte SBOM-Erfassung mit ALLEN Quellen... -/- Starting SBOM scan with ALL sources...
echo   (OS, Updates, Apps, Store, Features, Treiber) -/- (OS, updates, apps, store, features, drivers)
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Get-WindowsSBOM.ps1" -OutputDir "%~dp0sbom-output" -All

echo.
echo   Oeffne HTML-Report im Browser... -/- Opening HTML report in browser...
for /f "delims=" %%f in ('dir /b /o-d "%~dp0sbom-output\*.html" 2^>nul') do (
    start "" "%~dp0sbom-output\%%f"
    goto :done
)
:done
echo.
echo   Druecke eine beliebige Taste zum Schliessen... -/- Press any key to close...
pause >nul
