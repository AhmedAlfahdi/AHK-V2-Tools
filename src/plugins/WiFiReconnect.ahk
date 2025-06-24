#Requires AutoHotkey v2.0-*

; =================== WI-FI RECONNECT PLUGIN ===================
; Plugin for Wi-Fi reconnection and DNS flush operations

; TopMsgBox, SafeMsgBox, and ShowMouseTooltip functions are defined in main file

class WiFiReconnectPlugin extends Plugin {
    ; Plugin metadata
    static Name := "Wi-Fi Reconnect"
    static Description := "Reconnects Wi-Fi and flushes DNS cache for network troubleshooting"
    static Version := "1.0.0"
    static Author := "AHK Tools"
    
    ; Plugin settings
    Settings := Map(
        "interfaceName", "Wi-Fi",
        "disableDelay", 2000,
        "enableDelay", 2000,
        "showProgress", true,
        "flushDNS", true,
        "requiresAdmin", true
    )
    
    ; Constructor
    __New() {
        super.__New()
    }
    
    ; Initialize the plugin
    Initialize() {
        ; Plugin initialized successfully
        return true
    }
    
    ; Enable the plugin
    Enable() {
        try {
            this.Enabled := true
            return true
        } catch as e {
            SafeMsgBox("Error enabling Wi-Fi Reconnect plugin: " e.Message, "Plugin Error", "Iconx")
            return false
        }
    }
    
    ; Disable the plugin
    Disable() {
        try {
            this.Enabled := false
            return true
        } catch as e {
            MsgBox "Error disabling Wi-Fi Reconnect plugin: " e.Message, "Plugin Error", "Iconx"
            return false
        }
    }
    
    ; Execute the main plugin functionality
    Execute() {
        if (!this.Enabled) {
            SafeMsgBox("Wi-Fi Reconnect plugin is disabled.", "Plugin Disabled", "Icon!")
            return
        }
        
        ; Check if running as admin
        if (!this.CheckAdminRequired()) {
            return
        }
        
        this.ShowReconnectDialog()
    }
    
    ; Check if admin privileges are required
    CheckAdminRequired() {
        if (!A_IsAdmin) {
            result := TopMsgBox("Wi-Fi Reconnect requires administrator privileges.`n`nWould you like to restart the script as admin?", "Admin Required", "YesNo Icon?")
            if (result = "Yes") {
                try {
                    Run '*RunAs "' A_ScriptFullPath '"'
                    ExitApp
                } catch as e {
                    TopMsgBox("Error restarting as admin: " e.Message, "Error", "Iconx")
                }
            }
            return false
        }
        return true
    }
    
    ; Show the reconnect options dialog
    ShowReconnectDialog() {
        reconGui := Gui("+AlwaysOnTop +ToolWindow", "Wi-Fi Reconnect & DNS Flush")
        reconGui.SetFont("s10", "Segoe UI")
        reconGui.BackColor := 0xF5F5F5

        ; Header
        reconGui.Add("Text", "x20 y20 w400 Center", "Wi-Fi Network Troubleshooting").SetFont("s12 Bold")
        reconGui.Add("Text", "x20 y45 w400", "Select the operations to perform:")

        ; Options
        reconnectCheck := reconGui.Add("Checkbox", "x30 y75 w360 Checked", "Reconnect Wi-Fi interface")
        flushDNSCheck := reconGui.Add("Checkbox", "x30 y100 w360 Checked", "Flush DNS cache")
        releaseRenewCheck := reconGui.Add("Checkbox", "x30 y125 w360", "Release and renew IP address")
        resetWinsockCheck := reconGui.Add("Checkbox", "x30 y150 w360", "Reset Winsock catalog")
        
        ; Interface selection
        reconGui.Add("Text", "x30 y185", "Network Interface:")
        interfaceEdit := reconGui.Add("Edit", "x30 y205 w200")
        interfaceEdit.Text := this.Settings["interfaceName"]
        
        detectBtn := reconGui.Add("Button", "x240 y205 w120 h23", "Auto-Detect")
        detectBtn.OnEvent("Click", (*) => this.DetectInterface(interfaceEdit))

        ; Progress options
        reconGui.Add("GroupBox", "x20 y240 w400 h60", "Options")
        showProgressCheck := reconGui.Add("Checkbox", "x30 y260 w180", "Show detailed progress")
        showProgressCheck.Value := this.Settings["showProgress"]
        
        silentModeCheck := reconGui.Add("Checkbox", "x220 y260 w180", "Silent mode (no popups)")

        ; Action buttons
        btnStart := reconGui.Add("Button", "x30 y320 w100 h35", "&Start")
        btnStart.SetFont("s10")
        btnStart.OnEvent("Click", (*) => this.StartReconnect(reconGui, reconnectCheck, flushDNSCheck, releaseRenewCheck, resetWinsockCheck, interfaceEdit, showProgressCheck, silentModeCheck))
        
        btnQuick := reconGui.Add("Button", "x140 y320 w100 h35", "&Quick Fix")
        btnQuick.SetFont("s10") 
        btnQuick.OnEvent("Click", (*) => this.QuickReconnect())
        
        btnCancel := reconGui.Add("Button", "x250 y320 w80 h35", "&Cancel")
        btnCancel.SetFont("s10")
        btnCancel.OnEvent("Click", (*) => reconGui.Destroy())
        
        btnHelp := reconGui.Add("Button", "x340 y320 w80 h35", "&Help")
        btnHelp.SetFont("s10")
        btnHelp.OnEvent("Click", (*) => this.ShowHelp())

        ; Event handlers
        reconGui.OnEvent("Escape", (*) => reconGui.Destroy())
        reconGui.OnEvent("Close", (*) => reconGui.Destroy())
        
        ; Show the dialog
        reconGui.Show("w440 h375")
        btnStart.Focus()
    }
    
    ; Detect Wi-Fi interface automatically
    DetectInterface(interfaceEdit) {
        try {
            ; Try common interface names
            interfaces := ["Wi-Fi", "WiFi", "Wireless", "WLAN", "Ethernet"]
            
            for interface in interfaces {
                ; Test if interface exists by trying to get its status
                try {
                    RunWait 'netsh interface show interface name="' interface '"',, "Hide"
                    ; If we get here, the interface exists
                    interfaceEdit.Text := interface
                            ShowMouseTooltip("Interface '" interface "' detected", 2000)
                    return
                } catch {
                    continue
                }
            }
            
            ; If no common interface found, show a dialog to list all interfaces
            this.ShowInterfaceList(interfaceEdit)
            
        } catch as e {
            MsgBox "Error detecting interfaces: " e.Message, "Detection Error", "Iconx"
        }
    }
    
    ; Show list of available interfaces
    ShowInterfaceList(interfaceEdit) {
        try {
            ; Get list of interfaces
            tempFile := A_Temp "\interfaces.txt"
            RunWait 'netsh interface show interface > "' tempFile '"',, "Hide"
            
            ; Read the file
            if FileExist(tempFile) {
                content := FileRead(tempFile)
                FileDelete tempFile
                
                ; Parse interface names (simplified)
                interfaceList := []
                Loop Parse content, "`n", "`r" {
                    if (InStr(A_LoopField, "Connected") || InStr(A_LoopField, "Disconnected")) {
                        ; Extract interface name (this is a simplified approach)
                        parts := StrSplit(A_LoopField, " ")
                        if (parts.Length >= 4) {
                            interfaceName := parts[4]
                            interfaceList.Push(interfaceName)
                        }
                    }
                }
                
                if (interfaceList.Length > 0) {
                    interfaceEdit.Text := interfaceList[1]
                    ShowMouseTooltip("Found " interfaceList.Length " interfaces. Using: " interfaceList[1], 3000)
                } else {
                    ShowMouseTooltip("No interfaces found. Using default: Wi-Fi", 2000)
                    interfaceEdit.Text := "Wi-Fi"
                }
            }
        } catch as e {
            ShowMouseTooltip("Auto-detection failed. Using default: Wi-Fi", 2000)
            interfaceEdit.Text := "Wi-Fi"
        }
    }
    
    ; Quick reconnect with default settings
    QuickReconnect() {
        ; Start quick reconnect with minimal UI
        this.PerformReconnect(this.Settings["interfaceName"], true, true, false, false, false, false)
    }
    
    ; Start the reconnect process with custom options
    StartReconnect(gui, reconnectCheck, flushDNSCheck, releaseRenewCheck, resetWinsockCheck, interfaceEdit, showProgressCheck, silentModeCheck) {
        ; Get settings
        interfaceName := interfaceEdit.Text
        doReconnect := reconnectCheck.Value
        doFlushDNS := flushDNSCheck.Value
        doReleaseRenew := releaseRenewCheck.Value
        doResetWinsock := resetWinsockCheck.Value
        showProgress := showProgressCheck.Value
        silentMode := silentModeCheck.Value
        
        ; Close dialog
        gui.Destroy()
        
        ; Perform operations
        this.PerformReconnect(interfaceName, doReconnect, doFlushDNS, doReleaseRenew, doResetWinsock, showProgress, silentMode)
    }
    
    ; Perform the actual reconnect operations
    PerformReconnect(interfaceName, doReconnect, doFlushDNS, doReleaseRenew, doResetWinsock, showProgress, silentMode) {
        progressGui := ""
        progressBar := ""
        statusText := ""
        
        ; Create progress dialog if requested
        if (showProgress) {
            progressGui := Gui("+AlwaysOnTop +ToolWindow", "Wi-Fi Reconnect - Progress")
            progressGui.SetFont("s10", "Segoe UI")
            progressGui.BackColor := 0xF5F5F5
            
            progressGui.Add("Text", "x20 y20 w350 Center", "Network Troubleshooting in Progress").SetFont("s11 Bold")
            progressBar := progressGui.Add("Progress", "x20 y50 w350 h20 Range0-100")
            statusText := progressGui.Add("Text", "x20 y80 w350", "Initializing...")
            
            btnCancel := progressGui.Add("Button", "x160 y110 w80 h30", "Cancel")
            btnCancel.OnEvent("Click", (*) => (progressGui.Destroy(), ExitApp()))
            
            progressGui.Show("w390 h160")
        }
        
        try {
            step := 0
            totalSteps := 0
            
            ; Count total steps
            if (doReconnect) totalSteps += 2  ; Disable + Enable
            if (doFlushDNS) totalSteps += 1
            if (doReleaseRenew) totalSteps += 2  ; Release + Renew
            if (doResetWinsock) totalSteps += 1
            
            ; Reconnect Wi-Fi interface
            if (doReconnect) {
                step++
                this.UpdateProgress(progressBar, statusText, step, totalSteps, "Disabling Wi-Fi interface...")
                
                try {
                    RunWait 'netsh interface set interface name="' interfaceName '" admin=disable',, "Hide"
                    if (!silentMode) {
                                    ShowMouseTooltip("Wi-Fi disabled", 1000)
                    }
                } catch as e {
                    if (!silentMode) {
                        MsgBox "Error disabling interface: " e.Message, "Warning", "Icon!"
                    }
                }
                
                Sleep this.Settings["disableDelay"]
                
                step++
                this.UpdateProgress(progressBar, statusText, step, totalSteps, "Re-enabling Wi-Fi interface...")
                
                try {
                    RunWait 'netsh interface set interface name="' interfaceName '" admin=enable',, "Hide"
                    if (!silentMode) {
                                    ShowMouseTooltip("Wi-Fi re-enabled", 1000)
                    }
                } catch as e {
                    if (!silentMode) {
                        MsgBox "Error enabling interface: " e.Message, "Warning", "Icon!"
                    }
                }
                
                Sleep this.Settings["enableDelay"]
            }
            
            ; Flush DNS cache
            if (doFlushDNS) {
                step++
                this.UpdateProgress(progressBar, statusText, step, totalSteps, "Flushing DNS cache...")
                
                try {
                    RunWait "ipconfig /flushdns",, "Hide"
                    if (!silentMode) {
                                            ShowMouseTooltip("DNS cache flushed", 1000)
                    }
                } catch as e {
                    if (!silentMode) {
                        MsgBox "Error flushing DNS: " e.Message, "Warning", "Icon!"
                    }
                }
            }
            
            ; Release and renew IP
            if (doReleaseRenew) {
                step++
                this.UpdateProgress(progressBar, statusText, step, totalSteps, "Releasing IP address...")
                
                try {
                    RunWait "ipconfig /release",, "Hide"
                    if (!silentMode) {
                                            ShowMouseTooltip("IP address released", 1000)
                    }
                } catch as e {
                    if (!silentMode) {
                        MsgBox "Error releasing IP: " e.Message, "Warning", "Icon!"
                    }
                }
                
                step++
                this.UpdateProgress(progressBar, statusText, step, totalSteps, "Renewing IP address...")
                
                try {
                    RunWait "ipconfig /renew",, "Hide"
                    if (!silentMode) {
                                        ShowMouseTooltip("IP address renewed", 1000)
                    }
                } catch as e {
                    if (!silentMode) {
                        MsgBox "Error renewing IP: " e.Message, "Warning", "Icon!"
                    }
                }
            }
            
            ; Reset Winsock
            if (doResetWinsock) {
                step++
                this.UpdateProgress(progressBar, statusText, step, totalSteps, "Resetting Winsock catalog...")
                
                try {
                    RunWait "netsh winsock reset",, "Hide"
                    if (!silentMode) {
                                    ShowMouseTooltip("Winsock catalog reset (restart required)", 3000)
                    }
                } catch as e {
                    if (!silentMode) {
                        MsgBox "Error resetting Winsock: " e.Message, "Warning", "Icon!"
                    }
                }
            }
            
            ; Completion
            this.UpdateProgress(progressBar, statusText, totalSteps, totalSteps, "Network troubleshooting completed!")
            
            if (!silentMode) {
                        ShowMouseTooltip("Wi-Fi reconnect and DNS flush completed successfully", 3000)
            }
            
            ; Close progress dialog after a moment
            if (progressGui) {
                SetTimer(() => progressGui.Destroy(), -2000)
            }
            
        } catch as e {
            if (progressGui) {
                progressGui.Destroy()
            }
            if (!silentMode) {
                MsgBox "Error during network operations: " e.Message, "Error", "Iconx"
            }
        }
    }
    
    ; Update progress display
    UpdateProgress(progressBar, statusText, currentStep, totalSteps, message) {
        if (progressBar && statusText) {
            percentage := Round((currentStep / totalSteps) * 100)
            progressBar.Value := percentage
            statusText.Text := message
        }
    }
    
    ; Show help information
    ShowHelp() {
        helpText := "
(
Wi-Fi Reconnect & DNS Flush Help
═══════════════════════════════════

Operations:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

• Reconnect Wi-Fi Interface
  Disables and re-enables the Wi-Fi adapter
  Useful for: Connection drops, slow speeds
  
• Flush DNS Cache
  Clears the DNS resolver cache
  Useful for: Website access issues, DNS errors
  
• Release and Renew IP Address
  Gets a new IP address from DHCP server
  Useful for: IP conflicts, connectivity issues
  
• Reset Winsock Catalog
  Resets network socket configuration
  Useful for: Network protocol corruption
  Note: Requires system restart to take effect


Interface Names:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Common interface names:
• Wi-Fi (most common)
• WiFi
• Wireless
• WLAN
• Ethernet (for wired connections)

Use 'Auto-Detect' to find your interface name automatically.


Quick Fix vs Custom:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

• Quick Fix: Reconnects Wi-Fi and flushes DNS
• Custom: Choose specific operations and settings


Requirements:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

• Administrator privileges required
• Active network interface
• Windows Vista or later

Note: Some operations may temporarily disconnect your internet.
)"
        
        helpGui := Gui("+AlwaysOnTop", "Wi-Fi Reconnect - Help")
        helpGui.SetFont("s9", "Consolas")
        helpGui.BackColor := 0xF8F8F8
        
        helpGui.Add("Text", "x20 y20 w580", helpText)
        helpGui.Add("Button", "x270 y420 w100 h30", "OK").OnEvent("Click", (*) => helpGui.Destroy())
        
        helpGui.OnEvent("Escape", (*) => helpGui.Destroy())
        helpGui.Show("w620 h470")
    }
    
    ; Show plugin settings
    ShowSettings() {
        settingsGui := Gui("+AlwaysOnTop", "Wi-Fi Reconnect - Settings")
        settingsGui.SetFont("s10", "Segoe UI")
        
        ; Interface settings
        settingsGui.Add("Text", "x20 y20", "Default Wi-Fi Interface:")
        interfaceEdit := settingsGui.Add("Edit", "x20 y45 w200")
        interfaceEdit.Text := this.Settings["interfaceName"]
        
        ; Timing settings
        settingsGui.Add("Text", "x20 y80", "Disable Delay (ms):")
        disableEdit := settingsGui.Add("Edit", "x20 y105 w100")
        disableEdit.Text := this.Settings["disableDelay"]
        
        settingsGui.Add("Text", "x140 y80", "Enable Delay (ms):")
        enableEdit := settingsGui.Add("Edit", "x140 y105 w100")
        enableEdit.Text := this.Settings["enableDelay"]
        
        ; Options
        flushDNSCheck := settingsGui.Add("Checkbox", "x20 y140", "Always flush DNS")
        flushDNSCheck.Value := this.Settings["flushDNS"]
        
        showProgressCheck := settingsGui.Add("Checkbox", "x20 y165", "Show progress by default")
        showProgressCheck.Value := this.Settings["showProgress"]
        
        ; Buttons
        saveBtn := settingsGui.Add("Button", "x20 y200 w80", "Save")
        saveBtn.OnEvent("Click", (*) => this.SaveSettings(settingsGui, interfaceEdit, disableEdit, enableEdit, flushDNSCheck, showProgressCheck))
        
        cancelBtn := settingsGui.Add("Button", "x110 y200 w80", "Cancel")
        cancelBtn.OnEvent("Click", (*) => settingsGui.Destroy())
        
        resetBtn := settingsGui.Add("Button", "x200 y200 w80", "Reset")
        resetBtn.OnEvent("Click", (*) => this.ResetSettings(settingsGui, interfaceEdit, disableEdit, enableEdit, flushDNSCheck, showProgressCheck))
        
        settingsGui.Show("w300 h250")
    }
    
    ; Save plugin settings
    SaveSettings(gui, interfaceEdit, disableEdit, enableEdit, flushDNSCheck, showProgressCheck) {
        this.Settings["interfaceName"] := interfaceEdit.Text
        this.Settings["disableDelay"] := Integer(disableEdit.Text)
        this.Settings["enableDelay"] := Integer(enableEdit.Text)
        this.Settings["flushDNS"] := flushDNSCheck.Value
        this.Settings["showProgress"] := showProgressCheck.Value
        
        ShowMouseTooltip("Settings saved", 1000)
        gui.Destroy()
    }
    
    ; Reset settings to defaults
    ResetSettings(gui, interfaceEdit, disableEdit, enableEdit, flushDNSCheck, showProgressCheck) {
        interfaceEdit.Text := "Wi-Fi"
        disableEdit.Text := "2000"
        enableEdit.Text := "2000"
        flushDNSCheck.Value := true
        showProgressCheck.Value := true
        
        ShowMouseTooltip("Settings reset to defaults", 1000)
    }
} 