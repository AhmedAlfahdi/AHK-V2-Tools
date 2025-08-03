#Requires AutoHotkey v2.0-*

; Version Update Script for AHK Tools
; This script automates version updates across all project files

; Configuration
global SCRIPT_DIR := A_ScriptDir "\.."
global MAIN_SCRIPT := SCRIPT_DIR "\src\AHK-Tools-Plugins.ahk"
global VERSION_FILE := SCRIPT_DIR "\VERSION.md"
global CHANGELOG_FILE := SCRIPT_DIR "\CHANGELOG.md"
global README_FILE := SCRIPT_DIR "\README.md"

; Version update function
UpdateVersion(newVersion, updateType := "patch") {
    try {
        ; Validate version format
        if (!RegExMatch(newVersion, "^\d+\.\d+\.\d+$")) {
            throw Error("Invalid version format. Use MAJOR.MINOR.PATCH (e.g., 2.1.1)")
        }
        
        ; Parse version components
        versionParts := StrSplit(newVersion, ".")
        major := versionParts[1]
        minor := versionParts[2]
        patch := versionParts[3]
        
        ; Update main script
        UpdateMainScript(newVersion)
        
        ; Update VERSION.md
        UpdateVersionFile(newVersion, updateType)
        
        ; Update CHANGELOG.md
        UpdateChangelog(newVersion, updateType)
        
        ; Show success message
        MsgBox("Version updated successfully to " newVersion "!`n`nNext steps:`n1. Test the script`n2. Commit changes`n3. Create git tag: git tag AHK-" newVersion "`n4. Push tag: git push origin AHK-" newVersion, "Version Update Complete", "Iconi")
        
    } catch as e {
        MsgBox("Error updating version: " e.Message, "Version Update Error", "Iconx")
    }
}

; Update main script version
UpdateMainScript(newVersion) {
    try {
        ; Read the main script
        scriptContent := FileRead(MAIN_SCRIPT)
        
        ; Update version in CONFIG object
        scriptContent := RegExReplace(scriptContent, 'version:\s*"[^"]*"', 'version: "' newVersion '"')
        
        ; Write back to file
        FileDelete(MAIN_SCRIPT)
        FileAppend(scriptContent, MAIN_SCRIPT)
        
        MsgBox("Updated main script version to " newVersion, "Script Updated", "Iconi")
        
    } catch as e {
        throw Error("Failed to update main script: " e.Message)
    }
}

; Update VERSION.md file
UpdateVersionFile(newVersion, updateType) {
    try {
        ; Read current version file
        versionContent := FileRead(VERSION_FILE)
        
        ; Update current version
        versionContent := RegExReplace(versionContent, '## Current Version\s*\*\*v[^)]*\*\*', '## Current Version`n**v' newVersion '** - Latest stable release')
        
        ; Add new version entry
        currentDate := FormatTime(, "yyyy-MM-dd")
        newEntry := "`n`n### v" newVersion "`n- **Release Date**: " currentDate "`n- **Status**: Stable`n- **Key Features**:`n  - Version update`n  - Bug fixes and improvements`n`n"
        
        ; Insert after the Current Version section
        versionContent := RegExReplace(versionContent, '(## Current Version.*?\n\n)', '$1' newEntry)
        
        ; Write back to file
        FileDelete(VERSION_FILE)
        FileAppend(versionContent, VERSION_FILE)
        
        MsgBox("Updated VERSION.md to " newVersion, "Version File Updated", "Iconi")
        
    } catch as e {
        throw Error("Failed to update VERSION.md: " e.Message)
    }
}

; Update CHANGELOG.md file
UpdateChangelog(newVersion, updateType) {
    try {
        ; Read current changelog
        changelogContent := FileRead(CHANGELOG_FILE)
        
        ; Create new changelog entry
        currentDate := FormatTime(, "yyyy-MM-dd")
        newEntry := "## [" newVersion "] - " currentDate "`n`n### Added`n- Version update to " newVersion "`n`n### Changed`n- Updated version numbers across project files`n`n### Fixed`n- None`n`n"
        
        ; Insert after the [Unreleased] section
        changelogContent := RegExReplace(changelogContent, '(\[Unreleased\].*?\n\n)', '$1' newEntry)
        
        ; Write back to file
        FileDelete(CHANGELOG_FILE)
        FileAppend(changelogContent, CHANGELOG_FILE)
        
        MsgBox("Updated CHANGELOG.md with version " newVersion, "Changelog Updated", "Iconi")
        
    } catch as e {
        throw Error("Failed to update CHANGELOG.md: " e.Message)
    }
}

; Get current version from main script
GetCurrentVersion() {
    try {
        scriptContent := FileRead(MAIN_SCRIPT)
        if (RegExMatch(scriptContent, 'version:\s*"([^"]*)"', &match)) {
            return match[1]
        }
        return "Unknown"
    } catch {
        return "Unknown"
    }
}

; Suggest next version based on update type
SuggestNextVersion(currentVersion, updateType) {
    versionParts := StrSplit(currentVersion, ".")
    major := versionParts[1]
    minor := versionParts[2]
    patch := versionParts[3]
    
    switch updateType {
        case "major":
            return (major + 1) ".0.0"
        case "minor":
            return major "." (minor + 1) ".0"
        case "patch":
            return major "." minor "." (patch + 1)
        default:
            return major "." minor "." (patch + 1)
    }
}

; Main GUI for version update
ShowVersionUpdateGUI() {
    currentVersion := GetCurrentVersion()
    
    ; Create GUI
    gui := Gui("+AlwaysOnTop", "AHK Tools Version Update")
    
    ; Current version display
    gui.Add("Text", "w300", "Current Version: " currentVersion)
    gui.Add("Text", "w300", "")
    
    ; Update type selection
    gui.Add("Text", "w300", "Update Type:")
    updateType := gui.Add("Radio", "vUpdateType Checked", "Patch (2.1.0 → 2.1.1)")
    gui.Add("Radio",, "Minor (2.1.0 → 2.2.0)")
    gui.Add("Radio",, "Major (2.1.0 → 3.0.0)")
    gui.Add("Text", "w300", "")
    
    ; New version input
    suggestedVersion := SuggestNextVersion(currentVersion, "patch")
    gui.Add("Text", "w300", "New Version:")
    versionInput := gui.Add("Edit", "vNewVersion w150", suggestedVersion)
    gui.Add("Text", "w300", "Format: MAJOR.MINOR.PATCH (e.g., 2.1.1)")
    gui.Add("Text", "w300", "")
    
    ; Buttons
    gui.Add("Button", "w100 h30", "Update Version").OnEvent("Click", UpdateVersionHandler)
    gui.Add("Button", "x+10 w100 h30", "Cancel").OnEvent("Click", (*) => gui.Destroy())
    
    ; Show GUI
    gui.Show()
    
    ; Event handlers
    UpdateVersionHandler(ctrl, info) {
        saved := gui.Submit(false)
        if (saved) {
            updateType := saved.UpdateType
            newVersion := saved.NewVersion
            
            ; Determine update type from radio selection
            switch updateType {
                case 1: type := "patch"
                case 2: type := "minor"
                case 3: type := "major"
                default: type := "patch"
            }
            
            ; Update version
            UpdateVersion(newVersion, type)
            gui.Destroy()
        }
    }
}

; Command line interface
if (A_Args.Length > 0) {
    newVersion := A_Args[1]
    updateType := A_Args.Length > 1 ? A_Args[2] : "patch"
    UpdateVersion(newVersion, updateType)
} else {
    ; Show GUI if no arguments provided
    ShowVersionUpdateGUI()
}

; Helper function to create git tag
CreateGitTag(version) {
    try {
        ; Create tag
        RunWait("git tag AHK-" version, A_WorkingDir)
        
        ; Push tag
        RunWait("git push origin AHK-" version, A_WorkingDir)
        
        MsgBox("Git tag AHK-" version " created and pushed successfully!", "Git Tag Created", "Iconi")
        
    } catch as e {
        MsgBox("Error creating git tag: " e.Message, "Git Tag Error", "Iconx")
    }
}

; Helper function to show version info
ShowVersionInfo() {
    currentVersion := GetCurrentVersion()
    
    info := "AHK Tools Version Information`n`n"
    info .= "Current Version: " currentVersion "`n"
    info .= "Main Script: " MAIN_SCRIPT "`n"
    info .= "Version File: " VERSION_FILE "`n"
    info .= "Changelog: " CHANGELOG_FILE "`n`n"
    info .= "Usage:`n"
    info .= "1. Run without arguments: Show GUI`n"
    info .= "2. Run with version: update_version.ahk 2.1.1`n"
    info .= "3. Run with version and type: update_version.ahk 2.1.1 patch`n"
    
    MsgBox(info, "Version Information", "Iconi")
}

; Export functions for external use
global VersionUpdater := {
    UpdateVersion: UpdateVersion,
    GetCurrentVersion: GetCurrentVersion,
    CreateGitTag: CreateGitTag,
    ShowVersionInfo: ShowVersionInfo
} 