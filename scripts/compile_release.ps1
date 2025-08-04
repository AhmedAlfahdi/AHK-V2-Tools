# AHK Tools Release Compilation Script
# This script compiles the AHK script to an executable

param(
    [string]$Version = "2.1.0",
    [string]$OutputDir = "releases"
)

Write-Host "AHK Tools Release Compiler" -ForegroundColor Green
Write-Host "Version: $Version" -ForegroundColor Yellow

# Check if source file exists
$SourceFile = "src\AHK-Tools-Plugins.ahk"
if (-not (Test-Path $SourceFile)) {
    Write-Host "Error: Source file not found: $SourceFile" -ForegroundColor Red
    exit 1
}

# Create output directory if it doesn't exist
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    Write-Host "Created output directory: $OutputDir" -ForegroundColor Green
}

# Set output file name
$OutputFile = "$OutputDir\AHK-Tools-v$Version.exe"

# Check if Ahk2Exe compiler exists
$CompilerPath = "Compiler\Ahk2Exe.exe"
if (-not (Test-Path $CompilerPath)) {
    Write-Host "Error: Ahk2Exe compiler not found: $CompilerPath" -ForegroundColor Red
    exit 1
}

Write-Host "Compiling $SourceFile to $OutputFile..." -ForegroundColor Cyan

# Try to compile using Ahk2Exe
try {
    $Process = Start-Process -FilePath $CompilerPath -ArgumentList "/in", "`"$SourceFile`"", "/out", "`"$OutputFile`"" -Wait -PassThru -NoNewWindow
    
    if ($Process.ExitCode -eq 0) {
        Write-Host "Compilation successful!" -ForegroundColor Green
        
        # Check if file was created
        if (Test-Path $OutputFile) {
            $FileSize = (Get-Item $OutputFile).Length
            Write-Host "Executable created: $OutputFile" -ForegroundColor Green
            Write-Host "File size: $($FileSize / 1MB) MB" -ForegroundColor Yellow
        } else {
            Write-Host "Warning: Output file not found after compilation" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Compilation failed with exit code: $($Process.ExitCode)" -ForegroundColor Red
    }
} catch {
    Write-Host "Error during compilation: $($_.Exception.Message)" -ForegroundColor Red
}

# Alternative: Create a simple launcher script
Write-Host "Creating alternative launcher..." -ForegroundColor Cyan
$LauncherFile = "$OutputDir\AHK-Tools-Launcher-v$Version.bat"
$LauncherContent = @"
@echo off
REM AHK Tools Launcher v$Version
REM This launcher runs the AHK script using AutoHotkey v2

echo Starting AHK Tools v$Version...
echo.

REM Check if AutoHotkey v2 is installed
if not exist "C:\Program Files\AutoHotkey\v2\AutoHotkey.exe" (
    echo Error: AutoHotkey v2 is not installed.
    echo Please install AutoHotkey v2 from: https://www.autohotkey.com/
    pause
    exit /b 1
)

REM Run the script
"C:\Program Files\AutoHotkey\v2\AutoHotkey.exe" "%~dp0..\src\AHK-Tools-Plugins.ahk"

echo.
echo AHK Tools has been closed.
pause
"@

$LauncherContent | Out-File -FilePath $LauncherFile -Encoding ASCII
Write-Host "Launcher created: $LauncherFile" -ForegroundColor Green

Write-Host "`nCompilation process completed!" -ForegroundColor Green 