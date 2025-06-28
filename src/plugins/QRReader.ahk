#Requires AutoHotkey v2.0-*

; QR Reader Plugin for AHK Tools
; This plugin captures screenshots and uses Python libraries to read QR codes

class QRReaderPlugin extends Plugin {
    ; Plugin metadata
    static Name := "QR Reader"
    static Description := "Ultra-fast QR code scanner with speed-optimized Python engines"
    static Version := "2.1.0"
    static Author := "AHK Tools"
    
    ; Plugin settings
    Settings := {
        enabled: true,
        tempImagePath: A_Temp "\qr_capture.png",
        copyToClipboard: true,
        playSoundOnDetection: true
    }
    
    ; GUI components
    GUI := ""
    IsScanning := false
    LastQRData := ""
    QRHistory := []  ; Array to store QR scan history
    
    ; Constructor
    __New() {
        super.__New()
        this.SetupPythonEnvironment()
    }
    
    ; Initialize the plugin
    Initialize() {
        this.Enabled := true
        try {
            Hotkey "!q", (*) => this.ShowQRScanner()      ; Alt+Q - Open QR Scanner
            Hotkey "^!q", (*) => this.ShowQRScanner()     ; Ctrl+Alt+Q - Open QR Scanner (legacy)
            Hotkey "^!w", (*) => this.QuickScreenScan()   ; Ctrl+Alt+W - Quick full screen scan
        } catch as e {
            ; Handle hotkey registration errors
        }
        
        ; Engine caching removed from startup - will only check when GUI opens or user requests
        
        return true
    }
    
    ; Check engines only when explicitly requested (GUI open or manual test)
    CheckEnginesOnDemand() {
        try {
            this.CacheAvailableEngines()
        } catch as e {
            ; If engine check fails, return error status
            return "Engine check failed: " e.Message
        }
        return "Engines checked successfully"
    }
    
    ; Enable the plugin
    Enable() {
        try {
            Hotkey "!q", "On"       ; Alt+Q
            Hotkey "^!q", "On"      ; Ctrl+Alt+Q
            Hotkey "^!w", "On"      ; Ctrl+Alt+W
            this.Enabled := true
        } catch as e {
            MsgBox("Error enabling QR Reader plugin: " e.Message, "Plugin Error", "Iconx")
            return false
        }
        return true
    }
    
    ; Disable the plugin
    Disable() {
        try {
            Hotkey "!q", "Off"      ; Alt+Q
            Hotkey "^!q", "Off"     ; Ctrl+Alt+Q
            Hotkey "^!w", "Off"     ; Ctrl+Alt+W
            this.Enabled := false
            
            ; Clear all performance-related flags and timers
            this.CleanupPerformanceResources()
        } catch as e {
            MsgBox("Error disabling QR Reader plugin: " e.Message, "Plugin Error", "Iconx")
            return false
        }
        return true
    }
    
    ; Cleanup performance resources to prevent memory leaks
    CleanupPerformanceResources() {
        ; Clear timer flags  
        this.DeleteProp("cachingInProgress")
        this.DeleteProp("cleanupTimerActive")
        
        ; Clear cleanup queue
        this.DeleteProp("cleanupQueue")
        
        ; Clear cached data
        this.DeleteProp("cachedEngines")
    }
    
    ; Setup Python environment for QR reading (lightweight during startup)
    SetupPythonEnvironment() {
        ; Skip expensive Python checks during startup to reduce CPU spike
        ; Python availability will be checked when actually needed
        return
    }
    
    ; Check if Python is available (preferring virtual environment)
    CheckPythonAvailability() {
        ; First try virtual environment in various locations
        venvPaths := [
            A_ScriptDir "\qr_venv\Scripts\python.exe",  ; Same directory as script
            A_ScriptDir "\..\qr_venv\Scripts\python.exe",  ; Project root from src/
            A_WorkingDir "\qr_venv\Scripts\python.exe"   ; Working directory
        ]
        
        for path in venvPaths {
            if (FileExist(path)) {
                return true
            }
        }
        
        ; Fallback to system Python
        pythonCommands := ["python", "py", "python3"]
        
        for cmd in pythonCommands {
            try {
                RunWait(cmd ' --version', , "Hide", &output)
                if (InStr(output, "Python")) {
                    return true
                }
            } catch {
                continue
            }
        }
        return false
    }
    
    ; Get the best Python command to use
    GetPythonCommand() {
        ; First try virtual environment in various locations
        venvPaths := [
            A_ScriptDir "\qr_venv\Scripts\python.exe",  ; Same directory as script
            A_ScriptDir "\..\qr_venv\Scripts\python.exe",  ; Project root from src/
            A_WorkingDir "\qr_venv\Scripts\python.exe"   ; Working directory
        ]
        
        for path in venvPaths {
            if (FileExist(path)) {
                return '"' path '"'
            }
        }
        
        ; Fallback to system Python
        pythonCommands := ["python", "py", "python3"]
        
        for cmd in pythonCommands {
            try {
                RunWait(cmd ' --version', , "Hide", &output)
                if (InStr(output, "Python")) {
                    return cmd
                }
            } catch {
                continue
            }
        }
        return "python"  ; Default fallback
    }
    

    
    ; Show QR Scanner GUI (instant loading with modern design)
    ShowQRScanner() {
        if (IsObject(this.GUI))
            this.GUI.Destroy()
            
        this.GUI := Gui("+AlwaysOnTop -Resize -MaximizeBox", "QR Scanner v2.1 - Ultra Fast")
        this.GUI.SetFont("s10", "Segoe UI")
        this.GUI.BackColor := "White"
        
        ; Modern header section
        headerBg := this.GUI.Add("Text", "x0 y0 w540 h80 Background0x2563EB")
        this.GUI.Add("Text", "x0 y15 w540 Center c0xFFFFFF Background0x2563EB", "⚡ Ultra-Fast QR Scanner").SetFont("s12 Bold")
        statusText := this.GUI.Add("Text", "x0 y45 w540 Center c0xE5E7EB Background0x2563EB", "Ready - Select scan method")
        statusText.SetFont("s9")
        
        ; Main action buttons with better spacing
        this.GUI.Add("Text", "x20 y95 w500", "Choose scan method:").SetFont("s10 Bold")
        this.GUI.Add("Button", "x20 y120 w240 h50", "🖥️ Full Screen Scan").OnEvent("Click", (*) => this.StartScanWithDebug("fullscreen"))
        this.GUI.Add("Button", "x280 y120 w240 h50", "📁 Image File Scan").OnEvent("Click", (*) => this.StartScanWithDebug("file"))
        
        ; Engine status section with modern styling
        this.GUI.Add("Text", "x20 y185 w500", "Engine Status:").SetFont("s10 Bold")
        engineStatus := this.GUI.Add("Edit", "x20 y205 w500 h65 ReadOnly VScroll")
        engineStatus.Text := "🔄 Loading engine status..."
        
        ; Settings section
        this.GUI.Add("Text", "x20 y285 w500", "Settings:").SetFont("s10 Bold")
        settingsGroup := this.GUI.Add("GroupBox", "x20 y305 w500 h45", "")
        clipboardCheck := this.GUI.Add("Checkbox", "x35 y320", "📋 Auto-copy to clipboard")
        clipboardCheck.Value := this.Settings.copyToClipboard
        soundCheck := this.GUI.Add("Checkbox", "x280 y320", "🔊 Play sound on detection")
        soundCheck.Value := this.Settings.playSoundOnDetection
        
        ; History section with better layout
        this.GUI.Add("Text", "x20 y365 w300", "Scan History:").SetFont("s10 Bold")
        this.GUI.Add("Button", "x420 y362 w100 h25", "📋 View All").OnEvent("Click", (*) => this.ShowDetailedHistory())
        resultEdit := this.GUI.Add("Edit", "x20 y390 w500 h75 ReadOnly VScroll")
        resultEdit.Text := this.GetQRHistoryText()
        
        ; External Debug Window controls
        this.GUI.Add("Text", "x20 y480 w300", "Debug Information:").SetFont("s10 Bold")
        this.GUI.Add("Button", "x20 y505 w120 h30", " Debug ").OnEvent("Click", (*) => this.ToggleDebugWindow())
        this.GUI.Add("Button", "x150 y505 w100 h30", "🧹 Clear Log").OnEvent("Click", (*) => this.ClearDebugLog())
        
        ; Status display (replaces the small debug log)
        debugStatus := this.GUI.Add("Text", "x260 y510 w260 h20 Center", "⚡ QR Scanner ready - engines will be checked when GUI opens")
        debugStatus.SetFont("s9")
        
        ; Modern bottom button bar
        buttonBg := this.GUI.Add("Text", "x0 y595 w540 h55 Background0xF3F4F6")
        this.GUI.Add("Button", "x20 y610 w80 h30", "🔧 Install").OnEvent("Click", (*) => this.InstallPythonEngines())
        this.GUI.Add("Button", "x110 y610 w60 h30", "🔍 Test").OnEvent("Click", (*) => this.RunDiagnostics())
        this.GUI.Add("Button", "x180 y610 w60 h30", "❓ Help").OnEvent("Click", (*) => this.ShowHelp())
        this.GUI.Add("Button", "x250 y610 w110 h30", "🗑️ Clear History").OnEvent("Click", (*) => this.ClearQRHistory())
        this.GUI.Add("Button", "x450 y610 w70 h30", "❌ Close").OnEvent("Click", (*) => this.CleanupAndDestroy())
        
        ; Store references
        this.GUI.statusText := statusText
        this.GUI.engineStatus := engineStatus
        this.GUI.debugStatus := debugStatus
        this.GUI.resultEdit := resultEdit
        this.GUI.clipboardCheck := clipboardCheck
        this.GUI.soundCheck := soundCheck
        
        this.GUI.OnEvent("Close", (*) => this.CleanupAndDestroy())
        this.GUI.OnEvent("Escape", (*) => this.CleanupAndDestroy())
        
        ; Show GUI instantly with proper size
        this.GUI.Show("w540 h650")
        
        ; Check engines when GUI is opened (user-initiated)
        SetTimer(() => this.UpdateGUIEngineStatusOnOpen(), -1000)
        
        ; Generate some initial debug output
        this.LogDebug("🚀 QR Scanner GUI opened")
        this.LogDebug("⏳ Engine status check will begin in 1 second...")
    }
    
    ; Create or toggle external debug window
    ToggleDebugWindow() {
        if (this.HasProp("DebugGUI") && IsObject(this.DebugGUI)) {
            ; Window exists, toggle visibility
            try {
                if (this.DebugGUI.Visible) {
                    this.DebugGUI.Hide()
                } else {
                    this.DebugGUI.Show()
                    this.DebugGUI.Move(, , , , "NoActivate")  ; Show without stealing focus
                }
            } catch {
                ; If error (window destroyed), create new one
                this.CreateDebugWindow()
            }
        } else {
            ; Create new debug window
            this.CreateDebugWindow()
        }
    }
    
    ; Create external debug window with professional light theme
    CreateDebugWindow() {
        try {
            ; Create debug window with modern styling
            this.DebugGUI := Gui("+Resize +MaximizeBox +MinimizeBox", "🐛 QR Reader Debug Console")
            this.DebugGUI.BackColor := "0xF8F9FA"  ; Professional light background
            this.DebugGUI.MarginX := 0
            this.DebugGUI.MarginY := 0
            
            ; Calculate position relative to main window  
            try {
                mainPos := this.GUI.Pos
                mainX := mainPos.X
                mainY := mainPos.Y
                mainWidth := mainPos.Width
            } catch {
                ; Fallback if main GUI position unavailable
                mainX := A_ScreenWidth // 4
                mainY := A_ScreenHeight // 4
                mainWidth := 540
            }
            
            ; Position debug window to the right of main window
            debugX := mainX + mainWidth + 10
            debugY := mainY
            debugWidth := 900
            debugHeight := 650
            
            ; Ensure window stays on screen
            if (debugX + debugWidth > A_ScreenWidth) {
                debugX := mainX - debugWidth - 10  ; Position to the left instead
                if (debugX < 0) {
                    debugX := 50  ; Fallback position
                }
            }
            
            ; Professional header bar with clean light styling
            headerBg := this.DebugGUI.Add("Text", "x0 y0 w" debugWidth " h45 Background0xE9ECEF")
            
            ; Title with proper contrast
            title := this.DebugGUI.Add("Text", "x15 y12 w" (debugWidth-120) " h20", "🐛 QR Reader Debug Console")
            title.SetFont("s11 Bold", "Segoe UI")
            title.Opt("c0x212529 Background0xE9ECEF")  ; Dark text on light background
            
            ; Subtitle
            subtitle := this.DebugGUI.Add("Text", "x15 y30 w" (debugWidth-120) " h12", "Enhanced Readability Mode - Real-time Debug Output")
            subtitle.SetFont("s8", "Segoe UI")
            subtitle.Opt("c0x6C757D Background0xE9ECEF")  ; Subtle gray text
            
            ; Modern control buttons with better styling
            testBtn := this.DebugGUI.Add("Button", "x" (debugWidth-125) " y8 w35 h28", "🧪")
            testBtn.SetFont("s9")
            testBtn.OnEvent("Click", (*) => this.TestDebugOutput())
            testBtn.ToolTip := "Test Debug Output"
            
            clearBtn := this.DebugGUI.Add("Button", "x" (debugWidth-85) " y8 w35 h28", "🧹")
            clearBtn.SetFont("s9")
            clearBtn.OnEvent("Click", (*) => this.ClearDebugLog())
            clearBtn.ToolTip := "Clear Debug Log"
            
            closeBtn := this.DebugGUI.Add("Button", "x" (debugWidth-45) " y8 w35 h28", "❌")
            closeBtn.SetFont("s9")
            closeBtn.OnEvent("Click", (*) => this.DebugGUI.Hide())
            closeBtn.ToolTip := "Hide Debug Window"
            
            ; Main debug log area with professional light theme and proper word wrapping
            this.DebugLogEdit := this.DebugGUI.Add("Edit", "x8 y53 w" (debugWidth-16) " h" (debugHeight-61) " ReadOnly VScroll Wrap")
            this.DebugLogEdit.SetFont("s10", "Consolas")  ; Professional monospace font
            this.DebugLogEdit.Opt("c0x212529 Background0xFFFFFF")  ; Clean colors: dark text on white background
            
            ; Initialize with clean, spaced welcome message
            welcomeMsg := "`r`n`r`n"
            welcomeMsg .= "═══════════════════════════════════════════════════════════════════════════════════════════════`r`n"
            welcomeMsg .= "`r`n"
            welcomeMsg .= "        🐛  QR READER DEBUG CONSOLE  -  ENHANCED READABILITY MODE  🐛`r`n"
            welcomeMsg .= "`r`n"
            welcomeMsg .= "═══════════════════════════════════════════════════════════════════════════════════════════════`r`n"
            welcomeMsg .= "`r`n`r`n"
            welcomeMsg .= "📅  SESSION STARTED: " FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") "`r`n`r`n"
            welcomeMsg .= "🔧  PURPOSE: Real-time debugging and troubleshooting information`r`n`r`n"
            welcomeMsg .= "📊  FEATURES: Color-coded messages, millisecond timestamps, smart formatting`r`n`r`n"
            welcomeMsg .= "⚡  PERFORMANCE: Non-blocking updates, auto-scroll, intelligent line wrapping`r`n`r`n"
            welcomeMsg .= "═══════════════════════════════════════════════════════════════════════════════════════════════`r`n"
            welcomeMsg .= "`r`n`r`n"
            welcomeMsg .= "✅  CONSOLE READY - Waiting for QR Reader operations...`r`n`r`n`r`n"
            
            this.DebugLogEdit.Text := welcomeMsg
            
            ; Handle window events
            this.DebugGUI.OnEvent("Close", (*) => this.DebugGUI.Hide())
            this.DebugGUI.OnEvent("Size", (*) => this.ResizeDebugWindow())
            
            ; Show window with professional appearance
            this.DebugGUI.Show("x" debugX " y" debugY " w" debugWidth " h" debugHeight " NoActivate")
            
            ; Add initial test message to verify logging works
            SetTimer(() => this.TestDebugOutput(), -500)
            
        } catch as e {
            ; If debug window creation fails, show error
            ShowMouseTooltip("Debug window creation failed: " e.Message, 3000)
        }
    }
    
    ; Test debug output to verify the window is working
    TestDebugOutput() {
        this.LogDebugSeparator()
        this.LogDebug("🧪 DEBUG OUTPUT TEST - " FormatTime(A_Now, "HH:mm:ss"))
        this.LogDebug("🔧 Debug window initialized and ready")
        this.LogDebug("")
        this.LogDebug("⚡ Testing message formatting with different types:")
        this.LogDebug("")
        this.LogDebug("✅ Success message example - this should appear with green indicator")
        this.LogDebug("❌ Error message example - this should appear with red indicator") 
        this.LogDebug("🚀 Process start example - this should appear with blue indicator")
        this.LogDebug("📦 Info message example - this should appear with brown indicator")
        this.LogDebug("💥 Exception example - this should appear with orange indicator")
        this.LogDebug("🔄 Process indicator example - this should appear with purple indicator")
        this.LogDebug("")
        this.LogDebug("📂 File operation example:")
        this.LogDebug("    Processing image: C:\\Very\\Long\\Path\\To\\Some\\Image\\File\\That\\Demonstrates\\Line\\Wrapping\\Functionality.png")
        this.LogDebug("")
        this.LogDebug("💡 Debug logging system is working correctly! All message types formatted and displayed.")
        this.LogDebugSeparator()
    }
    
    ; Handle debug window resizing with professional layout
    ResizeDebugWindow() {
        try {
            if (!this.HasProp("DebugGUI") || !IsObject(this.DebugGUI) || !this.HasProp("DebugLogEdit"))
                return
                
            ; Get current window size
            winPos := this.DebugGUI.Pos
            
            ; Resize debug log to fill available space (accounting for header)
            this.DebugLogEdit.Move(8, 53, winPos.Width - 16, winPos.Height - 61)
            
            ; Resize header background to full width
            try {
                for hwnd, control in this.DebugGUI {
                    if (control.Type = "Text" && control.BackColor = "0xE9ECEF") {
                        ; Check if it's the header background (first one found)
                        control.Move(0, 0, winPos.Width, 45)
                        break
                    }
                }
            } catch {
                ; Ignore header resize errors
            }
            
            ; Reposition buttons to stay in top-right corner
            try {
                for hwnd, control in this.DebugGUI {
                    if (control.Type = "Button") {
                        if (InStr(control.Text, "❌")) {
                            control.Move(winPos.Width - 45, 8)
                        } else if (InStr(control.Text, "🧹")) {
                            control.Move(winPos.Width - 85, 8)
                        } else if (InStr(control.Text, "🧪")) {
                            control.Move(winPos.Width - 125, 8)
                        }
                    }
                }
            } catch {
                ; Ignore button repositioning errors
            }
            
            ; Resize title and subtitle to match new width
            try {
                for hwnd, control in this.DebugGUI {
                    if (control.Type = "Text" && InStr(control.Text, "QR Reader Debug Console")) {
                        control.Move(15, 12, winPos.Width - 120, 20)
                    } else if (control.Type = "Text" && InStr(control.Text, "Enhanced Readability Mode")) {
                        control.Move(15, 30, winPos.Width - 120, 12)
                    }
                }
            } catch {
                ; Ignore text resize errors
            }
            
        } catch {
            ; Silently ignore resize errors
        }
    }
    
    ; Update GUI engine status when GUI is opened (user-initiated check)
    UpdateGUIEngineStatusOnOpen() {
        ; Improved safety check for GUI controls
        if (!IsObject(this.GUI) || !this.GUI.HasProp("engineStatus") || !IsObject(this.GUI.engineStatus))
            return
            
        try {
            ; Quick status update
            if (this.GUI.HasProp("statusText") && IsObject(this.GUI.statusText)) {
                this.GUI.statusText.Text := "Checking engines..."
            }
            
            ; Check engines since user opened GUI (this is user-initiated)
            this.CheckEnginesOnDemand()
            
            ; Update engine status display
            engineStatus := this.GetEngineStatusFast()
            this.GUI.engineStatus.Text := engineStatus
            
            ; Update debug status with engine count
            engineCount := this.CountAvailableEnginesFast()
            if (this.GUI.HasProp("debugStatus") && IsObject(this.GUI.debugStatus)) {
                this.GUI.debugStatus.Text := "engines checked: " engineCount " engines available"
            }
            
            ; Update status
            if (this.GUI.HasProp("statusText") && IsObject(this.GUI.statusText)) {
                this.GUI.statusText.Text := "Ready - " engineCount " engines available"
            }
            
            ; Log successful engine check
            this.LogDebug("✅ Engine check completed: " engineCount " engines available")
            
        } catch as e {
            ; If engine check fails, show error but keep GUI working
            try {
                if (IsObject(this.GUI) && this.GUI.HasProp("engineStatus") && IsObject(this.GUI.engineStatus)) {
                    this.GUI.engineStatus.Text := "Error checking engines - click Test for details"
                }
                if (IsObject(this.GUI) && this.GUI.HasProp("statusText") && IsObject(this.GUI.statusText)) {
                    this.GUI.statusText.Text := "Ready - Engine status unknown"
                }
            } catch {
                ; Silently ignore if GUI is completely destroyed
            }
        }
    }
    
    ; Update GUI engine status display only (no checks - uses cache)
    UpdateGUIEngineStatus() {
        ; Improved safety check for GUI controls
        if (!IsObject(this.GUI) || !this.GUI.HasProp("engineStatus") || !IsObject(this.GUI.engineStatus))
            return
            
        try {
            ; Update engine status display from cache only
            engineStatus := this.GetEngineStatusFast()
            this.GUI.engineStatus.Text := engineStatus
            
            ; Update debug log with engine count
            engineCount := this.CountAvailableEnginesFast()
            
            ; Update status
            if (this.GUI.HasProp("statusText") && IsObject(this.GUI.statusText)) {
                this.GUI.statusText.Text := "Ready - " engineCount " engines available"
            }
            
        } catch as e {
            ; If display update fails, show error but keep GUI working
            try {
                if (IsObject(this.GUI) && this.GUI.HasProp("engineStatus") && IsObject(this.GUI.engineStatus)) {
                    this.GUI.engineStatus.Text := "Error updating display - click Test for details"
                }
                if (IsObject(this.GUI) && this.GUI.HasProp("statusText") && IsObject(this.GUI.statusText)) {
                    this.GUI.statusText.Text := "Ready - Engine status unknown"
                }
            } catch {
                ; Silently ignore if GUI is completely destroyed
            }
        }
    }
    
    ; Start scan with debug logging
    StartScanWithDebug(scanType) {
        this.UpdateSettings()
        this.LogDebugSeparator()
        this.LogDebug("🚀 Starting " scanType " scan")
        this.LogDebug("⚙️ Scan type: " (scanType = "fullscreen" ? "Full Screen Capture" : "Image File Selection"))
        this.UpdateStatus("Preparing scan...")
        
        switch scanType {
            case "fullscreen": 
                this.LogDebug("🖥️ Initiating full screen capture...")
                this.ScanFullScreen()
            case "file":
                this.LogDebug("📁 Opening file selection dialog...")
                this.ScanImageFile()
        }
    }
    
    ; Add visual separator to debug log (enhanced for external debug window)
    LogDebugSeparator() {
        ; Enhanced separator for external debug window
        separator := "─────────────────────────────────────────────────────────────────────────────"
        this.LogDebug(separator)
        
        ; Legacy support for internal debug log (if still used)
        try {
            if (IsObject(this.GUI) && this.GUI.HasProp("debugLog") && IsObject(this.GUI.debugLog)) {
                currentLog := this.GUI.debugLog.Text
                legacySeparator := "─────────────────────────────────────────"
                newLog := currentLog "`r`n" legacySeparator
                this.GUI.debugLog.Text := newLog
            }
        } catch {
            ; Silently ignore errors when GUI controls are destroyed
        }
    }
    
    ; Get engine status (may be slow on first call)
    GetEngineStatus() {
        status := ""
        engines := ["pyzbar", "zxing-cpp", "OpenCV"]
        
        for engine in engines {
            available := this.CheckEngineAvailable(engine)
            status .= engine ": " (available ? "✅ Available" : "❌ Missing") "`r`n"
        }
        
        return RTrim(status, "`r`n")  ; Remove trailing newline
    }
    
    ; Get engine status fast (uses cache only - no automatic checks)
    GetEngineStatusFast() {
        ; Use cached data if available
        if (this.HasProp("cachedEngines")) {
            status := ""
            for engine, available in this.cachedEngines {
                status .= engine ": " (available ? "✅ Available" : "❌ Missing") "`r`n"
            }
            return RTrim(status, "`r`n")  ; Remove trailing newline
        }
        
        ; Return instruction to manually check if no cache exists
        return "Engines: ❓ Click 'Test' button to check availability"
    }
    
    ; Check if specific engine is available
    CheckEngineAvailable(engine) {
        switch engine {
            case "pyzbar":
                return this.CheckPythonPackage("pyzbar")
            case "zxing-cpp":
                return this.CheckPythonPackage("zxingcpp")
            case "OpenCV":
                return this.CheckPythonPackage("cv2")
            default:
                return false
        }
    }
    
    ; Check Python package availability (using virtual environment first)
    CheckPythonPackage(packageName) {
        pythonCmd := this.GetPythonCommand()
        
        try {
            ; Use the same batch file approach as diagnostics for reliability
            tempBat := A_Temp "\qr_check_" A_TickCount ".bat"
            tempOut := A_Temp "\qr_check_output_" A_TickCount ".txt"
            
            ; Create batch file with timeout protection
            batContent := "@echo off`n"
            batContent .= "timeout /t 15 /nobreak > nul 2>&1`n"  ; 15 second hard timeout
            batContent .= pythonCmd ' -c "import ' packageName '; print(\"OK\")" > "' tempOut '" 2>&1`n'
            FileAppend(batContent, tempBat)
            
            ; Run with limited time
            exitCode := RunWait('"' tempBat '"', , "Hide")
            
            ; Read the output file
            result := ""
            if (FileExist(tempOut)) {
                result := FileRead(tempOut)
                FileDelete(tempOut)
            }
            FileDelete(tempBat)
            
            if (InStr(result, "OK")) {
                return true
            }
        } catch {
            ; If batch file approach fails, try direct fallback with timeout
            pythonCommands := ["python", "py", "python3"]
            
            for cmd in pythonCommands {
                try {
                    tempBat := A_Temp "\qr_fallback_" A_TickCount ".bat"
                    tempOut := A_Temp "\qr_fallback_output_" A_TickCount ".txt"
                    
                    batContent := "@echo off`n"
                    batContent .= "timeout /t 10 /nobreak > nul 2>&1`n"  ; 10 second timeout for fallback
                    batContent .= cmd ' -c "import ' packageName '; print(\"OK\")" > "' tempOut '" 2>&1`n'
                    FileAppend(batContent, tempBat)
                    
                    ; Run fallback with timeout
                    exitCode := RunWait('"' tempBat '"', , "Hide")
                    
                    result := ""
                    if (FileExist(tempOut)) {
                        result := FileRead(tempOut)
                        FileDelete(tempOut)
                    }
                    FileDelete(tempBat)
                    
                    if (InStr(result, "OK")) {
                        return true
                    }
                } catch {
                    continue
                }
            }
        }
        return false
    }
    

    
    ; Count available engines (may be slow)
    CountAvailableEngines() {
        count := 0
        engines := ["pyzbar", "zxing-cpp", "OpenCV"]
        
        for engine in engines {
            if (this.CheckEngineAvailable(engine))
                count++
        }
        
        return count "/3"
    }
    
    ; Count available engines fast (uses cache only - no background checks)
    CountAvailableEnginesFast() {
        ; Use cached data if available
        if (this.HasProp("cachedEngines")) {
            count := 0
            for engine, available in this.cachedEngines {
                if (available)
                    count++
            }
            return count "/3"
        }
        
        ; Return unknown status if no cache (user must manually check)
        return "0/3 (click Test to check)"
    }
    
    ; Update status text
    UpdateStatus(text) {
        try {
            if (IsObject(this.GUI) && this.GUI.HasProp("statusText") && IsObject(this.GUI.statusText))
                this.GUI.statusText.Text := text
        } catch {
            ; Silently ignore errors when GUI controls are destroyed
        }
    }
    
    ; Log debug message to external debug window with excellent formatting
    LogDebug(message) {
        ; Skip empty messages unless they're intentional spacers
        if (message = "" || message = " ") {
            ; Write to external debug window if available
            try {
                if (this.HasProp("DebugLogEdit") && IsObject(this.DebugLogEdit)) {
                    currentLog := this.DebugLogEdit.Text
                    newLog := currentLog "`r`n"
                    this.DebugLogEdit.Text := newLog
                }
            } catch {
                ; Silently ignore errors when debug window is not available
            }
            return
        }
        
        timestamp := FormatTime(A_Now, "HH:mm:ss.fff")
        
        ; Enhanced message formatting for external window
        formattedMessage := this.FormatDebugMessageExternal(message)
        
        ; Better timestamp formatting with new line separation (using \r\n for Edit control)
        logEntry := "⏰ " timestamp "`r`n" formattedMessage
        
        ; Write to external debug window if available
        try {
            if (this.HasProp("DebugLogEdit") && IsObject(this.DebugLogEdit)) {
                currentLog := this.DebugLogEdit.Text
                
                ; Add better spacing between messages for improved readability
                spacing := this.GetMessageSpacing(message, currentLog)
                newLog := currentLog . spacing . logEntry
                this.DebugLogEdit.Text := newLog
                
                ; Auto-scroll to bottom without stealing focus
                try {
                    DllCall("User32.dll\SendMessage", "Ptr", this.DebugLogEdit.Hwnd, "UInt", 0x00B1, "Ptr", -1, "Ptr", -1)
                    DllCall("User32.dll\SendMessage", "Ptr", this.DebugLogEdit.Hwnd, "UInt", 0x00B7, "Ptr", 0, "Ptr", 0)
                } catch {
                    ; Fallback to no scrolling if DLL call fails
                }
            }
        } catch {
            ; Silently ignore errors when debug window is not available
        }
        
        ; Also update status in main GUI if it's a key status message
        try {
            if (this.IsKeyStatusMessage(message) && IsObject(this.GUI) && this.GUI.HasProp("debugStatus") && IsObject(this.GUI.debugStatus)) {
                this.GUI.debugStatus.Text := this.ExtractStatusFromMessage(message)
            }
        } catch {
            ; Silently ignore main GUI update errors
                 }
    }
    
    ; Determine appropriate spacing between debug messages for better readability
    GetMessageSpacing(message, currentLog) {
        ; If log is empty or ends with separator, use single newline
        if (!currentLog || InStr(currentLog, "═══════════════════════════════════════") > StrLen(currentLog) - 100) {
            return "`r`n"
        }
        
        ; Major section breaks (separators, diagnostics, major events) get lots of space
        if (InStr(message, "═══") || InStr(message, "DIAGNOSTICS") || InStr(message, "DEBUG OUTPUT TEST") || 
            InStr(message, "COMPLETE") || InStr(message, "Session Started")) {
            return "`r`n`r`n`r`n"
        }
        
        ; Long separator lines get extra space
        if (InStr(message, "─────────────────────────────────────────────────────")) {
            return "`r`n`r`n"
        }
        
        ; Operation start messages get lots of spacing
        if (InStr(message, "🚀") && (InStr(message, "Starting") || InStr(message, "Processing") || InStr(message, "Running"))) {
            return "`r`n`r`n`r`n"
        }
        
        ; Success/Error completion messages get lots of spacing  
        if ((InStr(message, "✅") || InStr(message, "❌")) && 
            (InStr(message, "completed") || InStr(message, "failed") || InStr(message, "SUCCESS") || InStr(message, "working"))) {
            return "`r`n`r`n"
        }
        
        ; Engine status messages get extra spacing
        if (InStr(message, "📦") && (InStr(message, "Testing") || InStr(message, "checking") || InStr(message, "engines available"))) {
            return "`r`n`r`n"
        }
        
        ; File operations get extra spacing
        if (InStr(message, "📁") || InStr(message, "📂") || InStr(message, "📷") || InStr(message, "📸")) {
            return "`r`n`r`n"
        }
        
        ; Time/performance measurements get spacing
        if (InStr(message, "Time:") || InStr(message, "ms") || InStr(message, "Size:")) {
            return "`r`n`r`n"
        }
        
        ; Sub-messages (indented with spaces) get less spacing
        if (RegExMatch(message, "^\s{2,}")) {
            return "`r`n"
        }
        
        ; Regular messages get double line break for breathing room
        return "`r`n`r`n"
    }
    
    ; Enhanced debug message formatting for external window
    FormatDebugMessageExternal(message) {
        ; Add visual indicators and better formatting for different message types
        if (InStr(message, "✅")) {
            return "🟢 SUCCESS: " StrReplace(message, "✅ ", "")  ; Success indicator
        }
        else if (InStr(message, "❌")) {
            return "🔴 ERROR: " StrReplace(message, "❌ ", "")  ; Error indicator
        }
        else if (InStr(message, "⚡")) {
            return "🟡 ACTION: " StrReplace(message, "⚡ ", "")  ; Action indicator
        }
        else if (InStr(message, "🚀")) {
            return "🔵 START: " StrReplace(message, "🚀 ", "")  ; Process start indicator
        }
        else if (InStr(message, "💥")) {
            return "🟠 EXCEPTION: " StrReplace(message, "💥 ", "")  ; Exception indicator
        }
        else if (InStr(message, "🔄")) {
            return "🟣 PROCESS: " StrReplace(message, "🔄 ", "")  ; Process indicator
        }
        else if (InStr(message, "📦") || InStr(message, "🐍") || InStr(message, "📂")) {
            return "🟤 INFO: " message  ; Info indicator
        }
        else if (InStr(message, "DIAGNOSTICS") || InStr(message, "COMPLETE")) {
            return "⚪ EVENT: " message  ; Major event indicator
        }
        else if (InStr(message, "🧪")) {
            return "🟦 TEST: " StrReplace(message, "🧪 ", "")  ; Test indicator
        }
        
        ; Break long lines for better readability in external window
        if (StrLen(message) > 80) {
            ; Handle different message types with proper line breaks
            if (InStr(message, "Raw JSON received:")) {
                parts := StrSplit(message, "Raw JSON received: ", , 2)
                if (parts.Length >= 2) {
                    return parts[1] "Raw JSON received:`r`n      " parts[2]
                }
            }
            else if (InStr(message, "Running:") || InStr(message, "Creating:")) {
                return StrReplace(message, "Running:", "Running:`r`n      ")
            }
            else if (InStr(message, "Processing image:")) {
                return StrReplace(message, "Processing image:", "Processing image:`r`n      ")
            }
            else if (InStr(message, "File selected:")) {
                return StrReplace(message, "File selected:", "File selected:`r`n      ")
            }
            else if (InStr(message, "Project root:")) {
                return StrReplace(message, "Project root:", "Project root:`r`n      ")
            }
            else if (InStr(message, "Virtual environment:")) {
                return StrReplace(message, "Virtual environment:", "Virtual environment:`r`n      ")
            }
            else if (InStr(message, "Exit code:") && InStr(message, "output:")) {
                parts := StrSplit(message, ", output: ", , 2)
                if (parts.Length >= 2) {
                    return parts[1] "`r`n      Output: " parts[2]
                }
            }
            else if (StrLen(message) > 80) {
                ; Generic long message formatting
                words := StrSplit(message, " ")
                result := ""
                currentLine := ""
                
                for word in words {
                    if (StrLen(currentLine " " word) > 80 && currentLine != "") {
                        result .= (result ? "`r`n      " : "") currentLine
                        currentLine := word
                    } else {
                        currentLine .= (currentLine ? " " : "") word
                    }
                }
                
                if (currentLine) {
                    result .= (result ? "`r`n      " : "") currentLine
                }
                
                return result
            }
        }
        
        return message
    }
    
    ; Check if a debug message should update the main GUI status
    IsKeyStatusMessage(message) {
        keyIndicators := [
            "Engine check completed",
            "engines available",
            "DIAGNOSTICS COMPLETE",
            "Ready -",
            "Scanning with",
            "QR found",
            "No QR code found",
            "Installation successful",
            "Installation failed"
        ]
        
        for indicator in keyIndicators {
            if (InStr(message, indicator)) {
                return true
            }
        }
        
        return false
    }
    
    ; Extract status text from debug message for main GUI
    ExtractStatusFromMessage(message) {
        if (InStr(message, "Engine check completed")) {
            if (RegExMatch(message, "(\d+) engines available", &match)) {
                return "Ready - " match[1] " engines available"
            }
        }
        else if (InStr(message, "DIAGNOSTICS COMPLETE")) {
            return "Diagnostics completed"
        }
        else if (InStr(message, "Scanning with")) {
            if (RegExMatch(message, "Scanning with (\w+)", &match)) {
                return "Scanning with " match[1] "..."
            }
        }
        else if (InStr(message, "QR found")) {
            return "QR code detected!"
        }
        else if (InStr(message, "No QR code found")) {
            return "No QR code found"
        }
        else if (InStr(message, "Installation successful")) {
            return "Installation completed"
        }
        else if (InStr(message, "Installation failed")) {
            return "Installation failed"
        }
        
        ; Default: truncate message for status display
        return SubStr(message, 1, 40) (StrLen(message) > 40 ? "..." : "")
    }
    
    ; Format debug messages for better readability
    FormatDebugMessage(message) {
        ; Break long lines at logical points
        if (StrLen(message) <= 50) {
            return message
        }
        
        ; Handle different message types with proper line breaks
        if (InStr(message, "Raw JSON received:")) {
            ; Format JSON messages
            parts := StrSplit(message, "Raw JSON received: ", , 2)
            if (parts.Length >= 2) {
                jsonPart := parts[2]
                return parts[1] "Raw JSON received:`n    " jsonPart
            }
        }
        else if (InStr(message, "Running batch:") || InStr(message, "Creating batch:")) {
            ; Format batch file messages
            return StrReplace(message, "Running batch:", "Running batch:`n    ")
        }
        else if (InStr(message, "Processing image:")) {
            ; Format image path messages
            return StrReplace(message, "Processing image:", "Processing image:`n    ")
        }
        else if (InStr(message, "File selected:")) {
            ; Format file selection messages
            return StrReplace(message, "File selected:", "File selected:`n    ")
        }
        else if (InStr(message, "Exit code:") && InStr(message, "output:")) {
            ; Format command output messages
            parts := StrSplit(message, ", output: ", , 2)
            if (parts.Length >= 2) {
                return parts[1] "`n    Output: " parts[2]
            }
        }
        else if (InStr(message, "Time:") && InStr(message, "Size:")) {
            ; Format timing and size info
            message := StrReplace(message, ", Size:", "`n    Size:")
            return message
        }
        else if (InStr(message, "Data length:") && InStr(message, "Content:")) {
            ; Format result info
            message := StrReplace(message, ", Content:", "`n    Content:")
            return message
        }
        else if (InStr(message, "SUCCESS with") || InStr(message, "FAST SUCCESS")) {
            ; Keep success messages on one line but break details
            if (InStr(message, "Data length:")) {
                message := StrReplace(message, "Data length:", "`n    Data length:")
            }
            return message
        }
        else if (StrLen(message) > 50) {
            ; Generic long message formatting - break at word boundaries
            words := StrSplit(message, " ")
            result := ""
            currentLine := ""
            
            for word in words {
                if (StrLen(currentLine " " word) > 50 && currentLine != "") {
                    result .= (result ? "`n    " : "") currentLine
                    currentLine := word
                } else {
                    currentLine .= (currentLine ? " " : "") word
                }
            }
            
            if (currentLine) {
                result .= (result ? "`n    " : "") currentLine
            }
            
            return result
        }
        
        return message
    }
    
    ; Clear debug log in external window
    ClearDebugLog() {
        try {
            if (this.HasProp("DebugLogEdit") && IsObject(this.DebugLogEdit)) {
                ; Reset to professional welcome message
                welcomeMsg := "═══════════════════════════════════════════════════════════════════════════════════════════════`n"
                welcomeMsg .= "  🐛  QR READER DEBUG CONSOLE  -  ENHANCED READABILITY MODE  🐛`n"
                welcomeMsg .= "═══════════════════════════════════════════════════════════════════════════════════════════════`n"
                welcomeMsg .= "📅 Log Cleared: " FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") "`n"
                welcomeMsg .= "🔧 Purpose: Real-time debugging and troubleshooting information`n"
                welcomeMsg .= "📊 Features: Color-coded messages, millisecond timestamps, smart formatting`n"
                welcomeMsg .= "⚡ Performance: Non-blocking updates, auto-scroll, intelligent line wrapping`n"
                welcomeMsg .= "═══════════════════════════════════════════════════════════════════════════════════════════════`n"
                welcomeMsg .= "`n✅ Console cleared and ready - waiting for QR Reader operations...`n`n"
                
                this.DebugLogEdit.Text := welcomeMsg
                ; Don't call LogDebug here as it would create a loop
                ShowMouseTooltip("Debug log cleared", 1500)
            } else {
                ; If debug window doesn't exist, just show confirmation
                ShowMouseTooltip("Debug log cleared", 1500)
            }
        } catch {
            ; Silently ignore errors and show fallback message
            ShowMouseTooltip("Debug log cleared", 1500)
        }
    }
    
    ; Get formatted QR history text
    GetQRHistoryText() {
        if (this.QRHistory.Length = 0) {
            return "No QR codes scanned yet"
        }
        
        historyText := ""
        ; Show most recent first (reverse order)
        loop this.QRHistory.Length {
            index := this.QRHistory.Length - A_Index + 1
            entry := this.QRHistory[index]
            
            ; Format: [Time] Engine: Data
            historyText .= "[" entry.time "] " entry.engine ": " 
            
            ; Truncate long URLs/data for display
            displayData := entry.data
            if (StrLen(displayData) > 60) {
                displayData := SubStr(displayData, 1, 57) "..."
            }
            historyText .= displayData "`n"
            
            ; Limit to last 10 entries for display
            if (A_Index >= 10) {
                break
            }
        }
        
        ; Add summary if more than 10 entries
        if (this.QRHistory.Length > 10) {
            historyText .= "`n... and " (this.QRHistory.Length - 10) " more entries"
        }
        
        return historyText
    }
    
    ; Add QR result to history
    AddToQRHistory(result) {
        ; Create history entry
        entry := {
            time: FormatTime(A_Now, "HH:mm:ss"),
            date: FormatTime(A_Now, "yyyy-MM-dd"),
            data: result.data,
            engine: result.HasProp("engine") ? result.engine : "Unknown",
            timestamp: A_Now
        }
        
        ; Add to history array
        this.QRHistory.Push(entry)
        
        ; Keep only last 50 entries to prevent memory bloat
        if (this.QRHistory.Length > 50) {
            this.QRHistory.RemoveAt(1)  ; Remove oldest entry
        }
        
        ; Log the addition
        this.LogDebug("📝 Added to history: " entry.engine " - " StrLen(entry.data) " chars")
    }
    
    ; Clear QR history
    ClearQRHistory() {
        historyCount := this.QRHistory.Length
        this.QRHistory := []  ; Clear the array
        
        ; Update GUI if open
        try {
            if (IsObject(this.GUI) && this.GUI.HasProp("resultEdit") && IsObject(this.GUI.resultEdit)) {
                this.GUI.resultEdit.Text := this.GetQRHistoryText()
            }
        } catch {
            ; Silently ignore errors when GUI controls are destroyed
        }
        
        ; Log the action
        this.LogDebug("🗑️ Cleared QR history (" historyCount " entries)")
        
        ; Show confirmation
        ShowMouseTooltip("History cleared (" historyCount " entries)", 2000)
    }
    
    ; Show detailed history in separate window
    ShowDetailedHistory() {
        if (this.QRHistory.Length = 0) {
            ShowMouseTooltip("No QR history to display", 2000)
            return
        }
        
        historyGui := Gui("+Owner" (IsObject(this.GUI) ? this.GUI.Hwnd : "") " -MaximizeBox", "QR Scan History (" this.QRHistory.Length " entries)")
        historyGui.SetFont("s10", "Segoe UI")
        historyGui.BackColor := "White"
        
        ; Modern header
        headerBg := historyGui.Add("Text", "x0 y0 w580 h60 Background0x2563EB")
        historyGui.Add("Text", "x30 y15 w520 Center c0xFFFFFF Background0x2563EB", "📋 Complete QR Scan History").SetFont("s12 Bold")
        historyGui.Add("Text", "x30 y35 w520 Center c0xE5E7EB Background0x2563EB", "Double-click any entry to copy to clipboard")
        
        ; History list with better styling
        historyList := historyGui.Add("ListView", "x30 y80 w520 h320 Grid", ["Time", "Date", "Engine", "QR Data"])
        historyList.OnEvent("DoubleClick", (*) => this.CopyHistoryEntry(historyList))
        
        ; Populate list (most recent first)
        loop this.QRHistory.Length {
            index := this.QRHistory.Length - A_Index + 1
            entry := this.QRHistory[index]
            
            ; Truncate data for list display
            displayData := entry.data
            if (StrLen(displayData) > 50) {
                displayData := SubStr(displayData, 1, 47) "..."
            }
            
            historyList.Add("", entry.time, entry.date, entry.engine, displayData)
        }
        
        ; Auto-size columns with better proportions
        historyList.ModifyCol(1, 70)   ; Time
        historyList.ModifyCol(2, 90)   ; Date
        historyList.ModifyCol(3, 90)   ; Engine
        historyList.ModifyCol(4, 270)  ; Data
        
        ; Modern button bar
        buttonBg := historyGui.Add("Text", "x0 y420 w580 h60 Background0xF3F4F6")
        historyGui.Add("Button", "x30 y435 w120 h30", "📋 Copy Selected").OnEvent("Click", (*) => this.CopyHistoryEntry(historyList))
        historyGui.Add("Button", "x160 y435 w90 h30", "🗑️ Clear All").OnEvent("Click", (*) => (this.ClearQRHistory(), historyGui.Destroy()))
        historyGui.Add("Button", "x260 y435 w80 h30", "💾 Export").OnEvent("Click", (*) => this.ExportHistory())
        historyGui.Add("Button", "x480 y435 w70 h30", "Close").OnEvent("Click", (*) => historyGui.Destroy())
        
        historyGui.OnEvent("Escape", (*) => historyGui.Destroy())
        historyGui.Show("w580 h480")
    }
    
    ; Copy selected history entry to clipboard
    CopyHistoryEntry(listView) {
        selectedRow := listView.GetNext()
        if (selectedRow = 0) {
            ShowMouseTooltip("Please select an entry to copy", 2000)
            return
        }
        
        ; Get the actual entry (reverse index since we display newest first)
        entryIndex := this.QRHistory.Length - selectedRow + 1
        if (entryIndex > 0 && entryIndex <= this.QRHistory.Length) {
            entry := this.QRHistory[entryIndex]
            A_Clipboard := entry.data
            ShowMouseTooltip("Copied to clipboard: " SubStr(entry.data, 1, 30) "...", 2000)
        }
    }
    
    ; Export history to file
    ExportHistory() {
        if (this.QRHistory.Length = 0) {
            ShowMouseTooltip("No history to export", 2000)
            return
        }
        
        ; Create export filename with timestamp
        exportFile := A_Desktop "\QR_History_" FormatTime(A_Now, "yyyy-MM-dd_HH-mm-ss") ".txt"
        
        ; Build export content
        exportContent := "QR Code Scan History Export`n"
        exportContent .= "Generated: " FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") "`n"
        exportContent .= "Total Entries: " this.QRHistory.Length "`n"
        exportContent .= "=" . StrReplace(Format("{:50s}", ""), " ", "=") "`n`n"
        
        ; Add each entry
        for entry in this.QRHistory {
            exportContent .= "[" entry.date " " entry.time "] " entry.engine "`n"
            exportContent .= "Data: " entry.data "`n"
            exportContent .= "-" . StrReplace(Format("{:50s}", ""), " ", "-") "`n"
        }
        
        try {
            FileAppend(exportContent, exportFile)
            ShowMouseTooltip("History exported to: " exportFile, 4000)
        } catch as e {
            ShowMouseTooltip("Export failed: " e.Message, 3000)
        }
    }
    
    ; Update settings from GUI
    UpdateSettings() {
        if (IsObject(this.GUI)) {
            if (this.GUI.clipboardCheck)
                this.Settings.copyToClipboard := this.GUI.clipboardCheck.Value
            if (this.GUI.soundCheck)
                this.Settings.playSoundOnDetection := this.GUI.soundCheck.Value
        }
    }
    
    ; Run comprehensive diagnostics
    RunDiagnostics() {
        this.LogDebugSeparator()
        this.LogDebug("🔬 RUNNING DIAGNOSTICS")
        this.UpdateStatus("Running diagnostics...")
        
        ; Check and cache engines when user clicks Test (user-initiated)
        this.CheckEnginesOnDemand()
        
        ; Test 1: Check Python availability
        this.LogDebug("")
        this.LogDebug("🐍 Testing Python availability...")
        pythonFound := false
        pythonCommands := ["python", "py", "python3"]
        
        for cmd in pythonCommands {
            try {
                RunWait(cmd ' --version', , "Hide", &pythonVersion)
                this.LogDebug("✅ " cmd " found: " Trim(pythonVersion))
                pythonFound := true
            } catch {
                this.LogDebug("❌ " cmd " not found or not in PATH")
            }
        }
        
        if (!pythonFound) {
            this.LogDebug("💡 Try running setup_qr_complete.bat as Administrator")
        }
        
        ; Test 2: Check virtual environment
        venvPaths := [
            A_ScriptDir "\qr_venv\Scripts\python.exe",  ; Same directory as script
            A_ScriptDir "\..\qr_venv\Scripts\python.exe",  ; Project root from src/
            A_WorkingDir "\qr_venv\Scripts\python.exe"   ; Working directory
        ]
        
        venvFound := false
        for path in venvPaths {
            if (FileExist(path)) {
                this.LogDebug("✅ Virtual environment found at: " path)
                venvFound := true
                break
            }
        }
        
        if (!venvFound) {
            this.LogDebug("❌ Virtual environment not found - run setup_qr_venv.bat")
            this.LogDebug("🔍 Searched paths:")
            for path in venvPaths {
                this.LogDebug("   - " path)
            }
        }
        
        ; Test 3: Test each Python engine individually
        engines := ["opencv-python", "zxingcpp", "pyzbar", "Pillow"]
        pythonCmd := this.GetPythonCommand()
        this.LogDebug("🐍 Using Python command: " pythonCmd)
        
        for engine in engines {
            this.LogDebug("📦 Testing " engine "...")
            importName := this.GetImportName(engine)
            
            try {
                ; Create a temporary batch file to capture output
                tempBat := A_Temp "\qr_test_" A_TickCount ".bat"
                tempOut := A_Temp "\qr_output_" A_TickCount ".txt"
                
                batContent := "@echo off`n"
                batContent .= pythonCmd ' -c "import ' importName '; print(\"OK\")" > "' tempOut '" 2>&1`n'
                FileAppend(batContent, tempBat)
                
                this.LogDebug("💻 Running batch test...")
                exitCode := RunWait('"' tempBat '"', , "Hide")
                
                ; Read the output file
                result := ""
                if (FileExist(tempOut)) {
                    result := FileRead(tempOut)
                    FileDelete(tempOut)
                }
                FileDelete(tempBat)
                
                this.LogDebug("📄 Exit code: " exitCode)
                if (StrLen(result) > 0) {
                    this.LogDebug("    Result: " SubStr(result, 1, 30) (StrLen(result) > 30 ? "..." : ""))
                }
                
                if (InStr(result, "OK")) {
                    ; Check if using virtual environment
                    envType := "system"
                    venvPaths := [
                        A_ScriptDir "\qr_venv\Scripts\python.exe",
                        A_ScriptDir "\..\qr_venv\Scripts\python.exe", 
                        A_WorkingDir "\qr_venv\Scripts\python.exe"
                    ]
                    for path in venvPaths {
                        if (FileExist(path)) {
                            envType := "venv"
                            break
                        }
                    }
                    this.LogDebug("✅ " engine " working (" envType " Python)")
                } else {
                    this.LogDebug("❌ " engine " import failed - no OK found")
                }
            } catch as e {
                this.LogDebug("❌ " engine " error: " e.Message)
            }
        }
        
        ; Test 4: Create and test sample QR script
        this.LogDebug("🧪 Creating test QR script...")
        this.LogDebug("📂 A_ScriptDir: " A_ScriptDir)
        this.LogDebug("📂 A_WorkingDir: " A_WorkingDir)
        this.CreateTestQRScript()
        
        ; Test 5: Test screenshot capability
        this.LogDebug("📷 Testing screenshot capability...")
        try {
            tempPath := A_Temp "\qr_test_screenshot.png"
            psCmd := 'powershell -ExecutionPolicy Bypass -command "Add-Type -AssemblyName System.Windows.Forms; '
            psCmd .= '$bounds = [System.Drawing.Rectangle]::new(0, 0, 100, 100); '
            psCmd .= '$bitmap = New-Object System.Drawing.Bitmap(100, 100); '
            psCmd .= '$graphics = [System.Drawing.Graphics]::FromImage($bitmap); '
            psCmd .= '$graphics.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size); '
            psCmd .= '$bitmap.Save(\"' tempPath '\", [System.Drawing.Imaging.ImageFormat]::Png); '
            psCmd .= '$graphics.Dispose(); $bitmap.Dispose()"'
            
            RunWait(psCmd, , "Hide")
            
            if (FileExist(tempPath)) {
                this.LogDebug("✅ Screenshot capability working")
                FileDelete(tempPath)
            } else {
                this.LogDebug("❌ Screenshot failed - file not created")
            }
        } catch as e {
            this.LogDebug("❌ Screenshot error: " e.Message)
        }
        
        this.LogDebug("")
        this.LogDebug("🏁 DIAGNOSTICS COMPLETE")
        this.LogDebugSeparator()
        
        ; Update status with engine count first  
        engineCount := this.CountAvailableEnginesFast()
        this.UpdateStatus("Diagnostics complete - " engineCount " engines available")
        
        ; Small delay to ensure cache is updated, then refresh GUI display
        SetTimer(() => this.UpdateGUIAfterDiagnostics(), -100)
    }
    
    ; Update GUI display after diagnostics complete
    UpdateGUIAfterDiagnostics() {
        try {
            if (IsObject(this.GUI)) {
                ; Update engine status display
                if (this.GUI.HasProp("engineStatus") && IsObject(this.GUI.engineStatus)) {
                    this.GUI.engineStatus.Text := this.GetEngineStatusFast()
                }
                
                ; Update status text with engine count
                if (this.GUI.HasProp("statusText") && IsObject(this.GUI.statusText)) {
                    engineCount := this.CountAvailableEnginesFast()
                    this.GUI.statusText.Text := "Diagnostics complete - " engineCount " engines available"
                }
                
                ; Update debug status header
                if (this.GUI.HasProp("debugStatus") && IsObject(this.GUI.debugStatus)) {
                    engineCount := this.CountAvailableEnginesFast()
                    this.GUI.debugStatus.Text := "diagnostics complete - " engineCount " engines available"
                }
            }
        } catch {
            ; Silently ignore if GUI controls are destroyed
        }
    }
    
    ; Get import name for Python packages
    GetImportName(packageName) {
        switch packageName {
            case "opencv-python":
                return "cv2"
            case "zxingcpp":
                return "zxingcpp"
            case "pyzbar":
                return "pyzbar"
            case "Pillow":
                return "PIL"
            default:
                return packageName
        }
    }
    
    ; Create a simple test QR script
    CreateTestQRScript() {
        ; Try to use project root directory
        projectRoot := A_ScriptDir "\.."
        testScript := projectRoot "\qr_test.py"
        this.LogDebug("📝 Creating test script at: " testScript)
        
        script := "# Simple QR Test Script" . "`n"
        script .= "import sys" . "`n"
        script .= "print('Python working from:', sys.executable)" . "`n"
        script .= "print('Python version:', sys.version)" . "`n`n"
        
        script .= "try:" . "`n"
        script .= "    import cv2" . "`n"
        script .= "    print('OpenCV available')" . "`n"
        script .= "except Exception as e:" . "`n"
        script .= "    print('OpenCV not available:', str(e))" . "`n`n"
        
        script .= "try:" . "`n"
        script .= "    import zxingcpp" . "`n"
        script .= "    print('zxing-cpp available')" . "`n"
        script .= "except Exception as e:" . "`n"
        script .= "    print('zxing-cpp not available:', str(e))" . "`n`n"
        
        script .= "try:" . "`n"
        script .= "    from pyzbar import pyzbar" . "`n"
        script .= "    print('pyzbar available')" . "`n"
        script .= "except Exception as e:" . "`n"
        script .= "    print('pyzbar not available:', str(e))" . "`n`n"
        
        script .= "try:" . "`n"
        script .= "    from PIL import Image" . "`n"
        script .= "    print('Pillow available')" . "`n"
        script .= "except Exception as e:" . "`n"
        script .= "    print('Pillow not available:', str(e))" . "`n"
        
        try {
            if (FileExist(testScript))
                FileDelete(testScript)
            FileAppend(script, testScript)
            
            if (FileExist(testScript)) {
                this.LogDebug("✅ Test script created successfully at: " testScript)
            } else {
                this.LogDebug("❌ Test script creation failed - file does not exist after creation")
                return
            }
            
            ; Use batch file to capture output reliably
            tempBat := A_Temp "\qr_script_" A_TickCount ".bat"
            tempOut := A_Temp "\qr_script_output_" A_TickCount ".txt"
            
            batContent := "@echo off`n"
            batContent .= this.GetPythonCommand() ' "' testScript '" > "' tempOut '" 2>&1`n'
            FileAppend(batContent, tempBat)
            
            this.LogDebug("🚀 Running test script via batch: " tempBat)
            exitCode := RunWait('"' tempBat '"', , "Hide")
            
            ; Read the output file
            output := ""
            if (FileExist(tempOut)) {
                output := FileRead(tempOut)
                FileDelete(tempOut)
            }
            FileDelete(tempBat)
            
            this.LogDebug("🧪 Test script exit code: " exitCode ", output: [" output "]")
            
            FileDelete(testScript)
        } catch as e {
            this.LogDebug("❌ Test script failed: " e.Message)
        }
    }
    
    ; Lightning-fast screen scan (bypasses GUI)
    QuickScreenScan() {
        ; Show immediate feedback
        ShowMouseTooltip("⚡ Lightning scan starting...", 1000)
        
        ; Trigger instant full screen scan
        this.ScanFullScreen()
    }
    

    
    ; Scan full screen
    ScanFullScreen() {
        this.LogDebug("🖥️ Starting full screen scan (" A_ScreenWidth "x" A_ScreenHeight ")")
        this.UpdateStatus("Capturing full screen...")
        
        ShowMouseTooltip("Scanning full screen for QR codes...", 2000)
        this.CaptureAndProcessRegion(0, 0, A_ScreenWidth, A_ScreenHeight)
    }
    
    ; Ultra-fast screen capture and processing
    CaptureAndProcessRegion(x, y, width, height) {
        try {
            this.LogDebug("⚡ Starting screen capture")
            this.LogDebug("    Region: " x "," y " " width "x" height)
            this.UpdateStatus("Fast capturing...")
            
            tempPath := this.Settings.tempImagePath
            
            ; Speed-optimized PowerShell capture (single line, minimal objects)
            psCmd := 'powershell -ExecutionPolicy Bypass -command "'
            psCmd .= 'Add-Type -AssemblyName System.Windows.Forms,System.Drawing;'
            psCmd .= '$b=New-Object System.Drawing.Bitmap(' width ',' height ');'
            psCmd .= '$g=[System.Drawing.Graphics]::FromImage($b);'
            psCmd .= '$g.CopyFromScreen(' x ',' y ',0,0,$b.Size);'
            psCmd .= '$b.Save(\"' tempPath '\",[System.Drawing.Imaging.ImageFormat]::Png);'
            psCmd .= '$g.Dispose();$b.Dispose()"'
            
            ; Fast execution
            startTime := A_TickCount
            RunWait(psCmd, , "Hide")
            captureTime := A_TickCount - startTime
            
            if (FileExist(tempPath)) {
                fileSize := FileGetSize(tempPath)
                this.LogDebug("✅ Capture complete")
                this.LogDebug("    Time: " captureTime "ms")
                this.LogDebug("    Size: " fileSize " bytes")
                this.UpdateStatus("Processing QR...")
                
                ; Immediate processing with speed mode
                this.ProcessImageWithFallback(tempPath)
            } else {
                this.LogDebug("❌ Capture failed")
                this.UpdateStatus("Capture failed")
                ShowMouseTooltip("Screenshot failed", 2000)
            }
            
        } catch as e {
            this.LogDebug("💥 Fast capture error: " e.Message)
            this.UpdateStatus("Capture error")
            ShowMouseTooltip("Capture error: " e.Message, 3000)
        }
    }
    
    ; Scan image file
    ScanImageFile() {
        this.LogDebug("📁 Opening file selection dialog")
        this.UpdateStatus("Select image file...")
        
        selectedFile := FileSelect(1, , "Select Image File", "Image Files (*.png; *.jpg; *.jpeg; *.bmp; *.gif)")
        if (!selectedFile) {
            this.LogDebug("❌ File selection cancelled")
            this.UpdateStatus("File selection cancelled")
            return
        }
            
        this.LogDebug("✅ File selected: " selectedFile)
        ShowMouseTooltip("Processing image file with multiple engines...", 2000)
        this.ProcessImageWithFallback(selectedFile)
    }
    

    
    ; Speed-optimized QR processing with smart engine selection
    ProcessImageWithFallback(imagePath) {
        if (!FileExist(imagePath)) {
            this.LogDebug("❌ Image file not found: " imagePath)
            this.UpdateStatus("Error: Image file not found")
            ShowMouseTooltip("Image file not found", 2000)
            return
        }
        
        this.LogDebug("📸 Processing image: " imagePath)
        this.UpdateStatus("Fast QR scanning...")
        
        ; Get file size for engine selection optimization
        fileSize := FileGetSize(imagePath)
        this.LogDebug("📊 Image size: " fileSize " bytes")
        
        ; Speed-optimized engine order based on file size and performance
        engines := this.GetOptimalEngineOrder(fileSize)
        
        ; Pre-check available engines once (cache results)
        if (!this.HasProp("cachedEngines")) {
            this.CacheAvailableEngines()
        }
        
        for engine in engines {
            ; Skip unavailable engines immediately
            if (!this.cachedEngines[engine.name]) {
                this.LogDebug("⏭️ Skipping " engine.name " (cached as unavailable)")
                continue
            }
            
            try {
                this.LogDebug("🚀 Processing with " engine.name)
                this.UpdateStatus("Scanning with " engine.name "...")
                
                startTime := A_TickCount
                result := this.%engine.method%(imagePath, true)  ; Pass speed flag
                processingTime := A_TickCount - startTime
                
                this.LogDebug("⚡ " engine.name " completed")
                this.LogDebug("    Time: " processingTime "ms")
                
                if (result && result.success) {
                    this.LogDebug("✅ SUCCESS with " engine.name)
                    this.LogDebug("    Data length: " StrLen(result.data) " chars")
                    this.LogDebug("    Content: " SubStr(result.data, 1, 40) (StrLen(result.data) > 40 ? "..." : ""))
                    this.UpdateStatus("QR found!")
                    
                    ; Immediate clipboard copy for speed
                    if (this.Settings.copyToClipboard) {
                        A_Clipboard := result.data
                    }
                    
                    ; Quick sound feedback
                    if (this.Settings.playSoundOnDetection) {
                        SoundPlay("*64")
                    }
                    
                    ; Show result without blocking
                    ShowMouseTooltip("✅ QR: " result.data, 3000)
                    
                    ; Handle result in background
                    SetTimer(() => this.HandleQRResult(result), -10)
                    
                    return
                } else {
                    this.LogDebug("❌ " engine.name " no result")
                }
            } catch as e {
                this.LogDebug("💥 " engine.name " error: " e.Message)
                continue
            }
        }
        
        this.LogDebug("😞 No QR code detected")
        this.UpdateStatus("No QR code found")
        ShowMouseTooltip("No QR code detected", 1500)
    }
    
    ; Get optimal engine order based on file characteristics
    GetOptimalEngineOrder(fileSize) {
        ; For small images (< 500KB), prioritize speed
        if (fileSize < 500000) {
            return [
                {name: "pyzbar", method: "ProcessWithPyzbar"},
                {name: "zxing-cpp", method: "ProcessWithZxingCpp"},
                {name: "OpenCV", method: "ProcessWithOpenCV"}
            ]
        }
        ; For larger images, prioritize accuracy
        else {
            return [
                {name: "zxing-cpp", method: "ProcessWithZxingCpp"},
                {name: "pyzbar", method: "ProcessWithPyzbar"},
                {name: "OpenCV", method: "ProcessWithOpenCV"}
            ]
        }
    }
    
    ; Cache available engines to avoid repeated checks
    CacheAvailableEngines() {
        this.LogDebug("🔄 Caching available engines...")
        
        ; Initialize cache map
        this.cachedEngines := Map()
        
        engines := ["pyzbar", "zxing-cpp", "OpenCV"]
        for engine in engines {
            try {
                ; Add timeout protection for each engine check
                available := this.CheckEngineAvailable(engine)
                this.cachedEngines[engine] := available
                this.LogDebug("📦 " engine ": " (available ? "✅" : "❌"))
            } catch as e {
                ; If individual engine check fails, mark as unavailable and continue
                this.cachedEngines[engine] := false
                this.LogDebug("📦 " engine ": ❌ (Error: " e.Message ")")
            }
        }
        
        ; Ensure we have a valid cache even if all checks failed
        if (!IsObject(this.cachedEngines) || this.cachedEngines.Count == 0) {
            this.cachedEngines := Map()
            for engine in engines {
                this.cachedEngines[engine] := false
            }
            this.LogDebug("⚠️ All engine checks failed - marking all as unavailable")
        }
        
        ; No automatic refresh - engines will only be checked when requested by user
    }
    

    
    ; Refresh engine cache (manual refresh only)
    RefreshEngineCache() {
        this.DeleteProp("cachedEngines")
        this.DeleteProp("cachingInProgress")
        this.CacheAvailableEngines()
    }
    
    ; OpenCV WeChat QR detector (most reliable for artistic QR codes)
    ProcessWithOpenCV(imagePath, speedMode := false) {
        ; Use pre-built temp paths for speed
        tempBat := A_Temp "\qr_opencv.bat"
        tempOut := A_Temp "\qr_opencv_out.txt"
        
        ; Speed optimization: reuse batch file if exists and recent
        reuseFile := false
        if (speedMode && FileExist(tempBat)) {
            fileAge := A_Now - FileGetTime(tempBat, "M")
            if (fileAge < 300) {  ; 5 minutes
                reuseFile := true
            }
        }
        
        if (!reuseFile) {
            ; Optimized Python code for speed
            batContent := "@echo off`n"
            batContent .= this.GetPythonCommand() ' -c "'
            batContent .= "import sys,json,cv2;"
            batContent .= "img=cv2.imread(sys.argv[1]);"
            batContent .= "data,_,_=cv2.QRCodeDetector().detectAndDecode(img);"
            batContent .= "print(json.dumps({'success':bool(data),'data':str(data),'engine':'OpenCV'}))"
            batContent .= '" "%1" > "' tempOut '" 2>&1`n'
            
            ; Clear old file and create new one
            try {
                FileDelete(tempBat)
            } catch {
                ; Ignore deletion errors
            }
            FileAppend(batContent, tempBat)
        }
        
        ; Execute with timeout for speed
        exitCode := RunWait('"' tempBat '" "' imagePath '"', , "Hide")
        
        ; Quick file read
        output := ""
        if (FileExist(tempOut)) {
            output := FileRead(tempOut)
        }
        
        ; Schedule cleanup (centralized to prevent timer accumulation)
        if (!speedMode) {
            this.ScheduleCleanup(tempBat, tempOut)
        }
        
        return this.ParseJSON(output)
    }
    
    ; Centralized cleanup scheduler to prevent timer accumulation
    ScheduleCleanup(batFile, outFile) {
        ; Add files to cleanup queue
        if (!this.HasProp("cleanupQueue")) {
            this.cleanupQueue := []
        }
        
        this.cleanupQueue.Push({bat: batFile, out: outFile, time: A_TickCount})
        
        ; Start cleanup timer only if not already running
        if (!this.HasProp("cleanupTimerActive")) {
            this.cleanupTimerActive := true
            SetTimer(() => this.ProcessCleanupQueue(), -500)  ; Single timer for all cleanup
        }
    }
    
    ; Process cleanup queue
    ProcessCleanupQueue() {
        this.DeleteProp("cleanupTimerActive")
        
        if (!this.HasProp("cleanupQueue") || this.cleanupQueue.Length == 0) {
            return
        }
        
        ; Process all queued items
        for item in this.cleanupQueue {
            this.CleanupTempFiles(item.bat, item.out)
        }
        
        ; Clear the queue
        this.cleanupQueue := []
    }
    
    ; Cleanup temporary files (for background cleanup)
    CleanupTempFiles(batFile, outFile) {
        try {
            if (FileExist(batFile))
                FileDelete(batFile)
        } catch {
            ; Ignore deletion errors
        }
        try {
            if (FileExist(outFile))
                FileDelete(outFile)
        } catch {
            ; Ignore deletion errors
        }
    }
    
    ; zxing-cpp (best Python package)
    ProcessWithZxingCpp(imagePath, speedMode := false) {
        ; Speed optimized temp files
        tempBat := A_Temp "\qr_zxing.bat"
        tempOut := A_Temp "\qr_zxing_out.txt"
        
        ; Reuse batch file for speed
        reuseFile := false
        if (speedMode && FileExist(tempBat)) {
            fileAge := A_Now - FileGetTime(tempBat, "M")
            if (fileAge < 300) {  ; 5 minutes
                reuseFile := true
            }
        }
        
        if (!reuseFile) {
            ; Optimized Python code for speed
            batContent := "@echo off`n"
            batContent .= this.GetPythonCommand() ' -c "'
            batContent .= "import sys,json,zxingcpp;"
            batContent .= "from PIL import Image;"
            batContent .= "img=Image.open(sys.argv[1]);"
            batContent .= "results=zxingcpp.read_barcodes(img);"
            batContent .= "qr=next((r for r in results if r.valid),None);"
            batContent .= "print(json.dumps({'success':bool(qr),'data':str(qr.text) if qr else '','engine':'zxing-cpp'}))"
            batContent .= '" "%1" > "' tempOut '" 2>&1`n'
            
            try {
                FileDelete(tempBat)
            } catch {
                ; Ignore deletion errors
            }
            FileAppend(batContent, tempBat)
        }
        
        exitCode := RunWait('"' tempBat '" "' imagePath '"', , "Hide")
        
        ; Quick file read
        output := ""
        if (FileExist(tempOut)) {
            output := FileRead(tempOut)
        }
        
        ; Background cleanup for speed
        if (!speedMode) {
            SetTimer(() => this.CleanupTempFiles(tempBat, tempOut), -100)
        }
        
        return this.ParseJSON(output)
    }
    
    ; pyzbar fallback (fastest engine)
    ProcessWithPyzbar(imagePath, speedMode := false) {
        ; Speed optimized temp files
        tempBat := A_Temp "\qr_pyzbar.bat"
        tempOut := A_Temp "\qr_pyzbar_out.txt"
        
        ; Reuse batch file for speed
        reuseFile := false
        if (speedMode && FileExist(tempBat)) {
            fileAge := A_Now - FileGetTime(tempBat, "M")
            if (fileAge < 300) {  ; 5 minutes
                reuseFile := true
            }
        }
        
        if (!reuseFile) {
            ; Ultra-optimized Python code for maximum speed
            batContent := "@echo off`n"
            batContent .= this.GetPythonCommand() ' -c "'
            batContent .= "import sys,json;"
            batContent .= "from pyzbar.pyzbar import decode;"
            batContent .= "from PIL import Image;"
            batContent .= "img=Image.open(sys.argv[1]);"
            batContent .= "results=decode(img);"
            batContent .= "qr=next((r for r in results if r.type=='QRCODE'),None);"
            batContent .= "print(json.dumps({'success':bool(qr),'data':qr.data.decode('utf-8') if qr else '','engine':'pyzbar'}))"
            batContent .= '" "%1" > "' tempOut '" 2>&1`n'
            
            try {
                FileDelete(tempBat)
            } catch {
                ; Ignore deletion errors
            }
            FileAppend(batContent, tempBat)
        }
        
        exitCode := RunWait('"' tempBat '" "' imagePath '"', , "Hide")
        
        ; Ultra-fast file read
        output := ""
        if (FileExist(tempOut)) {
            output := FileRead(tempOut)
        }
        
        ; Schedule cleanup (centralized to prevent timer accumulation)
        if (!speedMode) {
            this.ScheduleCleanup(tempBat, tempOut)
        }
        
        return this.ParseJSON(output)
    }
    
    ; Create OpenCV WeChat QR detector script
    CreateOpenCVScript(scriptPath) {
        script := "import sys" . "`n"
        script .= "import json" . "`n"
        script .= "try:" . "`n"
        script .= "    import cv2" . "`n"
        script .= "except ImportError:" . "`n"
        script .= "    print(json.dumps({'success': False, 'error': 'OpenCV not installed'}))" . "`n"
        script .= "    sys.exit(0)" . "`n`n"
        script .= "def detect_qr_opencv(image_path):" . "`n"
        script .= "    try:" . "`n"
        script .= "        img = cv2.imread(image_path)" . "`n"
        script .= "        if img is None:" . "`n"
        script .= "            return {'success': False, 'error': 'Could not load image'}" . "`n"
        script .= "        detector = cv2.QRCodeDetector()" . "`n"
        script .= "        data, bbox, _ = detector.detectAndDecode(img)" . "`n`n"
        script .= "        if data:" . "`n"
        script .= "            return {" . "`n"
        script .= "                'success': True," . "`n"
        script .= "                'data': str(data)," . "`n"
        script .= "                'engine': 'OpenCV WeChat'" . "`n"
        script .= "            }" . "`n"
        script .= "        else:" . "`n"
        script .= "            return {'success': False, 'error': 'No QR code found'}" . "`n"
        script .= "    except Exception as e:" . "`n"
        script .= "        return {'success': False, 'error': str(e)}" . "`n`n"
        script .= "if __name__ == '__main__':" . "`n"
        script .= "    try:" . "`n"
        script .= "        if len(sys.argv) < 2:" . "`n"
        script .= "            print(json.dumps({'success': False, 'error': 'No image path provided'}))" . "`n"
        script .= "        else:" . "`n"
        script .= "            result = detect_qr_opencv(sys.argv[1])" . "`n"
        script .= "            print(json.dumps(result))" . "`n"
        script .= "    except Exception as e:" . "`n"
        script .= "        print(json.dumps({'success': False, 'error': 'Script error: ' + str(e)}))"
        
        try {
            FileDelete scriptPath
            FileAppend script, scriptPath
        } catch {
            ; Script creation failed
        }
    }
    
    ; Create zxing-cpp script  
    CreateZxingCppScript(scriptPath) {
        script := "import sys" . "`n"
        script .= "import json" . "`n"
        script .= "try:" . "`n"
        script .= "    import zxingcpp" . "`n"
        script .= "    from PIL import Image" . "`n"
        script .= "except ImportError as e:" . "`n"
        script .= "    print(json.dumps({'success': False, 'error': 'Missing package: ' + str(e)}))" . "`n"
        script .= "    sys.exit(0)" . "`n`n"
        script .= "def detect_qr_zxing(image_path):" . "`n"
        script .= "    try:" . "`n"
        script .= "        img = Image.open(image_path)" . "`n"
        script .= "        results = zxingcpp.read_barcodes(img)" . "`n`n"
        script .= "        for result in results:" . "`n"
        script .= "            if result.valid:" . "`n"
        script .= "                return {" . "`n"
        script .= "                    'success': True," . "`n"
        script .= "                    'data': str(result.text)," . "`n"
        script .= "                    'engine': 'zxing-cpp'," . "`n"
        script .= "                    'format': str(result.format.name)" . "`n"
        script .= "                }" . "`n`n"
        script .= "        return {'success': False, 'error': 'No QR code found'}" . "`n"
        script .= "    except Exception as e:" . "`n"
        script .= "        return {'success': False, 'error': str(e)}" . "`n`n"
        script .= "if __name__ == '__main__':" . "`n"
        script .= "    try:" . "`n"
        script .= "        if len(sys.argv) < 2:" . "`n"
        script .= "            print(json.dumps({'success': False, 'error': 'No image path provided'}))" . "`n"
        script .= "        else:" . "`n"
        script .= "            result = detect_qr_zxing(sys.argv[1])" . "`n"
        script .= "            print(json.dumps(result))" . "`n"
        script .= "    except Exception as e:" . "`n"
        script .= "        print(json.dumps({'success': False, 'error': 'Script error: ' + str(e)}))"
        
        try {
            FileDelete scriptPath
            FileAppend script, scriptPath
        } catch {
            ; Script creation failed
        }
    }
    
    ; Create pyzbar script
    CreatePyzbarScript(scriptPath) {
        script := "import sys" . "`n"
        script .= "import json" . "`n"
        script .= "try:" . "`n"
        script .= "    from pyzbar.pyzbar import decode" . "`n"
        script .= "    from PIL import Image" . "`n"
        script .= "except ImportError as e:" . "`n"
        script .= "    print(json.dumps({'success': False, 'error': 'Missing package: ' + str(e)}))" . "`n"
        script .= "    sys.exit(0)" . "`n`n"
        script .= "def detect_qr_pyzbar(image_path):" . "`n"
        script .= "    try:" . "`n"
        script .= "        img = Image.open(image_path)" . "`n"
        script .= "        results = decode(img)" . "`n`n"
        script .= "        for result in results:" . "`n"
        script .= "            if result.type == 'QRCODE':" . "`n"
        script .= "                return {" . "`n"
        script .= "                    'success': True," . "`n"
        script .= "                    'data': result.data.decode('utf-8')," . "`n"
        script .= "                    'engine': 'pyzbar'" . "`n"
        script .= "                }" . "`n`n"
        script .= "        return {'success': False, 'error': 'No QR code found'}" . "`n"
        script .= "    except Exception as e:" . "`n"
        script .= "        return {'success': False, 'error': str(e)}" . "`n`n"
        script .= "if __name__ == '__main__':" . "`n"
        script .= "    try:" . "`n"
        script .= "        if len(sys.argv) < 2:" . "`n"
        script .= "            print(json.dumps({'success': False, 'error': 'No image path provided'}))" . "`n"
        script .= "        else:" . "`n"
        script .= "            result = detect_qr_pyzbar(sys.argv[1])" . "`n"
        script .= "            print(json.dumps(result))" . "`n"
        script .= "    except Exception as e:" . "`n"
        script .= "        print(json.dumps({'success': False, 'error': 'Script error: ' + str(e)}))"
        
        try {
            FileDelete scriptPath
            FileAppend script, scriptPath
        } catch {
            ; Script creation failed
        }
    }
    
        ; Handle QR scan result
    HandleQRResult(result) {
        try {
        if (result.success) {
            qrData := result.data
            this.LastQRData := qrData
            
            ; Add to history
            this.AddToQRHistory(result)
            
            ; Update GUI history display
            if (IsObject(this.GUI) && this.GUI.resultEdit)
                this.GUI.resultEdit.Text := this.GetQRHistoryText()
                
                if (this.Settings.copyToClipboard) {
                    A_Clipboard := qrData
                    ShowMouseTooltip("QR Code found and copied to clipboard:`n" qrData, 4000)
                } else {
                    ShowMouseTooltip("QR Code found:`n" qrData, 4000)
                }
                
                if (this.Settings.playSoundOnDetection) {
                    SoundPlay("*64")
                }
                
                try {
                    this.ShowQRResultDialog(result)
                } catch as e {
                    this.LogDebug("⚠️ Result dialog error: " e.Message " - but QR was processed!")
                    ; Don't fail the whole operation if dialog has issues
                }
                
            } else {
                ShowMouseTooltip("No QR code detected in image", 2000)
            }
        } catch as e {
            this.LogDebug("💥 HandleQRResult error: " e.Message)
            ; Still show the QR data even if there was an error
            if (result.success && result.data) {
                A_Clipboard := result.data
                ShowMouseTooltip("QR detected but UI error - copied to clipboard:`n" result.data, 4000)
            }
        }
    }
    
    ; Show detailed QR result dialog
    ShowQRResultDialog(result) {
        resultGui := Gui("+Owner" (IsObject(this.GUI) ? this.GUI.Hwnd : ""), "QR Code Detected")
        resultGui.SetFont("s10", "Segoe UI")
        
        resultGui.Add("Text", "x20 y20", "QR Code Data:")
        dataEdit := resultGui.Add("Edit", "x20 y40 w400 h100 ReadOnly VScroll")
        dataEdit.Text := result.data
        
        resultGui.Add("Text", "x20 y150", "Additional Information:")
        infoText := "Engine: " (result.HasProp("engine") ? result.engine : "Unknown") "`n"
        if (result.HasProp("format")) {
            infoText .= "Format: " result.format "`n"
        }
        if (result.HasProp("version")) {
            infoText .= "QR Version: " result.version "`n"
        }
        if (result.HasProp("location")) {
            infoText .= "Location: Found at multiple points`n"
        }
        
        ; Add data length and type info
        infoText .= "Data Length: " StrLen(result.data) " characters`n"
        if (InStr(result.data, "http") = 1) {
            infoText .= "Type: URL`n"
        } else if (InStr(result.data, "mailto:") = 1) {
            infoText .= "Type: Email`n"
        } else if (InStr(result.data, "tel:") = 1) {
            infoText .= "Type: Phone`n"
        } else {
            infoText .= "Type: Text`n"
        }
        
        infoEdit := resultGui.Add("Edit", "x20 y170 w400 h60 ReadOnly")
        infoEdit.Text := infoText
        
        resultGui.Add("Button", "x20 y250 w100 h30", "Copy Data").OnEvent("Click", (*) => (A_Clipboard := result.data, ShowMouseTooltip("Copied to clipboard", 1000)))
        
        if (InStr(result.data, "http") = 1) {
            resultGui.Add("Button", "x130 y250 w100 h30", "Open URL").OnEvent("Click", (*) => Run(result.data))
        }
        
        resultGui.Add("Button", "x320 y250 w100 h30", "Close").OnEvent("Click", (*) => resultGui.Destroy())
        
        resultGui.OnEvent("Escape", (*) => resultGui.Destroy())
        resultGui.Show("w440 h300")
    }
    

    
    ; Install Python QR engines
    InstallPythonEngines() {
        installGui := Gui("+Owner" (IsObject(this.GUI) ? this.GUI.Hwnd : ""), "Install Python QR Engines")
        installGui.SetFont("s10", "Segoe UI")
        
        installGui.Add("Text", "x20 y20 w400", "To use QR Reader, you need to install Python packages:")
        installGui.Add("Text", "x20 y50 w400", "1. Make sure Python is installed from python.org")
        installGui.Add("Text", "x20 y70 w400", "2. Open command prompt and run:")
        installGui.Add("Edit", "x20 y90 w400 h20 ReadOnly").Text := "pip install opencv-python zxing-cpp pyzbar Pillow"
        installGui.Add("Text", "x20 y120 w400", "3. Close and reopen this plugin")
        
        installGui.Add("Button", "x20 y160 w120 h30", "Auto Install").OnEvent("Click", (*) => this.AutoInstallPythonEngines())
        installGui.Add("Button", "x150 y160 w100 h30", "Open Python").OnEvent("Click", (*) => Run("https://python.org"))
        installGui.Add("Button", "x320 y160 w100 h30", "Close").OnEvent("Click", (*) => installGui.Destroy())
        
        installGui.OnEvent("Escape", (*) => installGui.Destroy())
        installGui.Show("w440 h210")
    }
    
    ; Auto install Python QR engines using PowerShell
    AutoInstallPythonEngines() {
        ShowMouseTooltip("Setting up virtual environment and installing packages...", 3000)
        
        ; Create universal PowerShell setup script
        try {
            this.LogDebug("📝 Creating PowerShell setup script...")
            this.LogDebug("📂 Project root will be: " A_ScriptDir "\..")
            this.LogDebug("📂 Virtual environment will be created at: " A_ScriptDir "\..\qr_venv")
            setupScript := this.CreateUniversalSetupScript()
            this.LogDebug("✅ Setup script created at: " setupScript)
        } catch as e {
            this.LogDebug("💥 Failed to create setup script: " e.Message)
            this.LogDebug("📂 A_Temp: " A_Temp)
            this.LogDebug("📂 A_ScriptDir: " A_ScriptDir)
            this.LogDebug("📂 A_WorkingDir: " A_WorkingDir)
            throw e
        }
        
        try {
            ; Show progress dialog
            progressGui := Gui("+Owner" (IsObject(this.GUI) ? this.GUI.Hwnd : ""), "Installing QR Engines")
            progressGui.SetFont("s10", "Segoe UI")
            progressGui.Add("Text", "x20 y20 w400 Center", "🐍 Setting up Python Virtual Environment")
            statusText := progressGui.Add("Text", "x20 y50 w400 Center", "Initializing...")
            progressGui.Add("Text", "x20 y80 w400 Center", "This may take a few minutes...")
            progressGui.Show("w440 h120")
            
            ; Update status
            statusText.Text := "Creating virtual environment..."
            
            ; Run PowerShell setup script from project root directory
            psCmd := 'powershell.exe -ExecutionPolicy Bypass -File "' setupScript '"'
            
            ; Run with output capture
            tempOut := A_Temp "\qr_setup_output_" A_TickCount ".txt"
            psCmd .= ' > "' tempOut '" 2>&1'
            
            ; Run from project root to ensure correct working directory
            projectRoot := A_ScriptDir "\.."
            exitCode := RunWait(psCmd, projectRoot, "Hide")
            
            ; Read output
            output := ""
            if (FileExist(tempOut)) {
                output := FileRead(tempOut)
                FileDelete(tempOut)
            }
            
            ; Clean up setup script
            FileDelete(setupScript)
            
            progressGui.Destroy()
            
            if (exitCode = 0) {
                ShowMouseTooltip("✅ Virtual environment setup complete! QR engines ready.", 4000)
                
                ; Show success dialog with details
                this.ShowInstallationSuccess(output)
                
                ; Refresh engine status
                if (IsObject(this.GUI) && this.GUI.engineStatus) {
                    this.GUI.engineStatus.Text := this.GetEngineStatus()
                }
            } else {
                throw Error("PowerShell script failed with exit code: " exitCode)
            }
            
        } catch as e {
            if (IsObject(progressGui))
                progressGui.Destroy()
                
            this.LogDebug("💥 Auto installation failed: " e.Message)
            
            ; Try direct PowerShell command approach if script creation failed
            if (InStr(e.Message, "setup script")) {
                this.LogDebug("🔄 Trying direct PowerShell approach...")
                if (this.TryDirectPowerShellInstall()) {
                    return
                }
            }
            
            ; Show detailed error dialog
            errorGui := Gui("+Owner" (IsObject(this.GUI) ? this.GUI.Hwnd : ""), "Installation Failed")
            errorGui.SetFont("s10", "Segoe UI")
            errorGui.Add("Text", "x20 y20 w400", "❌ Automatic installation failed:")
            errorGui.Add("Edit", "x20 y50 w400 h80 ReadOnly VScroll").Text := e.Message . "`n`nOutput:`n" . (IsSet(output) ? output : "No output")
            errorGui.Add("Text", "x20 y140 w400", "Manual installation options:")
            errorGui.Add("Button", "x20 y165 w120 h30", "🛠️ Manual Steps").OnEvent("Click", (*) => this.ShowManualInstallSteps())
            errorGui.Add("Button", "x150 y165 w100 h30", "📁 Open Folder").OnEvent("Click", (*) => Run('explorer "' A_ScriptDir '"'))
            errorGui.Add("Button", "x320 y165 w100 h30", "Close").OnEvent("Click", (*) => errorGui.Destroy())
            errorGui.Show("w440 h210")
        }
    }
    
    ; Create universal PowerShell setup script
    CreateUniversalSetupScript() {
        ; Try multiple locations for the script (prefer project directory first)
        possiblePaths := [
            A_ScriptDir "\setup_qr_universal_" A_TickCount ".ps1",
            A_ScriptDir "\..\setup_qr_universal_" A_TickCount ".ps1",
            A_Temp "\setup_qr_universal_" A_TickCount ".ps1",
            A_WorkingDir "\setup_qr_universal_" A_TickCount ".ps1"
        ]
        
        scriptPath := ""
        for path in possiblePaths {
            try {
                ; Test if we can write to this location
                FileAppend("test", path)
                FileDelete(path)
                scriptPath := path
                break
            } catch {
                continue
            }
        }
        
        if (!scriptPath) {
            throw Error("Cannot find writable location for setup script")
        }
        
        script := "# Universal QR Reader Setup Script`n"
        script .= "# Compatible with any Windows computer with PowerShell`n`n"
        
        script .= "Write-Host 'QR Reader Universal Setup Script' -ForegroundColor Green`n"
        script .= "Write-Host '=====================================' -ForegroundColor Green`n`n"
        
        script .= "# Set execution policy for this session`n"
        script .= "Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force`n`n"
        
        script .= "# Use the correct project directory (passed from AHK script)`n"
        projectDir := StrReplace(A_ScriptDir "\..", "\", "\\")
        script .= "$ProjectDir = '" projectDir "'`n"
        script .= "Write-Host `"Using project directory: $ProjectDir`" -ForegroundColor Yellow`n"
        script .= "Write-Host `"Virtual environment will be: $ProjectDir\\qr_venv`" -ForegroundColor Cyan`n`n"
        
        script .= "# Set virtual environment path`n"
        script .= "$VenvPath = Join-Path $ProjectDir 'qr_venv'`n"
        script .= "Write-Host `"Virtual environment will be created at: $VenvPath`" -ForegroundColor Yellow`n`n"
        
        script .= "# Function to find Python executable`n"
        script .= "function Find-Python {`n"
        script .= "    $pythonCandidates = @('python', 'py', 'python3')`n"
        script .= "    foreach ($candidate in $pythonCandidates) {`n"
        script .= "        try {`n"
        script .= "            $version = & $candidate --version 2>$null`n"
        script .= "            if ($version -match 'Python') {`n"
        script .= "                Write-Host `"Found Python: $candidate ($version)`" -ForegroundColor Green`n"
        script .= "                return $candidate`n"
        script .= "            }`n"
        script .= "        } catch { }`n"
        script .= "    }`n"
        script .= "    return $null`n"
        script .= "}`n`n"
        
        script .= "# Check for Python`n"
        script .= "Write-Host 'Checking for Python installation...' -ForegroundColor Cyan`n"
        script .= "$pythonCmd = Find-Python`n"
        script .= "if (-not $pythonCmd) {`n"
        script .= "    Write-Host 'ERROR: Python not found!' -ForegroundColor Red`n"
        script .= "    Write-Host 'Please install Python from https://python.org and add it to PATH' -ForegroundColor Red`n"
        script .= "    exit 1`n"
        script .= "}`n`n"
        
        script .= "# Remove existing virtual environment if it exists`n"
        script .= "if (Test-Path $VenvPath) {`n"
        script .= "    Write-Host 'Removing existing virtual environment...' -ForegroundColor Yellow`n"
        script .= "    Remove-Item -Path $VenvPath -Recurse -Force -ErrorAction SilentlyContinue`n"
        script .= "}`n`n"
        
        script .= "# Create virtual environment`n"
        script .= "Write-Host 'Creating virtual environment...' -ForegroundColor Cyan`n"
        script .= "try {`n"
        script .= "    & $pythonCmd -m venv `"$VenvPath`"`n"
        script .= "    if ($LASTEXITCODE -ne 0) { throw 'venv creation failed' }`n"
        script .= "    Write-Host '✓ Virtual environment created successfully' -ForegroundColor Green`n"
        script .= "} catch {`n"
        script .= "    Write-Host 'ERROR: Failed to create virtual environment' -ForegroundColor Red`n"
        script .= "    Write-Host 'Trying to install virtualenv and retry...' -ForegroundColor Yellow`n"
        script .= "    & $pythonCmd -m pip install virtualenv`n"
        script .= "    & $pythonCmd -m virtualenv `"$VenvPath`"`n"
        script .= "    if ($LASTEXITCODE -ne 0) {`n"
        script .= "        Write-Host 'ERROR: Virtual environment creation failed' -ForegroundColor Red`n"
        script .= "        exit 1`n"
        script .= "    }`n"
        script .= "}`n`n"
        
        script .= "# Set virtual environment Python path`n"
        script .= "$VenvPython = Join-Path $VenvPath 'Scripts\\python.exe'`n"
        script .= "if (-not (Test-Path $VenvPython)) {`n"
        script .= "    Write-Host 'ERROR: Virtual environment Python not found' -ForegroundColor Red`n"
        script .= "    exit 1`n"
        script .= "}`n`n"
        
        script .= "# Upgrade pip in virtual environment`n"
        script .= "Write-Host 'Upgrading pip in virtual environment...' -ForegroundColor Cyan`n"
        script .= "& `"$VenvPython`" -m pip install --upgrade pip`n`n"
        
        script .= "# Install QR packages`n"
        script .= "Write-Host 'Installing QR Reader packages...' -ForegroundColor Cyan`n"
        script .= "$packages = @('opencv-python', 'zxing-cpp', 'pyzbar', 'Pillow', 'numpy')`n"
        script .= "foreach ($package in $packages) {`n"
        script .= "    Write-Host `"Installing $package...`" -ForegroundColor Yellow`n"
        script .= "    & `"$VenvPython`" -m pip install $package`n"
        script .= "    if ($LASTEXITCODE -eq 0) {`n"
        script .= "        Write-Host `"✓ $package installed successfully`" -ForegroundColor Green`n"
        script .= "    } else {`n"
        script .= "        Write-Host `"⚠ $package installation had issues (continuing...)`" -ForegroundColor Yellow`n"
        script .= "    }`n"
        script .= "}`n`n"
        
        script .= "# Test installations`n"
        script .= "Write-Host 'Testing package installations...' -ForegroundColor Cyan`n"
        script .= "$testResults = @()`n"
        script .= "$testPackages = @(`n"
        script .= "    @{Name='OpenCV'; Import='cv2'},`n"
        script .= "    @{Name='zxing-cpp'; Import='zxingcpp'},`n"
        script .= "    @{Name='pyzbar'; Import='pyzbar'},`n"
        script .= "    @{Name='Pillow'; Import='PIL'}`n"
        script .= ")`n`n"
        
        script .= "foreach ($pkg in $testPackages) {`n"
        script .= "    try {`n"
        script .= "        $testCmd = `"import $($pkg.Import); print('OK')`"`n"
        script .= "        $result = & `"$VenvPython`" -c $testCmd 2>$null`n"
        script .= "        if ($result -eq 'OK') {`n"
        script .= "            Write-Host `"✓ $($pkg.Name) working`" -ForegroundColor Green`n"
        script .= "            $testResults += `"$($pkg.Name): OK`"`n"
        script .= "        } else {`n"
        script .= "            Write-Host `"✗ $($pkg.Name) test failed`" -ForegroundColor Red`n"
        script .= "            $testResults += `"$($pkg.Name): FAILED`"`n"
        script .= "        }`n"
        script .= "    } catch {`n"
        script .= "        Write-Host `"✗ $($pkg.Name) import error`" -ForegroundColor Red`n"
        script .= "        $testResults += `"$($pkg.Name): ERROR`"`n"
        script .= "    }`n"
        script .= "}`n`n"
        
        script .= "# Final summary`n"
        script .= "Write-Host '`nInstallation Summary:' -ForegroundColor Green`n"
        script .= "Write-Host '===================' -ForegroundColor Green`n"
        script .= "Write-Host `"Virtual Environment: $VenvPath`" -ForegroundColor Cyan`n"
        script .= "Write-Host `"Python Executable: $VenvPython`" -ForegroundColor Cyan`n"
        script .= "Write-Host '`nPackage Test Results:' -ForegroundColor Cyan`n"
        script .= "foreach ($result in $testResults) {`n"
        script .= "    Write-Host $result -ForegroundColor $(if ($result -match 'OK') { 'Green' } else { 'Red' })`n"
        script .= "}`n`n"
        
        script .= "Write-Host '`n✓ QR Reader setup complete!' -ForegroundColor Green`n"
        script .= "Write-Host 'You can now use the QR Reader plugin.' -ForegroundColor Green`n"
        
        try {
            ; Clean up any existing script
            if (FileExist(scriptPath)) {
                FileDelete(scriptPath)
            }
            
            ; Create the script
            FileAppend(script, scriptPath)
            
            ; Verify the script was created
            if (!FileExist(scriptPath)) {
                throw Error("Script file was not created")
            }
            
            ; Verify we can read it back
            testContent := FileRead(scriptPath)
            if (StrLen(testContent) < 100) {
                throw Error("Script content appears incomplete")
            }
            
        } catch as e {
            throw Error("Failed to create setup script: " e.Message)
        }
        
        return scriptPath
    }
    
    ; Show installation success dialog
    ShowInstallationSuccess(output) {
        successGui := Gui("+Owner" (IsObject(this.GUI) ? this.GUI.Hwnd : ""), "Installation Complete")
        successGui.SetFont("s10", "Segoe UI")
        
        successGui.Add("Text", "x20 y20 w400 Center", "🎉 QR Reader Setup Complete!").SetFont("s12 Bold")
        successGui.Add("Text", "x20 y50 w400 Center", "Virtual environment created with all packages installed")
        
        ; Show package status
        successGui.Add("Text", "x20 y80", "Package Status:")
        statusEdit := successGui.Add("Edit", "x20 y100 w400 h100 ReadOnly VScroll")
        
        ; Parse output for package status
        statusText := "Virtual Environment: ✅ Created`n"
        if (InStr(output, "OpenCV") && InStr(output, "OK")) {
            statusText .= "OpenCV: ✅ Working`n"
        }
        if (InStr(output, "zxing-cpp") && InStr(output, "OK")) {
            statusText .= "zxing-cpp: ✅ Working`n"
        }
        if (InStr(output, "pyzbar") && InStr(output, "OK")) {
            statusText .= "pyzbar: ✅ Working`n"
        }
        if (InStr(output, "Pillow") && InStr(output, "OK")) {
            statusText .= "Pillow: ✅ Working`n"
        }
        statusText .= "`nYou can now scan QR codes with all three engines!"
        
        statusEdit.Text := statusText
        
        successGui.Add("Button", "x20 y220 w100 h30", "🔍 Test Now").OnEvent("Click", (*) => (successGui.Destroy(), this.RunDiagnostics()))
        successGui.Add("Button", "x130 y220 w100 h30", "📄 View Log").OnEvent("Click", (*) => this.ShowDetailedOutput(output))
        successGui.Add("Button", "x320 y220 w100 h30", "Close").OnEvent("Click", (*) => successGui.Destroy())
        
        successGui.Show("w440 h270")
    }
    
    ; Show manual installation steps
    ShowManualInstallSteps() {
        manualGui := Gui("+Owner" (IsObject(this.GUI) ? this.GUI.Hwnd : ""), "Manual Installation")
        manualGui.SetFont("s10", "Segoe UI")
        
        manualGui.Add("Text", "x20 y20 w400", "Manual Installation Steps:").SetFont("s12 Bold")
        
        steps := "1. Open Command Prompt or PowerShell as Administrator`n`n"
        steps .= "2. Navigate to project root directory:`n"
        steps .= "   cd `"" A_ScriptDir "\.." "`"`n`n"
        steps .= "3. Create virtual environment:`n"
        steps .= "   python -m venv qr_venv`n`n"
        steps .= "4. Activate virtual environment:`n"
        steps .= "   qr_venv\\Scripts\\activate`n`n"
        steps .= "5. Install packages:`n"
        steps .= "   pip install opencv-python zxing-cpp pyzbar Pillow`n`n"
        steps .= "6. Test installation:`n"
        steps .= "   python -c `"import cv2, zxingcpp, pyzbar, PIL; print('All OK')`"`n`n"
        steps .= "Alternative: Use existing batch file if available:`n"
        steps .= "   setup_qr_venv.bat"
        
        stepsEdit := manualGui.Add("Edit", "x20 y50 w400 h200 ReadOnly VScroll")
        stepsEdit.Text := steps
        
        manualGui.Add("Button", "x20 y260 w100 h30", "📋 Copy Steps").OnEvent("Click", (*) => (A_Clipboard := steps, ShowMouseTooltip("Steps copied to clipboard", 2000)))
        manualGui.Add("Button", "x130 y260 w100 h30", "📁 Open Folder").OnEvent("Click", (*) => Run('explorer "' A_ScriptDir '"'))
        manualGui.Add("Button", "x320 y260 w100 h30", "Close").OnEvent("Click", (*) => manualGui.Destroy())
        
        manualGui.Show("w440 h310")
    }
    
    ; Show detailed output
    ShowDetailedOutput(output) {
        outputGui := Gui("+Owner" (IsObject(this.GUI) ? this.GUI.Hwnd : ""), "Installation Log")
        outputGui.SetFont("s9", "Consolas")
        
        outputGui.Add("Text", "x20 y20 w500", "Detailed Installation Log:").SetFont("s10 Bold", "Segoe UI")
        outputEdit := outputGui.Add("Edit", "x20 y50 w500 h300 ReadOnly VScroll")
        outputEdit.Text := output
        
        outputGui.Add("Button", "x20 y360 w100 h30", "📋 Copy Log").OnEvent("Click", (*) => (A_Clipboard := output, ShowMouseTooltip("Log copied to clipboard", 2000)))
        outputGui.Add("Button", "x420 y360 w100 h30", "Close").OnEvent("Click", (*) => outputGui.Destroy())
        
        outputGui.Show("w540 h410")
    }
    
    ; Try direct PowerShell installation without script files
    TryDirectPowerShellInstall() {
        try {
            this.LogDebug("🔧 Attempting direct PowerShell installation...")
            
            ; Simple direct commands with correct project root path
            projectRoot := A_ScriptDir "\.."
            venvPath := projectRoot "\qr_venv"
            venvPython := venvPath "\Scripts\python.exe"
            
            this.LogDebug("📂 Project root: " projectRoot)
            this.LogDebug("📂 Virtual environment path: " venvPath)
            this.LogDebug("📂 Virtual environment Python: " venvPython)
            
            commands := [
                'python -m venv "' venvPath '"',
                '"' venvPython '" -m pip install --upgrade pip',
                '"' venvPython '" -m pip install opencv-python zxing-cpp pyzbar Pillow numpy'
            ]
            
            progressGui := Gui("+Owner" (IsObject(this.GUI) ? this.GUI.Hwnd : ""), "Direct Installation")
            progressGui.SetFont("s10", "Segoe UI")
            progressGui.Add("Text", "x20 y20 w400 Center", "🔧 Direct PowerShell Installation")
            statusText := progressGui.Add("Text", "x20 y50 w400 Center", "Creating virtual environment...")
            progressGui.Show("w440 h100")
            
            for i, cmd in commands {
                statusText.Text := "Step " i "/3: " (i=1 ? "Creating venv..." : i=2 ? "Upgrading pip..." : "Installing packages...")
                
                this.LogDebug("⚡ Running: " cmd)
                exitCode := RunWait('powershell -ExecutionPolicy Bypass -Command "' cmd '"', projectRoot, "Hide")
                
                if (exitCode != 0 && i = 1) {
                    ; Try with py command if python failed
                    altCmd := StrReplace(cmd, "python", "py")
                    this.LogDebug("⚡ Retrying with: " altCmd)
                    exitCode := RunWait('powershell -ExecutionPolicy Bypass -Command "' altCmd '"', projectRoot, "Hide")
                }
                
                if (exitCode != 0) {
                    this.LogDebug("❌ Command failed with exit code: " exitCode)
                    progressGui.Destroy()
                    return false
                }
            }
            
            progressGui.Destroy()
            
            ; Test the installation
            testCmd := '"' venvPython '" -c "import cv2, zxingcpp, pyzbar, PIL; print(\"OK\")"'
            exitCode := RunWait('powershell -ExecutionPolicy Bypass -Command "' testCmd '"', projectRoot, "Hide", &testOutput)
            
            if (exitCode = 0 && InStr(testOutput, "OK")) {
                this.LogDebug("✅ Direct installation successful!")
                ShowMouseTooltip("✅ Direct installation completed successfully!", 4000)
                
                ; Refresh engine status
                if (IsObject(this.GUI) && this.GUI.engineStatus) {
                    this.GUI.engineStatus.Text := this.GetEngineStatus()
                }
                
                return true
            } else {
                this.LogDebug("❌ Direct installation test failed")
                return false
            }
            
        } catch as e {
            this.LogDebug("💥 Direct installation error: " e.Message)
            return false
        }
    }
    
    ; Show help
    ShowHelp() {
        helpText := "Ultra-Fast QR Reader v2.1 Help`n`n"
        helpText .= "Hotkeys:`n"
        helpText .= "Alt+Q - Open QR Scanner (primary)`n"
        helpText .= "Ctrl+Alt+Q - Open QR Scanner (legacy)`n"
        helpText .= "Ctrl+Alt+W - Lightning fast full screen scan`n`n"
        helpText .= "Speed Features:`n"
        helpText .= "⚡ Engine caching - avoid repeated availability checks`n"
        helpText .= "⚡ Batch file reuse - skip recreation for 5 minutes`n"
        helpText .= "⚡ Optimized Python code - minimal imports and variables`n"
        helpText .= "⚡ Smart engine selection - based on image size`n"
        helpText .= "⚡ Background cleanup - non-blocking file operations`n"
        helpText .= "⚡ Immediate feedback - instant clipboard and sound`n`n"
        helpText .= "Engine Performance (speed optimized):`n"
        helpText .= "1. pyzbar - Ultra-fast for small images`n"
        helpText .= "2. zxing-cpp - Fast and reliable for large images`n"
        helpText .= "3. OpenCV - Robust for damaged/artistic QR codes`n`n"
        helpText .= "Setup:`n"
        helpText .= "• Use 'Install' button for automated virtual environment`n"
        helpText .= "• Manual: pip install opencv-python zxing-cpp pyzbar Pillow`n"
        helpText .= "• Requires Python 3.6+ (virtual environment recommended)"
        
        TopMsgBox(helpText, "Ultra-Fast QR Reader Help", "Iconi")
    }
    
    ; Show settings dialog
    ShowSettings() {
        this.ShowQRScanner()
    }
    
    ; Simple JSON parser for the expected QR result format
    ParseJSON(jsonString) {
        ; Log raw JSON for debugging
        this.LogDebug("🔍 Raw JSON received: " jsonString)
        
        ; Clean up the string
        jsonString := Trim(jsonString)
        
        ; Basic validation
        if (!InStr(jsonString, "{") || !InStr(jsonString, "}")) {
            this.LogDebug("❌ JSON validation failed - no braces found")
            throw Error("Invalid JSON format")
        }
            
        ; Create result object
        result := {}
        
        ; Parse success field
        if (InStr(jsonString, '"success":true') || InStr(jsonString, '"success": true'))
            result.success := true
        else
            result.success := false
            
        ; Parse data field
        dataMatch := RegExMatch(jsonString, '"data"\s*:\s*"([^"]*)"', &match)
        if (dataMatch)
            result.data := match[1]
        else
            result.data := ""
            
        ; Parse error field
        errorMatch := RegExMatch(jsonString, '"error"\s*:\s*"([^"]*)"', &match)
        if (errorMatch)
            result.error := match[1]
        else
            result.error := ""
            
        ; Parse engine field
        engineMatch := RegExMatch(jsonString, '"engine"\s*:\s*"([^"]*)"', &match)
        if (engineMatch)
            result.engine := match[1]
        else
            result.engine := "Unknown"
            
        this.LogDebug("✅ JSON parsed - success: " result.success ", data length: " StrLen(result.data) ", error: " result.error)
        return result
    }
    
    ; Cleanup and destroy GUI properly
    CleanupAndDestroy() {
        try {
            ; Clear performance resources to prevent memory leaks
            this.CleanupPerformanceResources()
            
            ; Cleanup external debug window
            try {
                if (this.HasProp("DebugGUI") && IsObject(this.DebugGUI)) {
                    this.DebugGUI.Destroy()
                    this.DeleteProp("DebugGUI")
                }
                if (this.HasProp("DebugLogEdit")) {
                    this.DeleteProp("DebugLogEdit")
                }
            } catch {
                ; Ignore debug window cleanup errors
            }
            
            ; Mark GUI as being destroyed to prevent further access
            if (IsObject(this.GUI)) {
                ; Remove all property references to prevent access after destruction
                if (this.GUI.HasProp("debugStatus"))
                    this.GUI.DeleteProp("debugStatus")
                if (this.GUI.HasProp("statusText"))
                    this.GUI.DeleteProp("statusText")
                if (this.GUI.HasProp("engineStatus"))
                    this.GUI.DeleteProp("engineStatus")
                if (this.GUI.HasProp("resultEdit"))
                    this.GUI.DeleteProp("resultEdit")
                if (this.GUI.HasProp("clipboardCheck"))
                    this.GUI.DeleteProp("clipboardCheck")
                if (this.GUI.HasProp("soundCheck"))
                    this.GUI.DeleteProp("soundCheck")
                
                ; Destroy the GUI
                this.GUI.Destroy()
            }
        } catch {
            ; If cleanup fails, force destroy
            try {
                if (IsObject(this.GUI))
                    this.GUI.Destroy()
            } catch {
                ; Ignore final cleanup errors
            }
        }
    }
}
