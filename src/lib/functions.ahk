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
    MsgBox "Settings dialog will be implemented here"
}

ShowAbout(*) {
    aboutText := Format("{1}`nVersion {2}`n`nCreated by: {3}", 
                       CONFIG.appName, 
                       CONFIG.version, 
                       CONFIG.author)
    MsgBox aboutText
}

ReloadScript(*) {
    Reload
}

ExitScript(*) {
    ExitApp
} 