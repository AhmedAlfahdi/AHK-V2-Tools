# AHK Tools Portable Creator
# This script creates a portable version of AHK Tools

param(
    [string]$Version = "2.1.0",
    [string]$OutputDir = "releases"
)

Write-Host "AHK Tools Portable Creator" -ForegroundColor Green
Write-Host "Version: $Version" -ForegroundColor Yellow

# Create portable directory
$PortableDir = "$OutputDir\AHK-Tools-v$Version-Portable"
$PortableDir = $PortableDir.Replace(" ", "")

if (Test-Path $PortableDir) {
    Remove-Item $PortableDir -Recurse -Force
}

New-Item -ItemType Directory -Path $PortableDir -Force | Out-Null
Write-Host "Created portable directory: $PortableDir" -ForegroundColor Green

# Copy AutoHotkey v2 executable
$AhkSource = "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
$AhkDest = "$PortableDir\AutoHotkey64.exe"

if (Test-Path $AhkSource) {
    Copy-Item $AhkSource $AhkDest -Force
    Write-Host "Copied AutoHotkey64.exe" -ForegroundColor Green
} else {
    Write-Host "Warning: AutoHotkey64.exe not found at $AhkSource" -ForegroundColor Yellow
}

# Copy script files
$ScriptSource = "src"
$ScriptDest = "$PortableDir\src"

if (Test-Path $ScriptSource) {
    Copy-Item $ScriptSource $ScriptDest -Recurse -Force
    Write-Host "Copied script files" -ForegroundColor Green
} else {
    Write-Host "Error: Script source not found: $ScriptSource" -ForegroundColor Red
    exit 1
}

# Create launcher script
$LauncherContent = @"
@echo off
REM AHK Tools v$Version Portable Launcher
REM This launcher runs the portable version of AHK Tools

title AHK Tools v$Version Portable

echo ========================================
echo    AHK Tools for Power Users v$Version
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
"@

$LauncherFile = "$PortableDir\AHK-Tools-Portable.bat"
$LauncherContent | Out-File -FilePath $LauncherFile -Encoding ASCII
Write-Host "Created portable launcher: $LauncherFile" -ForegroundColor Green

# Create README for portable version
$PortableReadme = @"
# AHK Tools v$Version - Portable Version

## What's Included

This portable version includes:
- **AutoHotkey64.exe** - AutoHotkey v2 runtime (portable)
- **src/** - All script files and plugins
- **AHK-Tools-Portable.bat** - Launcher script
- **README.md** - This file

## Usage

1. **Extract** all files to a folder of your choice
2. **Run** `AHK-Tools-Portable.bat` to start the application
3. **No installation required** - everything is self-contained

## Features

### Hotkeys
- **Alt + B** - LibGen Book Download
- **Alt + Y** - YouTube Search
- **Alt + T** - Run Selected Command
- **Win + Delete** - Suspend/Resume Script
- **Alt + C** - Currency Converter
- **Alt + U** - Unit Converter
- **Alt + A** - Auto Completion

### Plugins
- Currency Converter (v3.0.0)
- Unit Converter (v1.0.0)
- Auto Completion (v1.0.0)

## Advantages of Portable Version

- **No installation required** - just extract and run
- **Self-contained** - includes AutoHotkey runtime
- **Portable** - can be run from USB drive or any location
- **No system changes** - doesn't modify Windows registry
- **Easy to update** - just replace the folder

## Troubleshooting

1. **"AutoHotkey64.exe not found"**
   - Make sure all files were extracted properly
   - Re-download the portable package

2. **"AHK script file not found"**
   - Ensure the src folder is in the same directory as the launcher
   - Check that all files were extracted

3. **Hotkeys not working**
   - Check if the script is running (tray icon should be visible)
   - Try suspending and resuming the script (Win+Delete)

## System Requirements

- **Windows 10/11** (64-bit recommended)
- **No additional software required** - AutoHotkey is included

## Version

This is AHK Tools v$Version Portable Edition.

## Support

For issues, feature requests, or questions:
- GitHub: https://github.com/ahmedalfahdi/AHK-V2-Tools
- Report issues on the GitHub repository

## License

This project is open source and available under the MIT License.
"@

$PortableReadmeFile = "$PortableDir\README.md"
$PortableReadme | Out-File -FilePath $PortableReadmeFile -Encoding UTF8
Write-Host "Created portable README" -ForegroundColor Green

# Create ZIP file
$ZipFile = "$OutputDir\AHK-Tools-v$Version-Portable.zip"
if (Test-Path $ZipFile) {
    Remove-Item $ZipFile -Force
}

Write-Host "Creating ZIP archive..." -ForegroundColor Cyan
Compress-Archive -Path $PortableDir -DestinationPath $ZipFile -Force
Write-Host "Created ZIP archive: $ZipFile" -ForegroundColor Green

# Get file sizes
$ZipSize = (Get-Item $ZipFile).Length
$ZipSizeMB = [math]::Round($ZipSize / 1MB, 2)
Write-Host "ZIP file size: $ZipSizeMB MB" -ForegroundColor Yellow

Write-Host "`nPortable version created successfully!" -ForegroundColor Green
Write-Host "Location: $ZipFile" -ForegroundColor Cyan 