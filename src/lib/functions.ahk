; Utility functions

ShowTimeTooltip() {
    if (SubStr(A_AhkVersion, 1, 1) != "2") {
        MsgBox "Error: V2 required"
        return
    }
    currentTime := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    ToolTip(currentTime)
    SetTimer () => ToolTip(), -CONFIG.tooltipDuration
}

ShowSettings(*) {
    ; Create settings GUI
    settingsGui := Gui("+AlwaysOnTop", "Script Settings")
    settingsGui.SetFont("s10", "Segoe UI")
    
    ; Add startup setting
    startupCheck := settingsGui.Add("CheckBox", "vRunAtStartup", "Run at Windows startup")
    startupCheck.Value := IsStartupEnabled() ? 1 : 0
    
    ; Add save and close buttons
    settingsGui.Add("Button", "Default w100", "Save").OnEvent("Click", (*) => SaveStartupSetting(startupCheck.Value, settingsGui))
    settingsGui.Add("Button", "w100", "Close").OnEvent("Click", (*) => settingsGui.Destroy())
    
    settingsGui.Show()
}

SaveStartupSetting(enable, settingsGui) {
    try {
        if (enable) {
            ; Add to startup without admin privileges
            startupPath := A_Startup "\AHK-Tools.lnk"
            if !FileExist(startupPath) {
                ; Create shortcut
                FileCreateShortcut A_ScriptFullPath, startupPath, A_ScriptDir
            }
        } else {
            ; Remove from startup
            startupPath := A_Startup "\AHK-Tools.lnk"
            if FileExist(startupPath) {
                FileDelete startupPath
            }
        }
        
        ; Create a custom message box positioned closer to center
        msgGui := Gui("+AlwaysOnTop +ToolWindow", "Settings")
        msgGui.SetFont("s10", "Segoe UI")
        msgGui.Add("Text",, "Startup setting saved successfully!")
        msgGui.Add("Button", "Default w100", "OK").OnEvent("Click", (*) => msgGui.Destroy())
        
        ; Position the GUI closer to center but slightly to the right
        screenWidth := A_ScreenWidth
        guiWidth := 300
        xPos := (screenWidth - guiWidth) * 0.6  ; 60% from left (closer to center)
        msgGui.Show("x" xPos " yCenter")
    } catch as e {
        MsgBox "Error saving startup setting: " e.Message, "Error", "Iconx"
    }
}

IsStartupEnabled() {
    ; Check if startup shortcut exists
    return FileExist(A_Startup "\AHK-Tools.lnk")
}

ShowAbout(*) {
    aboutText := Format("{1}`nVersion {2}`n`nCreated by: {3}`nGitHub: {4}", 
                       CONFIG.appName, 
                       CONFIG.version, 
                       CONFIG.author,
                       CONFIG.GitHub)
    MsgBox aboutText
}

ReloadScript(*) {
    Reload
}

CheckAdminRequired() {
    if !A_IsAdmin {
        ; Create a warning GUI
        adminGui := Gui("+AlwaysOnTop", "Admin Required")
        adminGui.SetFont("s10", "Segoe UI")
        adminGui.Add("Text",, "This feature requires administrator privileges.")
        adminGui.Add("Text",, "Would you like to reload the script as admin?")
        
        ; Add buttons
        adminGui.Add("Button", "Default w100", "Yes").OnEvent("Click", (*) => ReloadAsAdmin())
        adminGui.Add("Button", "w100", "No").OnEvent("Click", (*) => adminGui.Destroy())
        
        ; Show the GUI
        adminGui.Show()
        return false
    }
    return true
}

ReloadAsAdmin() {
    try {
        ; Relaunch as admin
        Run '*RunAs "' A_ScriptFullPath '"'
        ExitApp
    } catch as e {
        MsgBox "Error reloading as admin: " e.Message, "Error", "Iconx"
    }
}

ExitScript(*) {
    ExitApp
}

; Add tray menu items
A_TrayMenu.Delete()  ; Clear default items
A_TrayMenu.Add("Reload Script", (*) => ReloadScript())
A_TrayMenu.Add("Reload as Admin", (*) => ReloadAsAdmin())
A_TrayMenu.Add()  ; Separator
A_TrayMenu.Add("Exit", (*) => ExitScript()) 


