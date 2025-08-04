@echo off
REM AHK Tools v2.1.0 Portable Launcher
REM This launcher runs the portable version of AHK Tools

title AHK Tools v2.1.0 Portable

echo ========================================
echo    AHK Tools for Power Users v2.1.0
echo           Portable Version
echo ========================================
echo.
echo Starting AHK Tools...
echo.

REM Check if AutoHotkey executable exists
if not exist "%~dp0AutoHotkey64.exe" (
    echo ERROR: AutoHotkey64.exe not found in portable directory.
    echo.
    echo This portable version should include AutoHotkey64.exe.
    echo Please re-download the portable package.
    echo.
    pause
    exit /b 1
)

REM Check if the script file exists
if not exist "%~dp0src\AHK-Tools-Plugins.ahk" (
    echo ERROR: AHK script file not found.
    echo.
    echo This portable version should include the src folder.
    echo Please re-download the portable package.
    echo.
    pause
    exit /b 1
)

echo AutoHotkey found. Starting script...
echo.

REM Run the script using the portable AutoHotkey
"%~dp0AutoHotkey64.exe" "%~dp0src\AHK-Tools-Plugins.ahk"

echo.
echo AHK Tools has been closed.
echo.
pause
