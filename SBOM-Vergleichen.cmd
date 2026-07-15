@echo off
chcp 65001 >nul 2>&1
title SCHUNK SBOM Vergleich -/- SBOM Compare

echo.
echo   ============================================================
echo    SCHUNK SBOM Vergleich -/- SBOM Compare
echo    3-Spalten-Diff (Quelle 1 ^| Ampel ^| Quelle 2)
echo   ============================================================
echo.
echo   Waehle zwei CycloneDX-Dateien (.cdx.json)...
echo   Select two CycloneDX files (.cdx.json)...
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Compare-WindowsSBOM.ps1" -OutputDir "%~dp0sbom-output"

echo.
echo   [DE] Druecke eine beliebige Taste zum Schliessen...
echo   [EN] Press any key to close...
pause >nul
