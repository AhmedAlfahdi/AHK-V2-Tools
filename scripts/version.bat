@echo off
REM AHK Tools Version Control Batch Script
REM Provides easy access to version control operations

setlocal enabledelayedexpansion

REM Configuration
set "PROJECT_ROOT=%~dp0.."
set "MAIN_SCRIPT=%PROJECT_ROOT%\src\AHK-Tools-Plugins.ahk"
set "VERSION_FILE=%PROJECT_ROOT%\VERSION.md"
set "CHANGELOG_FILE=%PROJECT_ROOT%\CHANGELOG.md"
set "UPDATE_SCRIPT=%PROJECT_ROOT%\scripts\update_version.ahk"
set "POWERSHELL_SCRIPT=%PROJECT_ROOT%\scripts\version_control.ps1"

REM Check if AutoHotkey v2 is available
where "C:\Program Files\AutoHotkey\v2\AutoHotkey.exe" >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: AutoHotkey v2 is not installed or not found in default location
    echo Please install AutoHotkey v2 from https://www.autohotkey.com/
    pause
    exit /b 1
)

REM Check if PowerShell is available
powershell -Command "Write-Host 'PowerShell available'" >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: PowerShell is not available
    pause
    exit /b 1
)

REM Function to show help
:show_help
echo.
echo === AHK Tools Version Control ===
echo.
echo Usage: version.bat [command] [parameters]
echo.
echo Commands:
echo   info                    - Show current version information
echo   suggest [type]          - Suggest next version (patch/minor/major)
echo   update [version]        - Update version using GUI
echo   tag [version]           - Create git tag for version
echo   checklist [version]     - Show release checklist
echo   status                  - Show git status and recent tags
echo   help                    - Show this help message
echo.
echo Examples:
echo   version.bat info
echo   version.bat suggest patch
echo   version.bat update
echo   version.bat tag 2.1.1
echo   version.bat checklist 2.1.1
echo.
goto :eof

REM Function to get current version
:get_current_version
for /f "tokens=2 delims=:" %%i in ('findstr /C:"version:" "%MAIN_SCRIPT%"') do (
    set "version=%%i"
    set "version=!version: =!"
    set "version=!version:"=!"
    goto :found_version
)
set "version=Unknown"
:found_version
goto :eof

REM Function to suggest next version
:suggest_version
set "type=%2"
if "%type%"=="" set "type=patch"
call :get_current_version

for /f "tokens=1,2,3 delims=." %%a in ("!version!") do (
    set "major=%%a"
    set "minor=%%b"
    set "patch=%%c"
)

if "%type%"=="major" (
    set /a "new_major=!major!+1"
    set "suggested=!new_major!.0.0"
) else if "%type%"=="minor" (
    set /a "new_minor=!minor!+1"
    set "suggested=!major!.!new_minor!.0"
) else (
    set /a "new_patch=!patch!+1"
    set "suggested=!major!.!minor!.!new_patch!"
)

echo Current Version: !version!
echo Suggested Version (%type%): !suggested!
goto :eof

REM Function to create git tag
:create_tag
set "version=%2"
if "%version%"=="" (
    echo Error: Version parameter is required for tag command
    echo Usage: version.bat tag 2.1.1
    pause
    exit /b 1
)

echo Creating git tag AHK-%version%...
git tag "AHK-%version%"
if %errorlevel% neq 0 (
    echo Error: Failed to create git tag
    pause
    exit /b 1
)

echo Pushing tag to remote...
git push origin "AHK-%version%"
if %errorlevel% neq 0 (
    echo Error: Failed to push git tag
    pause
    exit /b 1
)

echo Git tag AHK-%version% created and pushed successfully!
goto :eof

REM Function to show release checklist
:show_checklist
set "version=%2"
if "%version%"=="" (
    call :suggest_version
    set "version=!suggested!"
    echo No version specified, using suggested version: !version!
)

echo.
echo === Release Checklist for v%version% ===
echo.
echo Before Release:
echo □ Update version numbers in all relevant files
echo □ Test all functionality
echo □ Update documentation
echo □ Create git tag
echo □ Push to remote repository
echo □ Update VERSION.md
echo □ Update CHANGELOG.md
echo.
echo After Release:
echo □ Create GitHub release
echo □ Update download links
echo □ Notify users
echo.
goto :eof

REM Function to show version info
:show_info
call :get_current_version
echo === AHK Tools Version Information ===
echo Current Version: !version!
echo Main Script: %MAIN_SCRIPT%
echo Version File: %VERSION_FILE%
echo Changelog: %CHANGELOG_FILE%
echo.
echo === Git Status ===
git status --porcelain
echo.
echo === Recent Tags ===
git tag --sort=-version:refname | findstr /v "^$" | head -5
goto :eof

REM Function to show git status
:show_status
echo === Git Status ===
git status
echo.
echo === Recent Tags ===
git tag --sort=-version:refname | findstr /v "^$" | head -10
goto :eof

REM Main script logic
if "%1"=="" goto :show_help
if "%1"=="help" goto :show_help
if "%1"=="info" goto :show_info
if "%1"=="suggest" goto :suggest_version
if "%1"=="update" (
    echo Starting version update GUI...
    "C:\Program Files\AutoHotkey\v2\AutoHotkey.exe" "%UPDATE_SCRIPT%"
    goto :eof
)
if "%1"=="tag" goto :create_tag
if "%1"=="checklist" goto :show_checklist
if "%1"=="status" goto :show_status

REM If command not recognized, try PowerShell script
echo Command not recognized, trying PowerShell script...
powershell -ExecutionPolicy Bypass -File "%POWERSHELL_SCRIPT%" %*
if %errorlevel% neq 0 (
    echo Error: Unknown command '%1'
    echo Use 'version.bat help' to see available options
    pause
    exit /b 1
)

goto :eof 