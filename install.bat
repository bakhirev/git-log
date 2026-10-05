@echo off
setlocal
title Install Assayo report

set "SRC=%~dp0"
set "DEST=%LOCALAPPDATA%\Assayo"

if not exist "%SRC%build\" (
    echo build folder was not found next to install.bat
    pause
    exit /b 1
)

echo Installing to %DEST%
if not exist "%DEST%" mkdir "%DEST%"

robocopy "%SRC%build" "%DEST%\build" /E /R:1 /W:1 /NFL /NDL /NJH /NJS /nc /ns /np
set "RC=%ERRORLEVEL%"
if %RC% GEQ 8 (
    echo Could not copy the report template. robocopy exit %RC%
    pause
    exit /b 1
)

copy /Y "%SRC%create-report.ps1" "%DEST%\create-report.ps1" >nul
copy /Y "%SRC%create-report.bat" "%DEST%\create-report.bat" >nul
if errorlevel 1 (
    echo Could not copy scripts.
    pause
    exit /b 1
)

reg add "HKCU\Software\Classes\Directory\shell\AssayoReport" /ve /d "Git HTML-report Assayo" /f >nul
reg add "HKCU\Software\Classes\Directory\shell\AssayoReport" /v Icon /t REG_SZ /d "%SystemRoot%\System32\imageres.dll,-5340" /f >nul
reg add "HKCU\Software\Classes\Directory\shell\AssayoReport\command" /ve /d "\"%DEST%\create-report.bat\" \"%%1\"" /f >nul

reg add "HKCU\Software\Classes\Directory\Background\shell\AssayoReport" /ve /d "Git HTML-report Assayo" /f >nul
reg add "HKCU\Software\Classes\Directory\Background\shell\AssayoReport" /v Icon /t REG_SZ /d "%SystemRoot%\System32\imageres.dll,-5340" /f >nul
reg add "HKCU\Software\Classes\Directory\Background\shell\AssayoReport\command" /ve /d "\"%DEST%\create-report.bat\" \"%%V\"" /f >nul

echo.
echo Updating build from https://github.com/bakhirev/assayo ...
set "CLONE=%TEMP%\assayo-clone"
set "GIT_TERMINAL_PROMPT=0"
call :remove_clone

where git >nul 2>&1
if errorlevel 1 (
    echo Git was not found. The bundled build was kept.
    goto :done
)

git clone --depth 1 https://github.com/bakhirev/assayo "%CLONE%"
if errorlevel 1 (
    echo Could not clone the repository. The bundled build was kept.
    goto :cleanup
)

if not exist "%CLONE%\build\" (
    echo The repository has no build folder. The bundled build was kept.
    goto :cleanup
)

robocopy "%CLONE%\build" "%DEST%\build" /MIR /R:1 /W:1 /NFL /NDL /NJH /NJS /nc /ns /np
set "RC=%ERRORLEVEL%"
if %RC% GEQ 8 (
    echo Could not replace the build folder. robocopy exit %RC%
    goto :cleanup
)

echo Build folder updated.

:cleanup
call :remove_clone

:done
echo.
echo Installed. Right-click a folder, or empty space inside it, and choose "Git HTML-report Assayo".
echo The folder must contain .git. The report is written to assayo\log.txt.
echo To remove the menu item, run uninstall.bat.
echo.
pause
exit /b 0

:remove_clone
if not exist "%CLONE%\" exit /b 0
attrib -R "%CLONE%\*" /S /D >nul 2>&1
rd /s /q "%CLONE%"
exit /b 0
