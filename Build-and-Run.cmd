@echo off
setlocal
cd /d "%~dp0"
where pwsh.exe >nul 2>&1
if errorlevel 1 (
  echo PowerShell 7 is required. Install it from https://github.com/PowerShell/PowerShell/releases
  pause
  exit /b 1
)
pwsh.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Build-SuiteDock.ps1" -Run
set "BuildExit=%ERRORLEVEL%"
echo.
if not "%BuildExit%"=="0" echo Build failed. Read build-logs\SuiteDock_ERROR_COMPACT.txt.
pause
exit /b %BuildExit%
