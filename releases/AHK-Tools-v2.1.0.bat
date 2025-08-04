@echo off
REM AHK Tools v2.1.0 Launcher
REM This launcher runs the AHK script using AutoHotkey v2

title AHK Tools v2.1.0

echo ========================================
echo    AHK Tools for Power Users v2.1.0
echo ========================================
echo.
echo Starting AHK Tools...
echo.

REM Check if AutoHotkey v2 is installed
if not exist "C:\Program Files\AutoHotkey\v2\AutoHotkey.exe" (
    echo ERROR: AutoHotkey v2 is not installed.
    echo.
    echo Please install AutoHotkey v2 from:
    echo https://www.autohotkey.com/
    echo.
    echo After installation, run this launcher again.
    echo.
    pause
    exit /b 1
)

REM Check if the script file exists
if not exist "%~dp0..\src\AHK-Tools-Plugins.ahk" (
    echo ERROR: AHK script file not found.
    echo.
    echo Make sure this launcher is in the releases directory
    echo and the src folder is in the parent directory.
    echo.
    pause
    exit /b 1
)

echo AutoHotkey v2 found. Starting script...
echo.

REM Run the script
"C:\Program Files\AutoHotkey\v2\AutoHotkey.exe" "%~dp0..\src\AHK-Tools-Plugins.ahk"

echo.
echo AHK Tools has been closed.
echo.
pause 