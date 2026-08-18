@echo off
chcp 65001 >nul 2>&1
title SCHUNK SBOM Tool - Integritaetspruefung / Integrity check

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Test-SBOM-ToolIntegrity.ps1"
set "RESULT=%ERRORLEVEL%"
echo.
if not "%RESULT%"=="0" (
  echo   FEHLER: Tooldateien wurden veraendert oder fehlen. -/- ERROR: Tool files changed or are missing.
) else (
  echo   Integritaet bestaetigt. -/- Integrity verified.
)
echo.
pause
exit /b %RESULT%