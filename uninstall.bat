@echo off
setlocal
title Uninstall Assayo report

reg delete "HKCU\Software\Classes\Directory\shell\AssayoReport" /f >nul 2>&1
reg delete "HKCU\Software\Classes\Directory\Background\shell\AssayoReport" /f >nul 2>&1

set "DEST=%LOCALAPPDATA%\Assayo"
if exist "%DEST%" rmdir /s /q "%DEST%"

echo Assayo report was removed from the Explorer menu.
echo.
pause
exit /b 0
