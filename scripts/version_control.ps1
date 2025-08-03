# AHK Tools Version Control Script
# PowerShell script for version control automation

param(
    [string]$Action = "help",
    [string]$Version = "",
    [string]$Type = "patch"
)

# Configuration
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$MainScript = Join-Path $ProjectRoot "src\AHK-Tools-Plugins.ahk"
$VersionFile = Join-Path $ProjectRoot "VERSION.md"
$ChangelogFile = Join-Path $ProjectRoot "CHANGELOG.md"

# Colors for output
$Green = "Green"
$Yellow = "Yellow"
$Red = "Red"
$Cyan = "Cyan"

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Get-CurrentVersion {
    try {
        $scriptContent = Get-Content $MainScript -Raw
        if ($scriptContent -match 'version:\s*"([^"]*)"') {
            return $matches[1]
        }
        return "Unknown"
    } catch {
        return "Unknown"
    }
}

function Show-VersionInfo {
    $currentVersion = Get-CurrentVersion
    Write-ColorOutput "=== AHK Tools Version Information ===" $Cyan
    Write-ColorOutput "Current Version: $currentVersion" $Green
    Write-ColorOutput "Main Script: $MainScript" $Yellow
    Write-ColorOutput "Version File: $VersionFile" $Yellow
    Write-ColorOutput "Changelog: $ChangelogFile" $Yellow
    
    # Show git status
    Write-ColorOutput "`n=== Git Status ===" $Cyan
    git status --porcelain
    
    # Show recent tags
    Write-ColorOutput "`n=== Recent Tags ===" $Cyan
    git tag --sort=-version:refname | Select-Object -First 5
}

function Test-VersionFormat {
    param([string]$Version)
    
    if ($Version -match '^\d+\.\d+\.\d+$') {
        return $true
    }
    return $false
}

function Suggest-NextVersion {
    param(
        [string]$CurrentVersion,
        [string]$Type
    )
    
    $parts = $CurrentVersion.Split('.')
    $major = [int]$parts[0]
    $minor = [int]$parts[1]
    $patch = [int]$parts[2]
    
    switch ($Type) {
        "major" { return "$($major + 1).0.0" }
        "minor" { return "$major.$($minor + 1).0" }
        "patch" { return "$major.$minor.$($patch + 1)" }
        default { return "$major.$minor.$($patch + 1)" }
    }
}

function Create-GitTag {
    param([string]$Version)
    
    try {
        Write-ColorOutput "Creating git tag AHK-$Version..." $Yellow
        git tag "AHK-$Version"
        
        Write-ColorOutput "Pushing tag to remote..." $Yellow
        git push origin "AHK-$Version"
        
        Write-ColorOutput "Git tag AHK-$Version created and pushed successfully!" $Green
        return $true
    } catch {
        Write-ColorOutput "Error creating git tag: $_" $Red
        return $false
    }
}

function Show-ReleaseChecklist {
    param([string]$Version)
    
    Write-ColorOutput "`n=== Release Checklist for v$Version ===" $Cyan
    Write-ColorOutput "Before Release:" $Yellow
    Write-ColorOutput "□ Update version numbers in all relevant files" $White
    Write-ColorOutput "□ Test all functionality" $White
    Write-ColorOutput "□ Update documentation" $White
    Write-ColorOutput "□ Create git tag" $White
    Write-ColorOutput "□ Push to remote repository" $White
    Write-ColorOutput "□ Update VERSION.md" $White
    Write-ColorOutput "□ Update CHANGELOG.md" $White
    
    Write-ColorOutput "`nAfter Release:" $Yellow
    Write-ColorOutput "□ Create GitHub release" $White
    Write-ColorOutput "□ Update download links" $White
    Write-ColorOutput "□ Notify users" $White
}

function Show-Help {
    Write-ColorOutput "=== AHK Tools Version Control ===" $Cyan
    Write-ColorOutput "Usage: .\version_control.ps1 [Action] [Parameters]" $White
    Write-ColorOutput ""
    Write-ColorOutput "Actions:" $Yellow
    Write-ColorOutput "  info                    - Show current version information" $White
    Write-ColorOutput "  suggest [type]          - Suggest next version (patch/minor/major)" $White
    Write-ColorOutput "  tag [version]           - Create git tag for version" $White
    Write-ColorOutput "  checklist [version]     - Show release checklist" $White
    Write-ColorOutput "  status                  - Show git status and recent tags" $White
    Write-ColorOutput "  help                    - Show this help message" $White
    Write-ColorOutput ""
    Write-ColorOutput "Examples:" $Yellow
    Write-ColorOutput "  .\version_control.ps1 info" $White
    Write-ColorOutput "  .\version_control.ps1 suggest patch" $White
    Write-ColorOutput "  .\version_control.ps1 tag 2.1.1" $White
    Write-ColorOutput "  .\version_control.ps1 checklist 2.1.1" $White
}

# Main script logic
switch ($Action.ToLower()) {
    "info" {
        Show-VersionInfo
    }
    "suggest" {
        $currentVersion = Get-CurrentVersion
        $suggestedVersion = Suggest-NextVersion $currentVersion $Type
        Write-ColorOutput "Current Version: $currentVersion" $Green
        Write-ColorOutput "Suggested Version ($Type): $suggestedVersion" $Yellow
    }
    "tag" {
        if ([string]::IsNullOrEmpty($Version)) {
            Write-ColorOutput "Error: Version parameter is required for tag action" $Red
            Write-ColorOutput "Usage: .\version_control.ps1 tag 2.1.1" $White
            exit 1
        }
        
        if (-not (Test-VersionFormat $Version)) {
            Write-ColorOutput "Error: Invalid version format. Use MAJOR.MINOR.PATCH (e.g., 2.1.1)" $Red
            exit 1
        }
        
        Create-GitTag $Version
    }
    "checklist" {
        if ([string]::IsNullOrEmpty($Version)) {
            $currentVersion = Get-CurrentVersion
            $suggestedVersion = Suggest-NextVersion $currentVersion "patch"
            Write-ColorOutput "No version specified, using suggested version: $suggestedVersion" $Yellow
            $Version = $suggestedVersion
        }
        
        Show-ReleaseChecklist $Version
    }
    "status" {
        Write-ColorOutput "=== Git Status ===" $Cyan
        git status
        
        Write-ColorOutput "`n=== Recent Tags ===" $Cyan
        git tag --sort=-version:refname | Select-Object -First 10
    }
    "help" {
        Show-Help
    }
    default {
        Write-ColorOutput "Unknown action: $Action" $Red
        Write-ColorOutput "Use 'help' action to see available options" $Yellow
        Show-Help
    }
} 