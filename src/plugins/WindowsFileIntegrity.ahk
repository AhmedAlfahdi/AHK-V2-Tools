#Requires AutoHotkey v2.0-*

; =================== WINDOWS FILE INTEGRITY PLUGIN ===================
; Plugin for Windows File Integrity Check operations

; TopMsgBox, SafeMsgBox, and ShowMouseTooltip functions are defined in main file

class WindowsFileIntegrityPlugin extends Plugin {
    ; Plugin metadata
    static Name := "Windows File Integrity"
    static Description := "Provides Windows File Integrity Check operations (DISM and SFC)"
    static Version := "1.0.0"
    static Author := "AHK Tools"
    
    ; Plugin settings
    Settings := Map(
        "defaultCheckType", 5,  ; Complete check by default
        "showProgress", true,
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
            SafeMsgBox("Error enabling Windows File Integrity plugin: " e.Message, "Plugin Error", "Iconx")
            return false
        }
    }
    
    ; Disable the plugin
    Disable() {
        try {
            this.Enabled := false
            return true
        } catch as e {
            SafeMsgBox("Error disabling Windows File Integrity plugin: " e.Message, "Plugin Error", "Iconx")
            return false
        }
    }
    
    ; Execute the main plugin functionality
    Execute() {
        if (!this.Enabled) {
            SafeMsgBox("Windows File Integrity plugin is disabled.", "Plugin Disabled", "Icon!")
            return
        }
        
        ; Check if running as admin
        if (!this.CheckAdminRequired()) {
            return
        }
        
        this.ShowIntegrityCheckDialog()
    }
    
    ; Check if admin privileges are required
    CheckAdminRequired() {
        if (!A_IsAdmin) {
            result := TopMsgBox("Windows File Integrity Check requires administrator privileges.`n`nWould you like to restart the script as admin?", "Admin Required", "YesNo Icon?")
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
    
    ; Show the integrity check selection dialog
    ShowIntegrityCheckDialog() {
        selectGui := Gui("+AlwaysOnTop +ToolWindow", "Windows File Integrity Check")
        selectGui.SetFont("s10", "Segoe UI")
        selectGui.BackColor := 0xF5F5F5

        ; Header
        selectGui.Add("Text", "x20 y20 w460 Center", "Windows File Integrity Check").SetFont("s12 Bold")
        selectGui.Add("Text", "x20 y45 w460", "Select the type of check to perform:")

        ; Check type options
        selectGui.Add("Radio", "x30 y75 w450 vCheckType1 Group checked", "Quick Check (DISM /ScanHealth)")
        selectGui.Add("Text", "x50 y95 w430 c0x666666", "• Basic system file check - Fast scan for obvious issues")
        
        selectGui.Add("Radio", "x30 y120 w450 vCheckType2", "Full Check (DISM /CheckHealth)")
        selectGui.Add("Text", "x50 y140 w430 c0x666666", "• Detailed system file check - More thorough analysis")
        
        selectGui.Add("Radio", "x30 y165 w450 vCheckType3", "Repair Check (DISM /RestoreHealth)")
        selectGui.Add("Text", "x50 y185 w430 c0x666666", "• Attempt to repair system files - Downloads fixes if needed")
        
        selectGui.Add("Radio", "x30 y210 w450 vCheckType4", "SFC Scan (sfc /scannow)")
        selectGui.Add("Text", "x50 y230 w430 c0x666666", "• System File Checker scan - Verifies Windows system files")
        
        selectGui.Add("Radio", "x30 y255 w450 vCheckType5", "Complete Check (DISM + SFC)")
        selectGui.Add("Text", "x50 y275 w430 c0x666666", "• Full repair and verification - Recommended for thorough check")

        ; Buttons
        btnStart := selectGui.Add("Button", "x30 y315 w100 h35", "&Start Check")
        btnStart.SetFont("s10")
        btnStart.OnEvent("Click", (*) => this.StartIntegrityCheck(selectGui))
        
        btnCancel := selectGui.Add("Button", "x150 y315 w100 h35", "&Cancel")
        btnCancel.SetFont("s10")
        btnCancel.OnEvent("Click", (*) => selectGui.Destroy())
        
        btnHelp := selectGui.Add("Button", "x380 y315 w100 h35", "&Help")
        btnHelp.SetFont("s10")
        btnHelp.OnEvent("Click", (*) => this.ShowHelp())

        ; Event handlers
        selectGui.OnEvent("Escape", (*) => selectGui.Destroy())
        selectGui.OnEvent("Close", (*) => selectGui.Destroy())
        
        ; Show the dialog
        selectGui.Show("w500 h370")
        btnStart.Focus()
    }
    
    ; Start the selected integrity check
    StartIntegrityCheck(gui) {
        try {
            ; Determine which check type was selected
            checkType := 1
            Loop 5 {
                if (gui["CheckType" A_Index].Value) {
                    checkType := A_Index
                    break
                }
            }
            
            ; Close selection dialog
            gui.Destroy()
            
            ; Show progress dialog
            progressGui := Gui("+AlwaysOnTop +ToolWindow", "File Integrity Check - Running")
            progressGui.SetFont("s10", "Segoe UI")
            progressGui.BackColor := 0xF5F5F5
            
            progressGui.Add("Text", "x20 y20 w400 Center", "Running Windows File Integrity Check...").SetFont("s12 Bold")
            progressGui.Add("Text", "x20 y50 w400", "This operation may take several minutes depending on your system.")
            progressGui.Add("Text", "x20 y75 w400", "Please wait while the check completes...")
            
            ; Add a progress bar (visual feedback)
            progressBar := progressGui.Add("Progress", "x20 y100 w400 h20 Range0-100")
            statusText := progressGui.Add("Text", "x20 y130 w400", "Initializing...")
            
            btnClose := progressGui.Add("Button", "x175 y160 w100 h30 Disabled", "Close")
            btnClose.OnEvent("Click", (*) => progressGui.Destroy())
            
            progressGui.Show("w440 h210")
            
            ; Build command based on check type
            command := ""
            description := ""
            switch checkType {
                case 1:
                    command := "DISM.exe /Online /Cleanup-Image /ScanHealth"
                    description := "Running DISM scan health check..."
                case 2:
                    command := "DISM.exe /Online /Cleanup-Image /CheckHealth"
                    description := "Running DISM detailed health check..."
                case 3:
                    command := "DISM.exe /Online /Cleanup-Image /RestoreHealth"
                    description := "Running DISM restore health operation..."
                case 4:
                    command := "sfc /scannow"
                    description := "Running System File Checker scan..."
                case 5:
                    command := "DISM.exe /Online /Cleanup-Image /RestoreHealth && sfc /scannow"
                    description := "Running complete DISM and SFC check..."
            }
            
            ; Update status
            statusText.Text := description
            progressBar.Value := 25
            
            ; Execute the command in a new command prompt window
            try {
                psCmd := '*RunAs powershell.exe -WindowStyle Normal -Command "Start-Process cmd -ArgumentList \"/k ' command '\" -Verb RunAs"'
                Run(psCmd)
                
                ; Update progress
                progressBar.Value := 100
                statusText.Text := "File integrity check launched in command prompt window."
                btnClose.Enabled := true
                btnClose.Focus()
                
                ; Show completion message
                SetTimer(() => (
                            ShowMouseTooltip("Windows File Integrity Check started in command prompt", 3000)
                ), -1000)
                
            } catch as e {
                SafeMsgBox("Error running integrity check: " e.Message, "Error", "Iconx")
                progressGui.Destroy()
            }
            
        } catch as e {
            SafeMsgBox("An error occurred: " e.Message, "Error", "Iconx")
            try {
                gui.Destroy()
            } catch {
                ; Ignore if already destroyed
            }
        }
    }
    
    ; Show help information
    ShowHelp() {
        helpText := "
(
Windows File Integrity Check Help
═══════════════════════════════════

Check Types:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

• Quick Check (DISM /ScanHealth)
  Fast scan for obvious corruption issues
  Recommended for: Regular maintenance
  Time: 1-5 minutes

• Full Check (DISM /CheckHealth)  
  Detailed analysis of system image health
  Recommended for: Investigating specific issues
  Time: 5-15 minutes

• Repair Check (DISM /RestoreHealth)
  Attempts to repair found issues automatically
  Downloads files from Windows Update if needed
  Recommended for: Fixing detected problems
  Time: 15-60 minutes

• SFC Scan (sfc /scannow)
  Scans and repairs Windows system files
  Uses local cache for repairs
  Recommended for: System file issues
  Time: 10-30 minutes

• Complete Check (DISM + SFC)
  Runs both DISM restore and SFC scan
  Most thorough option available
  Recommended for: Comprehensive system repair
  Time: 30-90 minutes


Requirements:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

• Administrator privileges required
• Internet connection recommended for repairs
• Sufficient disk space for temporary files
• System should not be busy with other tasks


Note: The check will run in a command prompt window
where you can monitor progress and see detailed results.
)"
        
        helpGui := Gui("+AlwaysOnTop", "Windows File Integrity - Help")
        helpGui.SetFont("s9", "Consolas")
        helpGui.BackColor := 0xF8F8F8
        
        helpGui.Add("Text", "x20 y20 w600", helpText)
        helpGui.Add("Button", "x275 y450 w100 h30", "OK").OnEvent("Click", (*) => helpGui.Destroy())
        
        helpGui.OnEvent("Escape", (*) => helpGui.Destroy())
        helpGui.Show("w640 h500")
    }
    
    ; Show plugin settings
    ShowSettings() {
        settingsGui := Gui("+AlwaysOnTop", "Windows File Integrity - Settings")
        settingsGui.SetFont("s10", "Segoe UI")
        
        settingsGui.Add("Text", "x20 y20", "Default Check Type:")
        
        options := ["Quick Check (DISM /ScanHealth)", "Full Check (DISM /CheckHealth)", "Repair Check (DISM /RestoreHealth)", "SFC Scan (sfc /scannow)", "Complete Check (DISM + SFC)"]
        defaultType := settingsGui.Add("DropDownList", "x20 y45 w300", options)
        defaultType.Choose(this.Settings["defaultCheckType"])
        
        showProgressCheck := settingsGui.Add("Checkbox", "x20 y80", "Show progress dialog")
        showProgressCheck.Value := this.Settings["showProgress"]
        
        ; Buttons
        saveBtn := settingsGui.Add("Button", "x20 y120 w80", "Save")
        saveBtn.OnEvent("Click", (*) => this.SaveSettings(settingsGui, defaultType, showProgressCheck))
        
        cancelBtn := settingsGui.Add("Button", "x110 y120 w80", "Cancel")
        cancelBtn.OnEvent("Click", (*) => settingsGui.Destroy())
        
        settingsGui.Show("w340 h170")
    }
    
    ; Save plugin settings
    SaveSettings(gui, defaultType, showProgressCheck) {
        this.Settings["defaultCheckType"] := defaultType.Value
        this.Settings["showProgress"] := showProgressCheck.Value
        
        ShowMouseTooltip("Settings saved", 1000)
        gui.Destroy()
    }
} 