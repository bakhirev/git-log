@echo off
setlocal
title Create Assayo report
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0create-report.ps1" "%~1"
exit /b %ERRORLEVEL%
