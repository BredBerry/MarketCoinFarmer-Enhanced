@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0build.ps1" %*
set "rc=%errorlevel%"
echo.
if not "%rc%"=="0" (echo Build stopped. Read the error above.) else (echo Build completed. Check the new desktop folder.)
pause
exit /b %rc%
