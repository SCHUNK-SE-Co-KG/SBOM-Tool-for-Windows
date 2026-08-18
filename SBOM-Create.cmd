@echo off
chcp 65001 >nul 2>&1
title SCHUNK Windows SBOM Generator - CRA / BSI ausgerichtet -/- aligned

set "TOOLROOT=%~dp0"

echo.
set "TOOLVER=1.1.0"
if exist "%TOOLROOT%\VERSION" for /f "usebackq delims=" %%V in ("%TOOLROOT%\VERSION") do set "TOOLVER=%%V"
echo   ============================================================
echo    SCHUNK Windows SBOM Generator v%TOOLVER%
echo    CRA / BSI TR-03183-2 v2.1.0 ausgerichtet -/- aligned
echo   ============================================================
echo.
echo   Starte SBOM-Erfassung mit ALLEN Quellen... -/- Starting SBOM scan with ALL sources...
echo   (OS, Updates, Apps, Store, Features, Treiber) -/- (OS, updates, apps, store, features, drivers)
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%TOOLROOT%_internal\generator\Get-WindowsSBOM.ps1" -OutputDir "%TOOLROOT%sbom-output" -All -OpenReport
if errorlevel 1 goto :scan_error

echo.
echo   SBOM erfolgreich erstellt. -/- SBOM created successfully.
echo.
echo   Druecke eine beliebige Taste zum Schliessen... -/- Press any key to close...
pause >nul
exit /b 0

:scan_error
echo.
echo   FEHLER: SBOM-Erfassung fehlgeschlagen. Es wird kein alter Report geoeffnet.
echo   ERROR: SBOM scan failed. No previous report will be opened.
echo.
echo   Druecke eine beliebige Taste zum Schliessen... -/- Press any key to close...
pause >nul
exit /b 1
