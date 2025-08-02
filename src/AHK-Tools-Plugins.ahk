#Requires AutoHotkey v2.0-*  ; Ensures only v2.x versions are used

; =================== GLOBAL MESSAGE BOX FUNCTIONS ===================
; These functions must be defined first so they're available to included files

; Helper function to convert string options to numeric
ConvertMsgBoxOptions(options := "") {
    if (Type(options) = "String") {
        numericOptions := 0
        
        ; Parse common option strings
        if (InStr(options, "YesNo"))
            numericOptions |= 0x4  ; 4 = Yes/No buttons
        if (InStr(options, "Icon!"))
            numericOptions |= 0x30  ; 48 = Exclamation icon
        if (InStr(options, "Iconx"))
            numericOptions |= 0x10  ; 16 = Error icon
        if (InStr(options, "Icon?"))
            numericOptions |= 0x20  ; 32 = Question icon
        if (InStr(options, "Iconi"))
            numericOptions |= 0x40  ; 64 = Information icon
        if (InStr(options, "T"))
            numericOptions |= 0x1000  ; Timeout (will need number parsing)
            
        return numericOptions
    }
    return options
}

; Helper function for always-on-top message boxes
TopMsgBox(text, title := "AHK Tools", options := "") {
    ; Convert string options to numeric if needed
    options := ConvertMsgBoxOptions(options)
    
    ; Add AlwaysOnTop option (262144) to existing options
    options := options | 0x40000  ; 0x40000 = 262144 = AlwaysOnTop
    return MsgBox(text, title, options)
}

; Helper function for regular message boxes (converts string options to numeric)
SafeMsgBox(text, title := "", options := "") {
    ; Convert string options to numeric if needed
    options := ConvertMsgBoxOptions(options)
    return MsgBox(text, title, options)
}

; Global variables for mouse-following tooltip
global g_mouseTooltipText := ""
global g_mouseTooltipActive := false
global g_lastMouseX := -1
global g_lastMouseY := -1

; Function to update tooltip position - called by timer (optimized for performance)
UpdateMouseTooltip() {
    global g_mouseTooltipText, g_mouseTooltipActive, g_lastMouseX, g_lastMouseY
    if (!g_mouseTooltipActive) {
        return
    }
    
    MouseGetPos(&x, &y)
    ; Only update if mouse position changed by at least 5 pixels (reduces unnecessary updates)
    if (Abs(x - g_lastMouseX) >= 5 || Abs(y - g_lastMouseY) >= 5) {
        ; Use a slightly larger offset and position to avoid cursor overlap
        ToolTip(g_mouseTooltipText, x + 20, y + 20)
        g_lastMouseX := x
        g_lastMouseY := y
    }
}

; Function to hide tooltip - called by timer
HideMouseTooltip() {
    global g_mouseTooltipActive, g_lastMouseX, g_lastMouseY
    ToolTip()
    g_mouseTooltipActive := false
    g_lastMouseX := -1
    g_lastMouseY := -1
    SetTimer(UpdateMouseTooltip, 0)
}

; Helper function for mouse-following tooltips
ShowMouseTooltip(text, duration := 2000) {
    global g_mouseTooltipText, g_mouseTooltipActive, g_lastMouseX, g_lastMouseY
    
    ; Clear any existing tooltip and stop updates
    ToolTip()
    SetTimer(UpdateMouseTooltip, 0)
    SetTimer(HideMouseTooltip, 0)
    
    ; Set up new tooltip
    g_mouseTooltipText := text
    g_mouseTooltipActive := true
    
    ; Get initial mouse position
    MouseGetPos(&x, &y)
    g_lastMouseX := x
    g_lastMouseY := y
    
    ; Show tooltip immediately at current position with larger offset
    ToolTip(g_mouseTooltipText, x + 20, y + 20)
    
    ; Start updating position every 16ms (60 FPS - smooth like games)
    SetTimer(UpdateMouseTooltip, 16)
    
    ; Auto-hide after duration
    SetTimer(HideMouseTooltip, -duration)
}

; Test function for mouse tooltip (Win + F11)
TestMouseTooltip() {
    ShowMouseTooltip("🎯 Mouse tooltip test! Move your mouse to see this tooltip follow you!", 5000)
}

; =================== VERSION CHECK ===================
if (SubStr(A_AhkVersion, 1, 1) != "2") {
    TopMsgBox("This script requires AutoHotkey v2. You are using " A_AhkVersion, "Version Error", "Iconx")
    ExitApp
}

; =================== STARTUP PROTECTION ===================
; Global startup protection flag to prevent phantom hotkey triggers
global g_startupComplete := false
global g_hotkeysEnabled := false

; Timer to enable hotkeys after startup delay
global g_enableHotkeysTimer := ""

; Function to enable hotkeys after startup delay
EnableHotkeys() {
    global g_hotkeysEnabled, g_startupComplete
    
    try {
        ; Mark startup as complete
        g_startupComplete := true
        g_hotkeysEnabled := true
        
        ; Apply dynamic hotkeys (this will be called again after delay)
        SetupDynamicHotkeys()
        
        ; Now it's safe to check environment (after startup delay)
        CheckEnvironment()
        
        ; Clear the timer reference
        global g_enableHotkeysTimer
        g_enableHotkeysTimer := ""
        
        ; Optional notification
        global g_settingsManager
        if (g_settingsManager && g_settingsManager.GetSetting("General_ShowNotifications", true)) {
            ShowMouseTooltip("All hotkeys are now active", 1000)
        }
        
    } catch as e {
        ; Log error but don't crash
        OutputDebug "Error enabling hotkeys: " e.Message
    }
}

; =================== CONFIGURATION SECTION ===================
; Configuration variables
global CONFIG := {
    appName: "AHK Tools for power users",
    version: "2.1.0",
    author: "Ahmed N. Alfahdi",
    GitHub: "https://github.com/ahmedalfahdi",
    ; Existing configurations
    tooltipDuration: 3000,    ; Duration in milliseconds for tooltips
    defaultSound: true,       ; Play sound on notifications
    logFilePath: "C:\\Logs\\ahk_tools.log",  ; Path to the log file
    maxRetries: 5,            ; Maximum number of retries for operations

    ; Additional configurations
    debugMode: false,         ; Enable detailed logging for debugging
    autoSaveInterval: 60000,  ; Auto-save interval in milliseconds (e.g., for state or settings)
    runAtStartup: true,       ; Whether the script should launch on system startup
    defaultLanguage: "en",    ; Default language code for messages
    opacity: 230,            ; Window opacity (0 = fully transparent, 255 = fully opaque)
    
    ; Plugin system settings
    enablePlugins: true,      ; Whether to enable the plugin system
    pluginsPath: A_ScriptDir "\plugins"  ; Path to plugins directory
}

; =================== INCLUDE PLUGIN SYSTEM ===================
; Include with error handling
try {
    #Include PluginSystem.ahk
} catch as e {
    TopMsgBox("Error loading PluginSystem.ahk: " e.Message "`n`nPlugin functionality will be disabled.", "Missing Dependency", "Iconx")
    ExitApp
}

try {
    #Include SettingsManager.ahk
} catch as e {
    TopMsgBox("Error loading SettingsManager.ahk: " e.Message "`n`nSettings functionality will be disabled.", "Missing Dependency", "Iconx")
    ExitApp
}

; =================== INCLUDE PLUGINS ===================
; Include all plugin files so their classes are available
try {
    #Include plugins\CurrencyConverter.ahk
} catch as e {
    ; Plugin not available, continue without it
}

try {
    #Include plugins\AutoCompletion.ahk
} catch as e {
    ; Plugin not available, continue without it
}

try {
    #Include plugins\UnitConverter.ahk
} catch as e {
    ; Plugin not available, continue without it
}

; WiFiReconnect, QRReader, and EmailPasswordManager plugins have been deprecated

; =================== GLOBAL VARIABLES ===================
; Global variables for plugin and settings management
; These will be initialized in InitPluginSystem()
global g_pluginManager := ""
global g_settingsManager := ""

; Error handling and initialization state
global g_initializationComplete := false
global g_errorCount := 0

; Cleanup function for proper exit
OnExit(CleanupOnExit)

CleanupOnExit(ExitReason, ExitCode) {
    try {
        ; Clear timers
        global g_enableHotkeysTimer
        if (g_enableHotkeysTimer) {
            SetTimer(g_enableHotkeysTimer, 0)
        }
        
        ; Clear dynamic hotkeys
        ClearDynamicHotkeys()
        
        ; Clear global references
        global g_pluginManager, g_settingsManager
        g_pluginManager := ""
        g_settingsManager := ""
        
    } catch {
        ; Ignore cleanup errors
    }
}

; =================== UTILITY FUNCTIONS SECTION ===================
; URL encoding utility
UrlEncode(str) {
    ; Basic URL encoding function
    chars := Map(
        " ", "%20", "!", "%21", "#", "%23", "$", "%24",
        "&", "%26", "'", "%27", "(", "%28", ")", "%29",
        "*", "%2A", "+", "%2B", ",", "%2C", "/", "%2F",
        ":", "%3A", ";", "%3B", "=", "%3D", "?", "%3F",
        "@", "%40", "[", "%5B", "]", "%5D"
    )
    
    encoded := ""
    loop parse str {
        encoded .= chars.Has(A_LoopField) ? chars[A_LoopField] : A_LoopField
    }
    return encoded
}

; Language detection utility
DetectLanguage(code) {
    ; Check for Python
    if (InStr(code, "def ") || InStr(code, "import ") || InStr(code, "class ") || InStr(code, "lambda ")) {
        return "py"
    }
    ; Check for JavaScript/TypeScript
    if (InStr(code, "function ") || InStr(code, "const ") || InStr(code, "let ") || InStr(code, "export ")) {
        return "js"
    }
    ; Check for HTML
    if (InStr(code, "<html") || InStr(code, "<div") || InStr(code, "<p") || InStr(code, "<head")) {
        return "html"
    }
    ; Check for CSS
    if (InStr(code, "{") && InStr(code, "}") && InStr(code, ":")) {
        return "css"
    }
    ; Check for C/C++
    if (InStr(code, "#include ") || InStr(code, "int main(") || InStr(code, "std::")) {
        return "cpp"
    }
    ; Check for Java
    if (InStr(code, "public class ") || InStr(code, "System.out.println")) {
        return "java"
    }
    ; Check for C#
    if (InStr(code, "using ") || InStr(code, "namespace ") || InStr(code, "Console.WriteLine")) {
        return "cs"
    }
    ; Check for PHP
    if (InStr(code, "<?php") || InStr(code, "echo ") || InStr(code, "$")) {
        return "php"
    }
    ; Check for Ruby
    if (InStr(code, "def ") || InStr(code, "puts ") || InStr(code, "end")) {
        return "rb"
    }
    ; Check for Go
    if (InStr(code, "package ") || InStr(code, "func ") || InStr(code, "fmt.Println")) {
        return "go"
    }
    ; Check for Rust
    if (InStr(code, "fn ") || InStr(code, "println!") || InStr(code, "let ")) {
        return "rs"
    }
    ; Check for Shell/Bash
    if (InStr(code, "#!/bin/bash") || InStr(code, "echo ") || InStr(code, "$")) {
        return "sh"
    }
    ; Check for PowerShell
    if (InStr(code, "Write-Host ") || InStr(code, "$")) {
        return "ps1"
    }
    ; Check for SQL
    if (InStr(code, "SELECT ") || InStr(code, "FROM ") || InStr(code, "WHERE ")) {
        return "sql"
    }
    ; Check for JSON
    if (InStr(code, "{") && InStr(code, "}") && InStr(code, ":")) {
        return "json"
    }
    ; Check for XML
    if (InStr(code, "<") && InStr(code, ">") && InStr(code, "</")) {
        return "xml"
    }
    ; Check for Markdown
    if (InStr(code, "#") && (InStr(code, "*") || InStr(code, "_")) && (InStr(code, "[") && InStr(code, "]"))) {
        return "md"
    }
    ; Default to .txt for unknown code
    return "txt"
}

; Theme management functions
ApplyThemeToGui(gui) {
    try {
        ; Soft light gray background - much easier on the eyes than blazing white
        gui.BackColor := 0xF5F5F5  ; Soft light gray instead of harsh white
        gui.SetFont("s9", "Segoe UI")
        
        ; Apply consistent modern styling
        for control in gui {
            switch control.Type {
                case "Text":
                    control.SetFont("s9", "Segoe UI")
                case "Edit":
                    control.SetFont("s9", "Segoe UI")
                case "Button":
                    control.SetFont("s9", "Segoe UI")
                case "ComboBox", "DropDownList":
                    control.SetFont("s9", "Segoe UI")
            }
        }
        
    } catch as e {
        ; Fallback: just use system defaults
    }
}

ShowTimeTooltip() {
    if (SubStr(A_AhkVersion, 1, 1) != "2") {
        MsgBox "Error: V2 required"
        return
    }
    currentTime := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    ShowMouseTooltip(currentTime, CONFIG.tooltipDuration)
}

ShowAbout(*) {
    ; Create retro-styled about page
    aboutGui := Gui("+AlwaysOnTop", "About - AHK Tools v" CONFIG.version)
    aboutGui.SetFont("s9", "Courier New")  ; Retro monospace font
    aboutGui.BackColor := 0x000080  ; Classic blue background
    
    ; ASCII art title - multi-line (with more vertical spacing)
    titleText1 := aboutGui.Add("Text", "x30 y30 w480 Center c0xFFFF00", " █████╗ ██╗  ██╗██╗  ██╗")
    titleText1.SetFont("s12 Bold", "Courier New")
    titleText2 := aboutGui.Add("Text", "x30 y50 w480 Center c0xFFFF00", "██╔══██╗██║  ██║██║ ██╔╝")
    titleText2.SetFont("s12 Bold", "Courier New")
    titleText3 := aboutGui.Add("Text", "x30 y70 w480 Center c0xFFFF00", "███████║███████║█████╔╝ ")
    titleText3.SetFont("s12 Bold", "Courier New")
    titleText4 := aboutGui.Add("Text", "x30 y90 w480 Center c0xFFFF00", "██╔══██║██╔══██║██╔═██╗ ")
    titleText4.SetFont("s12 Bold", "Courier New")
    titleText5 := aboutGui.Add("Text", "x30 y110 w480 Center c0xFFFF00", "██║  ██║██║  ██║██║  ██╗")
    titleText5.SetFont("s12 Bold", "Courier New")
    titleText6 := aboutGui.Add("Text", "x30 y130 w480 Center c0xFFFF00", "╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝")
    titleText6.SetFont("s12 Bold", "Courier New")
    
    ; Tools subtitle (fixed positioning and height)
    toolsText := aboutGui.Add("Text", "x30 y155 w480 h30 Center c0xFFFF00", "TOOLS")
    toolsText.SetFont("s14 Bold", "Courier New")
    
    ; Subtitle in retro style
    subtitleText := aboutGui.Add("Text", "x30 y195 w480 Center c0x00FFFF", "◄ PRODUCTIVITY AUTOMATION SUITE ►")
    subtitleText.SetFont("s10", "Courier New")
    
    ; Retro separator
    separator1 := aboutGui.Add("Text", "x30 y235 w480 Center c0xFFFFFF", "══════════════════════════════════════════════════════")
    
    ; Version info in retro style
    versionText := aboutGui.Add("Text", "x30 y275 w480 Center c0x00FF00", "VERSION: " CONFIG.version)
    versionText.SetFont("s12 Bold", "Courier New")
    
    ; Author info in retro style
    authorText := aboutGui.Add("Text", "x30 y310 w480 Center c0x00FF00", "SCRIPTED BY: " CONFIG.author)
    authorText.SetFont("s12 Bold", "Courier New")
    
    ; GitHub link in retro style (properly centered)
    linkText := aboutGui.Add("Text", "x30 y350 w480 Center c0xFFFF00", "► VISIT GITHUB REPOSITORY ◄")
    linkText.SetFont("s10", "Courier New")
    linkText.OnEvent("Click", (*) => Run(CONFIG.GitHub))
    
    ; Bottom separator
    separator2 := aboutGui.Add("Text", "x30 y390 w480 Center c0xFFFFFF", "══════════════════════════════════════════════════════")
    
    ; Retro copyright style
    copyrightText := aboutGui.Add("Text", "x30 y425 w480 Center c0x808080", "2024 - OPEN SOURCE MIT LICENSE - COPYLEFT")
    copyrightText.SetFont("s9", "Courier New")
    
    ; Help and OK buttons in retro style
    helpBtn := aboutGui.Add("Button", "x185 y465 w80 h35", "[ HELP ]")
    helpBtn.SetFont("s11 Bold", "Courier New")
    helpBtn.OnEvent("Click", (*) => ShowHelpDialog())
    
    okBtn := aboutGui.Add("Button", "x275 y465 w80 h35", "[ OK ]")
    okBtn.SetFont("s11 Bold", "Courier New")
    okBtn.OnEvent("Click", (*) => aboutGui.Destroy())
    
    ; Escape key handler
    aboutGui.OnEvent("Escape", (*) => aboutGui.Destroy())
    
    ; Show the dialog
    aboutGui.Show("w540 h520")
    
    ; Focus the OK button
    okBtn.Focus()
}

ReloadScript(*) {
    Reload
}

CheckAdminRequired() {
    global g_startupComplete
    
    ; Skip admin check during startup to prevent unwanted dialogs
    if (!g_startupComplete) {
        return false  ; Return false to abort admin-requiring functions during startup
    }
    
    if !A_IsAdmin {
        ; Create a warning GUI
        adminGui := Gui("+AlwaysOnTop", "Admin Required")
        adminGui.SetFont("s10", "Segoe UI")
        adminGui.Add("Text",, "This feature requires administrator privileges.")
        adminGui.Add("Text",, "Would you like to reload the script as admin?")
        
        ; Add buttons
        adminGui.Add("Button", "Default w100", "Yes").OnEvent("Click", (*) => ReloadAsAdmin())
        adminGui.Add("Button", "w100", "No").OnEvent("Click", (*) => adminGui.Destroy())
        
        ; Apply theme
        ApplyThemeToGui(adminGui)
        
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
    } catch as e {
        TopMsgBox("Error reloading as admin: " e.Message, "Error", "Iconx")
    }
    ExitApp
}

ExitScript(*) {
    ExitApp
}

; =================== SCRIPT INITIALIZATION ===================
; Ensure single instance
#SingleInstance Force

; Initialize the script
InitializeScript()

InitializeScript() {
    global g_initializationComplete, g_enableHotkeysTimer
    
    try {
        ; Initialize components in safe order
        SetupTrayMenu()
        InitPluginSystem()
        ; Note: CheckEnvironment() is now called after startup delay to prevent admin dialogs
        
        ; Mark initialization as complete
        g_initializationComplete := true
        
        ; Setup delayed hotkey activation (staggered to reduce startup CPU spike)
        ; This prevents phantom hotkey triggers like the F12 dialog issue
        g_enableHotkeysTimer := () => EnableHotkeys()
        SetTimer(g_enableHotkeysTimer, -3000)  ; Increased from 2000ms to 3000ms to stagger startup operations
        
        ; Show startup/reload success message with custom GUI
        ShowSuccessMessage()
        
    } catch as e {
        ; Handle initialization errors gracefully
        global g_errorCount
        g_errorCount++
        
        if (g_errorCount <= 3) {
                            TopMsgBox("Initialization error (attempt " g_errorCount "/3): " e.Message "`n`nRetrying in 1 second...", "Startup Error", ConvertMsgBoxOptions("Iconx T3"))
            SetTimer(() => InitializeScript(), -1000)
        } else {
            TopMsgBox("Failed to initialize after 3 attempts: " e.Message "`n`nScript will run with limited functionality.", "Startup Failed", "Iconx")
        }
    }
}

; Initialize the plugin system
InitPluginSystem() {
    global g_pluginManager, g_settingsManager
    
    if (CONFIG.enablePlugins) {
        ; Create plugin manager
        g_pluginManager := PluginManager()
        
        ; Create settings manager
        g_settingsManager := SettingsManager(g_pluginManager)
        
        ; Apply startup settings
        ApplyStartupSettings()
        
        ; Load plugins
        pluginCount := g_pluginManager.LoadPlugins()
        
        ; Enable all plugins
        g_pluginManager.EnableAllPlugins()
        
        ; Note: Dynamic hotkeys will be setup after startup delay via EnableHotkeys()
        
        ; Refresh tray menu now that settings manager is available
        SetTimer(() => SetupTrayMenu(), -100)  ; Small delay to ensure settings manager is fully initialized
        
        ; Check for updates if enabled (much longer delay to avoid interrupting user)
        if (g_settingsManager.GetSetting("General_AutoUpdate", true)) {
            SetTimer(() => g_settingsManager.CheckForUpdates(), -60000)  ; Check after 60 seconds to avoid interrupting startup workflow
        }
        
        if (CONFIG.debugMode || g_settingsManager.GetSetting("General_DebugMode", false)) {
            g_settingsManager.LogDebug("Loaded " pluginCount " plugins")
        }
    }
}

; Apply startup settings when script loads
ApplyStartupSettings() {
    global g_settingsManager
    
    ; Safety check - only proceed if settings manager is properly initialized
    if (!g_settingsManager || Type(g_settingsManager) = "String") {
        return
    }
    
    try {
        ; Check if we should be running as admin
        runAsAdmin := g_settingsManager.GetSetting("General_RunAsAdmin", false)
        if (runAsAdmin && !A_IsAdmin) {
            ; Show notification that admin mode is enabled but not active
            g_settingsManager.ShowNotification("Admin mode enabled - restart as admin for full functionality", 3000)
        }
        
        ; Apply debug mode
        debugMode := g_settingsManager.GetSetting("General_DebugMode", false)
        if (debugMode) {
            g_settingsManager.LogDebug("Script started with debug mode enabled")
        }
        
        ; Play startup sound if enabled
        soundEnabled := g_settingsManager.GetSetting("General_SoundEnabled", true)
        if (soundEnabled) {
            g_settingsManager.PlaySound(1000, 150)  ; Higher pitch for startup
        }
        
        ; Show startup notification if enabled
        showNotifications := g_settingsManager.GetSetting("General_ShowNotifications", true)
        if (showNotifications) {
            g_settingsManager.ShowNotification("AHK Tools loaded successfully")
        }
        
    } catch as e {
        ; Fallback error handling
        TopMsgBox("Error applying startup settings: " e.Message, "Startup Error", ConvertMsgBoxOptions("Iconx T5"))
    }
}

; Custom success message GUI with green checkmark
ShowSuccessMessage() {
    global successGui := Gui("+AlwaysOnTop +ToolWindow -MaximizeBox -MinimizeBox", "Script Ready")
    successGui.SetFont("s10", "Segoe UI")
    successGui.BackColor := 0xF0F0F5
    
    ; Create smaller green circle background with checkmark
    checkmarkControl := successGui.Add("Text", "x15 y15 w40 h40 Center c0xFFFFFF Background0x4CAF50", "✓")
    checkmarkControl.SetFont("s20 Bold", "Segoe UI")
    
    ; Success message text
    successGui.Add("Text", "x70 y20 w250", "AHK Tools v" CONFIG.version " loaded successfully!")
    successGui.Add("Text", "x70 y38 w250 c0x666666", "All shortcuts are ready to use.")
    
    ; OK button with countdown timer inside
    global okButton := successGui.Add("Button", "x120 y70 w100 h30", "OK (2.500s)")
    okButton.SetFont("s9", "Segoe UI")
    okButton.OnEvent("Click", (*) => CloseSuccessGui())
    
    ; Show the GUI
    successGui.Show("w340 h115")
    
    ; Focus the OK button so it's preselected
    okButton.Focus()
    
    ; Countdown logic with 50ms precision (20 FPS - much more performance friendly)
    global remainingTime := 2.5
    SetTimer(UpdateCountdown, 50)
}

CloseSuccessGui() {
    global successGui
    SetTimer(UpdateCountdown, 0)  ; Stop the timer
    successGui.Destroy()
}

UpdateCountdown() {
    global remainingTime, okButton, successGui
    remainingTime -= 0.05  ; Adjusted for 50ms intervals instead of 10ms
    
    if (remainingTime > 0) {
        okButton.Text := Format("OK ({:.2f}s)", remainingTime)  ; Reduced precision display
    } else {
        SetTimer(UpdateCountdown, 0)  ; Stop the timer
        successGui.Destroy()
    }
}

SetupTrayMenu() {
    ; Clear default menu items and add custom ones
    A_TrayMenu.Delete()  ; Clear default items
    
    ; Add startup toggle option using settings manager (with fallback)
    global g_settingsManager
    try {
        if (g_settingsManager && g_settingsManager.IsWindowsStartupEnabled()) {
            A_TrayMenu.Add("Disable Startup", (*) => ToggleStartupFromTray(false))
        } else if (g_settingsManager) {
            A_TrayMenu.Add("Enable Startup", (*) => ToggleStartupFromTray(true))
        } else {
            ; Fallback to old method if settings manager not available
            if (IsStartupEnabled()) {
                A_TrayMenu.Add("Disable Startup", (*) => ToggleStartup(false))
            } else {
                A_TrayMenu.Add("Enable Startup", (*) => ToggleStartup(true))
            }
        }
    } catch {
        ; Fallback to old method if any error occurs
        if (IsStartupEnabled()) {
            A_TrayMenu.Add("Disable Startup", (*) => ToggleStartup(false))
        } else {
            A_TrayMenu.Add("Enable Startup", (*) => ToggleStartup(true))
        }
    }
    
    ; Add plugin manager menu item if plugins are enabled
    if (CONFIG.enablePlugins) {
        A_TrayMenu.Add("Plugin Manager", (*) => ShowPluginManager())
        A_TrayMenu.Add("Settings", (*) => ShowSettings())
    }
    
    A_TrayMenu.Add()  ; Separator
    A_TrayMenu.Add("Reload Script", (*) => ReloadScript())
    A_TrayMenu.Add("Reload as Admin", (*) => ReloadAsAdmin())
    A_TrayMenu.Add()  ; Separator
    A_TrayMenu.Add("About", (*) => ShowAbout())
    A_TrayMenu.Add("Exit", (*) => ExitScript())
}

; Toggle startup from tray menu
ToggleStartupFromTray(enable) {
    global g_settingsManager
    
    if (g_settingsManager && Type(g_settingsManager) != "String") {
        ; Update the setting
        g_settingsManager.SetSetting("General_StartupEnabled", enable)
        
        ; Apply the change
        if (g_settingsManager.SetWindowsStartup(enable)) {
            ; Save the setting
            g_settingsManager.SaveSettings()
            
            ; Refresh tray menu
            SetupTrayMenu()
        }
    } else {
        ; Fallback to old method
        ToggleStartup(enable)
    }
}

CheckEnvironment() {
    global g_startupComplete
    
    ; Skip admin warning during startup to prevent unwanted dialogs
    if (!g_startupComplete) {
        return
    }
    
    ; Only show admin notice if user has admin-requiring features enabled
    global g_settingsManager
    if (!A_IsAdmin && g_settingsManager && g_settingsManager.GetSetting("General_ShowNotifications", true)) {
        ; Show a brief tooltip instead of dialog
        ShowMouseTooltip("Some features require admin rights. Use tray menu to reload as admin if needed.", 3000)
    }
}

; Show the plugin manager
ShowPluginManager() {
    global g_pluginManager
    
    if (!g_pluginManager) {
        TopMsgBox("Plugin system is not initialized.", "Plugin Manager", "Iconx")
        return
    }
    
    g_pluginManager.ShowPluginManager()
}

; Show the settings manager
ShowSettings() {
    global g_settingsManager
    
    if (!g_settingsManager) {
        TopMsgBox("Settings system is not initialized.", "Settings", "Iconx")
        return
    }
    
    g_settingsManager.ShowSettingsGui()
}

ToggleStartup(enable) {
    try {
        startupPath := A_Startup "\AHK-Tools.lnk"
        
        if (enable) {
            ; Create shortcut in startup folder
            FileCreateShortcut A_ScriptFullPath, startupPath, A_ScriptDir, "", "AHK Tools - Productivity Hotkeys"
            MsgBox "Startup enabled! Script will run when Windows starts.", "Startup Setting", "T2 64"
        } else {
            ; Remove shortcut from startup folder
            if FileExist(startupPath) {
                FileDelete startupPath
            }
            MsgBox "Startup disabled! Script will not run when Windows starts.", "Startup Setting", "T2 64"
        }
        
        ; Refresh tray menu to update the option
        SetupTrayMenu()
        
    } catch as e {
        SafeMsgBox("Error: " e.Message "`n`nTo manually set startup:`n1. Copy a shortcut of this script`n2. Paste it to: " A_Startup, "Error", "Iconx")
    }
}

IsStartupEnabled() {
    ; Check if startup shortcut exists
    return FileExist(A_Startup "\AHK-Tools.lnk")
}

; Function to show help dialog with modern ListView
ShowHelpDialog() {
    helpGui := Gui("+AlwaysOnTop +Resize", "🔥 AHK Tools - Keyboard Shortcuts")
    helpGui.SetFont("s9", "Segoe UI")
    helpGui.BackColor := 0xF0F0F0
    
    ; Title
    helpGui.Add("Text", "x20 y15 w600 Center", "AHK Tools - Keyboard Shortcuts Reference").SetFont("s12 Bold", "Segoe UI")
    
    ; Create tab control for categories
    tabControl := helpGui.Add("Tab3", "x10 y45 w620 h400", ["🔧 System", "🔌 Plugins", "🔍 Search", "📝 Text/File", "⚙️ Settings"])
    
    ; System & Management Tab
    tabControl.UseTab(1)
    systemLV := helpGui.Add("ListView", "x20 y75 w590 h330 -Multi Grid", ["Shortcut", "Function", "Admin"])
    systemLV.ModifyCol(1, 120)
    systemLV.ModifyCol(2, 380)
    systemLV.ModifyCol(3, 60)
    
    systemLV.Add("", "Win + F1", "Show This Help Dialog", "")
    systemLV.Add("", "Win + F5", "Settings Manager (Customize all hotkeys!)", "")
    systemLV.Add("", "Win + Delete", "Suspend/Resume Script", "")
    systemLV.Add("", "Win + Enter", "Open Terminal as Administrator", "🔐")
    systemLV.Add("", "Win + Q", "Force Quit Active Application", "")
    systemLV.Add("", "Win + X", "System Power Options", "")
    systemLV.Add("", "Win + C", "Open Calculator", "")
    
    ; Plugins & Tools Tab
    tabControl.UseTab(2)
    pluginsLV := helpGui.Add("ListView", "x20 y75 w590 h330 -Multi Grid", ["Shortcut", "Function", "Admin"])
    pluginsLV.ModifyCol(1, 120)
    pluginsLV.ModifyCol(2, 380)
    pluginsLV.ModifyCol(3, 60)
    
    pluginsLV.Add("", "Alt + C", "Currency Converter (Auto-detects $100, €50, etc.)", "")
    pluginsLV.Add("", "Ctrl + Alt + A", "Auto Completion Plugin", "")
    pluginsLV.Add("", "Alt + U", "Unit Converter (SI & Imperial units)", "")
    

    pluginsLV.Add("", "Win + F2", "Toggle Numpad Mode", "")
    pluginsLV.Add("", "Win + F4", "Hourly Chime Toggle", "")
    
    ; Search & Web Tab
    tabControl.UseTab(3)
    searchLV := helpGui.Add("ListView", "x20 y75 w590 h330 -Multi Grid", ["Shortcut", "Function", "Notes"])
    searchLV.ModifyCol(1, 120)
    searchLV.ModifyCol(2, 320)
    searchLV.ModifyCol(3, 120)
    
    searchLV.Add("", "Alt + D", "DuckDuckGo Search", "Privacy-focused")
    searchLV.Add("", "Alt + S", "Perplexity Search", "AI-powered")
    searchLV.Add("", "Alt + A", "WolframAlpha Search", "Math & facts")
    searchLV.Add("", "Alt + G", "Game Database Search", "Gaming info")
    
    helpGui.Add("Text", "x20 y415 w590", "💡 Tip: Select text first, then use search shortcuts").SetFont("s8 Italic")
    
    ; Text & File Operations Tab
    tabControl.UseTab(4)
    textLV := helpGui.Add("ListView", "x20 y75 w590 h330 -Multi Grid", ["Shortcut", "Function", "Target"])
    textLV.ModifyCol(1, 120)
    textLV.ModifyCol(2, 320)
    textLV.ModifyCol(3, 120)
    
    textLV.Add("", "Alt + E", "Open Selected Text in Editor", "Default editor")
    textLV.Add("", "Alt + T", "Open Selected Text in Notepad", "Notepad")
    textLV.Add("", "Alt + W", "Open Selected URL in Browser", "Default browser")
    
    helpGui.Add("Text", "x20 y415 w590", "💡 Tip: Select text or URL first, then use these shortcuts").SetFont("s8 Italic")
    
    ; Settings & Customization Tab
    tabControl.UseTab(5)
    settingsLV := helpGui.Add("ListView", "x20 y75 w590 h280 -Multi Grid", ["Action", "Method", "Description"])
    settingsLV.ModifyCol(1, 120)
    settingsLV.ModifyCol(2, 150)
    settingsLV.ModifyCol(3, 290)
    
    settingsLV.Add("", "Change Hotkeys", "Win + F5", "Settings → Hotkeys → Change any shortcut")
    settingsLV.Add("", "Plugin Manager", "Right-click tray", "Enable/disable plugins")
    settingsLV.Add("", "Reload as Admin", "Right-click tray", "Get administrator privileges")
    settingsLV.Add("", "Script Control", "Tray menu", "Suspend, reload, exit options")
    
    helpGui.Add("Text", "x20 y365 w590", "🔐 = Requires Administrator privileges").SetFont("s8 Bold")
    helpGui.Add("Text", "x20 y385 w590", "📱 = Available in system tray menu").SetFont("s8 Bold")
    helpGui.Add("Text", "x20 y415 w590", "💡 Pro Tip: All shortcuts are customizable! Use Win + F5 to personalize").SetFont("s8 Italic")
    
    ; Reset tab context and add buttons
    tabControl.UseTab()
    
    ; Buttons
    helpGui.Add("Button", "x20 y460 w100 h30", "&Open Settings").OnEvent("Click", (*) => (helpGui.Destroy(), ShowSettings()))
    helpGui.Add("Button", "x130 y460 w120 h30", "&Plugin Manager").OnEvent("Click", (*) => (helpGui.Destroy(), ShowPluginManager()))
    helpGui.Add("Button", "x500 y460 w100 h30 Default", "&Close").OnEvent("Click", (*) => helpGui.Destroy())
    
    ; Event handlers
    helpGui.OnEvent("Escape", (*) => helpGui.Destroy())
    helpGui.OnEvent("Close", (*) => helpGui.Destroy())
    
    ; Apply theme
    ApplyThemeToGui(helpGui)
    
    ; Show the GUI
    helpGui.Show("w640 h510")
}

; =================== DYNAMIC HOTKEY SYSTEM ===================
; Function to set up dynamic hotkeys based on settings
SetupDynamicHotkeys() {
    global g_settingsManager, g_startupComplete, g_hotkeysEnabled
    
    if (!g_settingsManager) {
        return
    }
    
    ; Skip if hotkeys are not enabled yet (startup protection)
    if (!g_hotkeysEnabled) {
        return
    }
    
    ; Define hotkey mappings - function name to actual function
    hotkeyFunctions := Map(
        "ShowHelp", (*) => ShowHelpDialog(),
        "ShowSettings", (*) => ShowSettings(),
        "SuspendScript", (*) => ToggleSuspend(),
        "AdminTerminal", (*) => OpenAdminTerminal(),
        "ToggleNumpad", (*) => ToggleNumpadMode(),

        "ForceQuit", (*) => ForceQuitApplication(),
        "PowerOptions", (*) => ShowPowerOptions(),
        "HourlyChime", (*) => ToggleHourlyChime(),
        "Calculator", (*) => Run("calc.exe"),

        "DuckDuckGoSearch", (*) => DuckDuckGoSearch(),
        "PerplexitySearch", (*) => PerplexitySearch(),
        "WolframSearch", (*) => WolframSearch(),
        "OpenInEditor", (*) => OpenSelectedInEditor(),
        "GameDatabaseSearch", (*) => SearchGameDatabases(),
        "OpenURL", (*) => OpenSelectedURL(),
        "AutoCompletion", (*) => ShowAutoCompletion(),
        "RunCommand", (*) => RunSelectedCommand()
    )
    
    ; Set up each hotkey from settings
    for name, func in hotkeyFunctions {
        settingKey := "Hotkey_" . name
        hotkeyString := g_settingsManager.GetSetting(settingKey, "")
        
        if (hotkeyString && hotkeyString != "") {
            try {
                ; Create the hotkey
                Hotkey(hotkeyString, func, "On")
            } catch as e {
                ; If hotkey fails, show error but continue
                if (g_settingsManager.GetSetting("General_DebugMode", false)) {
                    SafeMsgBox("Failed to set hotkey " hotkeyString " for " name ": " e.Message, "Hotkey Error", ConvertMsgBoxOptions("Iconx T3"))
                }
            }
        }
    }
}

; Function to clear all dynamic hotkeys (for reloading)
ClearDynamicHotkeys() {
    global g_settingsManager
    
    if (!g_settingsManager) {
        return
    }
    
    ; List of all possible hotkey names
    hotkeyNames := [
        "ShowHelp", "ShowSettings", "SuspendScript", "AdminTerminal", "ToggleNumpad",
        "ForceQuit", "PowerOptions", "HourlyChime", "Calculator",
        "DuckDuckGoSearch", "PerplexitySearch", "WolframSearch",
        "OpenInEditor", "GameDatabaseSearch", "OpenURL", "OpenInNotepad",
        "AutoCompletion", "UnitConverter"
    ]
    
    ; Clear each hotkey
    for name in hotkeyNames {
        settingKey := "Hotkey_" . name
        hotkeyString := g_settingsManager.GetSetting(settingKey, "")
        
        if (hotkeyString && hotkeyString != "") {
            try {
                Hotkey(hotkeyString, "Off")
            } catch {
                ; Ignore errors when clearing hotkeys
            }
        }
    }
}

; =================== HOTKEY FUNCTIONS ===================
; Individual functions for each hotkey action

ToggleSuspend() {
    static suspended := false
    suspended := !suspended
    if suspended {
        Suspend true
        ShowMouseTooltip("Script Suspended")
    } else {
        Suspend false
        ShowMouseTooltip("Script Active")
    }
}

OpenAdminTerminal() {
    try {
        Run "*RunAs wt.exe"
    } catch as e {
        SafeMsgBox("Error opening Terminal as admin: " e.Message, "Error", "Iconx")
    }
}

ToggleNumpadMode() {
    global EnableNumpadToggle
    if !GetKeyState("NumLock", "T") {
        SetNumLockState "On"
        ShowMouseTooltip("Numpad Mode: ON")
        EnableNumpadToggle := 1
    } else {
        SetNumLockState "Off"
        ShowMouseTooltip("Numpad Mode: OFF")
        EnableNumpadToggle := 0
    }
}



ForceQuitApplication() {
    activePID := WinGetPID("A")
    PostMessage 0x0010, 0, 0,, "ahk_id " WinGetID("A")
    Sleep 500
    
    if WinExist("ahk_pid " activePID) {
        RunWait "taskkill /PID " activePID " /F",, "Hide"
        ShowMouseTooltip("Application was force quit", 1500) 
    } else {
        ShowMouseTooltip("Application closed", 1500)
    }
}

ShowPowerOptions() {
    powerGui := Gui()
    powerGui.Opt("+AlwaysOnTop")
    powerGui.SetFont("s10", "Segoe UI")
    powerGui.Add("Text",, "Select an option:")
    
    btnSleep := powerGui.Add("Button", "w100", "Sleep")
    btnSleep.OnEvent("Click", (*) => (powerGui.Destroy(), DllCall("PowrProf\SetSuspendState", "Int", 0, "Int", 0, "Int", 0)))
    btnShutdown := powerGui.Add("Button", "w100", "Shutdown")
    btnShutdown.OnEvent("Click", (*) => (powerGui.Destroy(), Shutdown(1)))
    btnRestart := powerGui.Add("Button", "w100", "Restart")
    btnRestart.OnEvent("Click", (*) => (powerGui.Destroy(), Shutdown(2)))
    btnLogout := powerGui.Add("Button", "w100", "Logout")
    btnLogout.OnEvent("Click", (*) => (powerGui.Destroy(), Shutdown(0)))
    btnCancel := powerGui.Add("Button", "w100", "Cancel (Esc)")
    btnCancel.OnEvent("Click", (*) => powerGui.Destroy())
    
    btnSleep.Focus()
    powerGui.OnEvent("Escape", (*) => powerGui.Destroy())
    ApplyThemeToGui(powerGui)
    powerGui.Show()
}

ToggleHourlyChime() {
    static chimeActive := false
    chimeActive := !chimeActive
    
    if (chimeActive) {
        ShowMouseTooltip("Hourly chime activated", 2000)
        SetTimer PlayHourlyChime, 3600000
        PlayHourlyChime()
    } else {
        ShowMouseTooltip("Hourly chime deactivated", 2000)
        SetTimer PlayHourlyChime, 0
    }
}



OpenSelectedInEditor() {
    savedClipboard := ClipboardAll()
    A_Clipboard := ""
    
    Send "^c"
    if !ClipWait(0.5) {
        MsgBox "Failed to copy text to clipboard.", "Error", "Iconx"
        A_Clipboard := savedClipboard
        return
    }
    
    code := A_Clipboard
    lineCount := 0
    Loop Parse code, "`n", "`r" {
        lineCount++
    }
    
    language := DetectLanguage(code)
    tempFile := A_Temp "\SelectedCode." language
    FileAppend code, tempFile
    
    try {
        Run tempFile
        ShowMouseTooltip("Opening " lineCount " lines of " language " code...", 2000)
    } catch as e {
        MsgBox "Failed to open editor: " e.Message, "Error", "Iconx"
    }
    
    A_Clipboard := savedClipboard
    savedClipboard := ""
}

SearchGameDatabases() {
    savedClipboard := ClipboardAll()
    A_Clipboard := ""
    
    Send "^c"
    if !ClipWait(0.5) {
        MsgBox "Failed to copy text to clipboard.", "Error", "Iconx"
        A_Clipboard := savedClipboard
        return
    }
    
    try {
        searchTerm := UrlEncode(A_Clipboard)
        
        Run "https://www.pcgamingwiki.com/w/index.php?search=" searchTerm
        Run "https://cs.rin.ru/forum/search.php?keywords=" searchTerm "&terms=any&author=&sc=1&sf=titleonly&sk=t&sd=d&sr=topics&st=0&ch=300&t=0&submit=Search"
        Run "https://predb.net/?q=" searchTerm
        Run "https://www.gog-games.to/search/" searchTerm
        
        ShowMouseTooltip("Searching game databases...", 1500)
    } catch as e {
        MsgBox "Failed to open game databases: " e.Message, "Error", "Iconx"
    }
    
    A_Clipboard := savedClipboard
    savedClipboard := ""
}

OpenSelectedURL() {
    savedClipboard := ClipboardAll()
    A_Clipboard := ""
    
    Send "^c"
    if !ClipWait(0.5) {
        MsgBox "Failed to copy text to clipboard.", "Error", "Iconx"
        A_Clipboard := savedClipboard
        return
    }
    
    url := A_Clipboard
    
    if (InStr(url, "http://") || InStr(url, "https://") || InStr(url, "www.")) {
        if (!InStr(url, "http://") && !InStr(url, "https://")) {
            url := "https://" url
        }
        
        try {
            Run url
            ShowMouseTooltip("Opening URL in browser...", 1500)
        } catch as e {
            MsgBox "Failed to open URL: " e.Message, "Error", "Iconx"
        }
    } else {
        MsgBox "Selected text doesn't appear to be a valid URL.", "Error", "Iconx"
    }
    
    A_Clipboard := savedClipboard
    savedClipboard := ""
}



ShowAutoCompletion() {
    ; Trigger the auto completion plugin
    global g_pluginManager
    if (g_pluginManager && g_pluginManager.Plugins.Has("Auto Completion")) {
        plugin := g_pluginManager.Plugins["Auto Completion"]
        if (plugin.Enabled) {
            ; Call the plugin's management interface directly
            plugin.ShowAutoCompletionManager()
        } else {
            SafeMsgBox("Auto Completion plugin is disabled. Enable it in Settings > Plugins.", "Plugin Disabled", "Icon!")
        }
    } else {
        SafeMsgBox("Auto Completion plugin not found.", "Plugin Error", "Iconx")
    }
}

; =================== HOTKEYS SECTION ===================
; All hotkeys are now dynamically loaded from settings via SetupDynamicHotkeys()
; Users can customize hotkeys through Settings > Hotkeys tab
; Default hotkeys are defined in SettingsManager.InitializeDefaultHotkeys()

; Special handling for numpad toggle (context-sensitive hotkeys)
global EnableNumpadToggle := 0

#HotIf EnableNumpadToggle ; Only active when EnableNumpadToggle is True
1::Numpad1
2::Numpad2
3::Numpad3
4::Numpad4
5::Numpad5
6::Numpad6
7::Numpad7
8::Numpad8
9::Numpad9
0::Numpad0
Delete::Insert
#HotIf  ; End context sensitivity



; Initialize script start time for hourly chime
global scriptStartTime := A_TickCount

; Function for hourly chime
PlayHourlyChime() {
    global scriptStartTime
    
    ; Calculate hours since script started
    hoursPassed := ((A_TickCount - scriptStartTime) // 3600000)  ; Convert milliseconds to hours
    
            ; Show tooltip with hours passed
        ShowMouseTooltip("Hourly chime`nHours since activation: " hoursPassed, 3000)
    
    ; Ensure the file exists
    soundFile := "casio_hour_chime.mp3"
    if !FileExist(soundFile) {
        MsgBox "Error: " soundFile " not found in script directory"
        return
    }
    
    ; Play the sound
    try {
        SoundPlay soundFile
    } catch as e {
        MsgBox "Error playing sound: " e.Message
    }
}

; Remaining hardcoded hotkeys removed - now using dynamic system
{

}

; =================== SEARCH AND TEXT PROCESSING FUNCTIONS ===================
; These functions are now called via dynamic hotkeys

DuckDuckGoSearch() {
    ; Get selected text or prompt user for search term
    searchTerm := ""
    if (A_PriorHotkey = A_ThisHotkey && A_TimeSincePriorHotkey < 400)
        return  ; Avoid accidental double-triggers
    
    ; Try to get selected text first
    savedClip := ClipboardAll()  ; Save current clipboard
    A_Clipboard := ""  ; Clear clipboard
    Send "^c"  ; Copy selected text
    if ClipWait(0.5) {  ; Wait for clipboard data
        searchTerm := A_Clipboard
    }
    A_Clipboard := savedClip  ; Restore original clipboard
    
    ; If no text was selected, prompt user
    if (searchTerm = "") {
        searchTerm := InputBox("Enter search term:", "DuckDuckGo Search").Value
        if (searchTerm = "")  ; User cancelled
            return
    }
    
    ; Encode the search term and launch browser
    searchTerm := UrlEncode(searchTerm)
    Run "https://duckduckgo.com/?q=" searchTerm
}



PerplexitySearch() {
    ; Get selected text or prompt user for search term
    searchTerm := ""
    if (A_PriorHotkey = A_ThisHotkey && A_TimeSincePriorHotkey < 400)
        return  ; Avoid accidental double-triggers
    
    ; Try to get selected text first
    savedClip := ClipboardAll()  ; Save current clipboard
    A_Clipboard := ""  ; Clear clipboard
    Send "^c"  ; Copy selected text
    if ClipWait(0.5) {  ; Wait for clipboard data
        searchTerm := A_Clipboard
    }
    A_Clipboard := savedClip  ; Restore original clipboard
    
    ; If no text was selected, prompt user
    if (searchTerm = "") {
        searchTerm := InputBox("Enter search term:", "Perplexity Search").Value
        if (searchTerm = "")  ; User cancelled
            return
    }
    
    ; Encode the search term and launch browser
    searchTerm := UrlEncode(searchTerm)
    Run "https://www.perplexity.ai/search?q=" searchTerm
}



WolframSearch() {
    ; Get selected text or prompt user for search term
    searchTerm := ""
    if (A_PriorHotkey = A_ThisHotkey && A_TimeSincePriorHotkey < 400)
        return  ; Avoid accidental double-triggers
    
    ; Try to get selected text first
    savedClip := ClipboardAll()  ; Save current clipboard
    A_Clipboard := ""  ; Clear clipboard
    Send "^c"  ; Copy selected text
    if ClipWait(0.5) {  ; Wait for clipboard data
        searchTerm := A_Clipboard
    }
    A_Clipboard := savedClip  ; Restore original clipboard
    
    ; If no text was selected, prompt user
    if (searchTerm = "") {
        searchTerm := InputBox("Enter search term:", "WolframAlpha Search").Value
        if (searchTerm = "")  ; User cancelled
            return
    }
    
    ; Encode the search term and launch browser
    searchTerm := UrlEncode(searchTerm)
    Run "https://www.wolframalpha.com/input?i=" searchTerm
    
    ; Show confirmation tooltip
    ShowMouseTooltip("Searching with WolframAlpha...", 1000)
}

; Function to open selected text in editor with language detection (legacy)
OpenSelectedInEditorLegacy() {
    ; Save the current clipboard content
    savedClipboard := ClipboardAll()
    A_Clipboard := ""  ; Clear clipboard
    
    ; Copy selected text to clipboard
    Send "^c"
    if !ClipWait(0.5) {  ; Wait up to 0.5 seconds for clipboard to update
        MsgBox "Failed to copy text to clipboard.", "Error", "Iconx"
        A_Clipboard := savedClipboard  ; Restore clipboard
        return
    }
    
    ; Get the text from clipboard
    code := A_Clipboard
    
    ; Count lines
    lineCount := 0
    Loop Parse code, "`n", "`r" {
        lineCount++
    }
    
    ; Detect programming language
    language := DetectLanguage(code)
    
    ; Create temporary file with appropriate extension
    tempFile := A_Temp "\SelectedCode." language
    FileAppend code, tempFile
    
    ; Open in default editor
    try {
        Run tempFile
        ShowMouseTooltip("Opening " lineCount " lines of " language " code...", 2000)
    } catch as e {
        MsgBox "Failed to open editor: " e.Message, "Error", "Iconx"
    }
    
    ; Restore the original clipboard content
    A_Clipboard := savedClipboard
    savedClipboard := ""  ; Free memory
}

; Function to search selected text in game databases (legacy)
SearchGameDatabasesLegacy()
{
    ; Save the current clipboard content
    savedClipboard := ClipboardAll()
    A_Clipboard := ""  ; Clear clipboard
    
    ; Copy selected text to clipboard
    Send "^c"
    if !ClipWait(0.5) {  ; Wait up to 0.5 seconds for clipboard to update
        MsgBox "Failed to copy text to clipboard.", "Error", "Iconx"
        A_Clipboard := savedClipboard  ; Restore clipboard
        return
    }
    
    ; Open game databases with the selected text
    try {
        ; Encode the search term for URLs
        searchTerm := UrlEncode(A_Clipboard)
        
        ; Open PCGamingWiki
        Run "https://www.pcgamingwiki.com/w/index.php?search=" searchTerm
        
        ; Open CS.RIN.RU
        Run "https://cs.rin.ru/forum/search.php?keywords=" searchTerm "&terms=any&author=&sc=1&sf=titleonly&sk=t&sd=d&sr=topics&st=0&ch=300&t=0&submit=Search"
        
        ; Open preDB.net
        Run "https://predb.net/?q=" searchTerm
        
        ; Open GOG-Games
        Run "https://www.gog-games.to/search/" searchTerm
        
        ShowMouseTooltip("Searching game databases...", 1500)
    } catch as e {
        MsgBox "Failed to open game databases: " e.Message, "Error", "Iconx"
    }
    
    ; Restore the original clipboard content
    A_Clipboard := savedClipboard
    savedClipboard := ""  ; Free memory
}

; Function to open selected URL in web browser (legacy)
OpenSelectedURLLegacy()
{
    ; Save the current clipboard content
    savedClipboard := ClipboardAll()
    A_Clipboard := ""  ; Clear clipboard
    
    ; Copy selected text to clipboard
    Send "^c"
    if !ClipWait(0.5) {  ; Wait up to 0.5 seconds for clipboard to update
        MsgBox "Failed to copy text to clipboard.", "Error", "Iconx"
        A_Clipboard := savedClipboard  ; Restore clipboard
        return
    }
    
    ; Get the URL from clipboard
    url := A_Clipboard
    
    ; Check if the text looks like a URL
    if (InStr(url, "http://") || InStr(url, "https://") || InStr(url, "www.")) {
        ; If URL doesn't start with http:// or https://, add https://
        if (!InStr(url, "http://") && !InStr(url, "https://")) {
            url := "https://" url
        }
        
        ; Open the URL in default browser
        try {
            Run url
            ShowMouseTooltip("Opening URL in browser...", 1500)
        } catch as e {
            MsgBox "Failed to open URL: " e.Message, "Error", "Iconx"
        }
    } else {
        MsgBox "Selected text doesn't appear to be a valid URL.", "Error", "Iconx"
    }
    
    ; Restore the original clipboard content
    A_Clipboard := savedClipboard
    savedClipboard := ""  ; Free memory
}

; Function to open selected text in Notepad (legacy)
OpenSelectedInNotepadLegacy()
{
    ; Save the current clipboard content
    savedClipboard := ClipboardAll()
    A_Clipboard := ""  ; Clear clipboard

    ; Copy selected text to clipboard
    Send "^c"
    if !ClipWait(0.5) {  ; Wait up to 0.5 seconds for clipboard to update
        MsgBox "Failed to copy text to clipboard.", "Error", "Iconx"
        A_Clipboard := savedClipboard  ; Restore clipboard
        return
    }

    ; Get the text from clipboard
    selectedText := A_Clipboard

    ; Create a temporary file
    tempFile := A_Temp "\SelectedText.txt"
    try FileDelete(tempFile)  ; Ignore error if file doesn't exist
    FileAppend selectedText, tempFile

    ; Open in Notepad
    try {
        Run "notepad.exe '" tempFile "'"
        ShowMouseTooltip("Opening selected text in Notepad...", 1500)
    } catch as e {
        MsgBox "Failed to open Notepad: " e.Message, "Error", "Iconx"
    }

    ; Restore the original clipboard content
    A_Clipboard := savedClipboard
    savedClipboard := ""  ; Free memory
}

; Show settings window from tray
ShowSettingsFromTray() {
    global g_settingsManager
    
    if (g_settingsManager && Type(g_settingsManager) != "String") {
        g_settingsManager.ShowFromTray()
    } else {
        ShowSettings()  ; Fallback
    }
}

; =================== COMMAND RUNNER ===================
; Run selected command with admin/non-admin choice
RunSelectedCommand() {
    ; Get selected text
    selectedText := ""
    savedClip := ClipboardAll()
    A_Clipboard := ""
    Send "^c"
    if ClipWait(0.3) {
        selectedText := Trim(A_Clipboard)
    }
    A_Clipboard := savedClip
    
    if (!selectedText) {
        ShowMouseTooltip("No command selected", 2000)
        return
    }
    
    ; Detect command type and show appropriate dialog
    commandType := DetectCommandType(selectedText)
    
    ; If detection is unclear, ask user to choose
    if (commandType == "Unknown") {
        commandType := ShowCommandTypeChoiceDialog(selectedText)
        if (!commandType) {
            return  ; User cancelled
        }
    }
    
    ShowCommandExecutionDialog(selectedText, commandType)
}

; Detect if text is CMD or PowerShell command
DetectCommandType(text) {
    ; Convert to lowercase for comparison
    lowerText := StrLower(text)
    
    ; PowerShell-specific patterns (expanded)
    psPatterns := [
        "get-", "set-", "new-", "remove-", "invoke-", "start-", "stop-", "restart-",
        "test-", "measure-", "select-", "where-", "foreach-", "sort-", "group-",
        "$_", "$env:", "$home", "$profile", "$pshome", "$pwd", "$args", "$input",
        "write-host", "write-output", "write-error", "write-warning", "write-verbose",
        "import-module", "export-module", "get-module", "get-command", "get-help",
        "get-childitem", "get-content", "set-content", "add-content", "clear-content",
        "get-process", "stop-process", "start-process", "get-service", "start-service", "stop-service",
        "test-path", "resolve-path", "split-path", "join-path", "push-location", "pop-location",
        "-eq ", "-ne ", "-lt ", "-le ", "-gt ", "-ge ", "-like ", "-notlike ", "-match ", "-notmatch ",
        "-contains ", "-notcontains ", "-in ", "-notin ", "-replace ", "-split ", "-join ",
        "-and ", "-or ", "-not ", "-xor ", "-band ", "-bor ", "-bnot ", "-bxor ",
        "| where", "| select", "| sort", "| group", "| measure", "| foreach", "| out-",
        ".ps1", "-executionpolicy", "-noprofile", "-command", "-file",
        ; PowerShell aliases (commonly used)
        " iwr ", " irm ", " iex ", " gcm ", " gci ", " gi ", " gm ", " gp ", " gwmi ",
        " sal ", " sls ", " tee ", " cat ", " ls ", " pwd ", " cd ", " mv ", " cp ",
        " rm ", " wget ", " curl ",
        ; PowerShell-specific syntax
        "| %", "-f ", "@{", "@(", "$(",  "$(", "[pscustomobject]", "[system.",
        "foreach-object", "where-object", "-property", "-expandproperty"
    ]
    
    ; Strong PowerShell indicators (high confidence)
    strongPsPatterns := [
        "invoke-restmethod", "invoke-webrequest", "invoke-expression",
        "$_.", "| %", "| foreach", "| where",
        "@{", "@(", "[pscustomobject]", "-property", "-expandproperty"
    ]
    
    ; Check for PowerShell aliases at the beginning or after spaces
    psAliases := ["iwr", "irm", "iex", "gcm", "gci", "gi", "gm", "gp", "gwmi"]
    for alias in psAliases {
        ; Check if alias appears at the start of command or after whitespace
        if RegExMatch(lowerText, "(^|\s)" . alias . "(\s|$)") {
            return "PowerShell"
        }
    }
    
    ; Check for strong PowerShell patterns first
    for pattern in strongPsPatterns {
        if InStr(lowerText, pattern) {
            return "PowerShell"
        }
    }
    
    ; Check for general PowerShell patterns
    psScore := 0
    for pattern in psPatterns {
        if InStr(lowerText, pattern) {
            psScore++
        }
    }
    
    ; CMD-specific patterns
    cmdPatterns := [
        "dir ", "cd ", "md ", "rd ", "del ", "copy ", "move ", "ren ", "type ", "find ",
        "findstr ", "attrib ", "cacls ", "xcopy ", "robocopy ", "tasklist ", "taskkill ",
        "net ", "netstat ", "ping ", "ipconfig ", "nslookup ", "tracert ", "arp ",
        "systeminfo ", "driverquery ", "wmic ", "reg ", "sc ", "schtasks ",
        "echo ", "set ", "if ", "for ", "goto ", "call ", "pause ", "cls ", "exit ",
        "path ", "prompt ", "title ", "color ", "doskey ", "more ", "sort ", "fc ",
        "@echo", "%%", "%1", "%2", "%~", "%cd%", "%date%", "%time%", "%username%",
        ".bat", ".cmd", "&& ", "|| ", "& ", "> ", ">> ", "< ", "| ", "^"
    ]
    
    ; Check for CMD patterns
    cmdScore := 0
    for pattern in cmdPatterns {
        if InStr(lowerText, pattern) {
            cmdScore++
        }
    }
    
    ; Check file extensions in the command
    if RegExMatch(lowerText, "\.(exe|com|bat|cmd|msi|ps1)\b") {
        return InStr(lowerText, ".ps1") ? "PowerShell" : "CMD"
    }
    
    ; If starts with common PowerShell cmdlet pattern
    if RegExMatch(lowerText, "^[a-z]+-[a-z]+") {
        return "PowerShell"
    }
    
    ; Scoring logic
    if (psScore > 0 && cmdScore == 0) {
        return "PowerShell"
    } else if (cmdScore > 0 && psScore == 0) {
        return "CMD"
    } else if (psScore > cmdScore) {
        return "PowerShell"
    } else if (cmdScore > psScore) {
        return "CMD"
    }
    
    ; If unclear, return "Unknown" to trigger user choice
    return "Unknown"
}

; Show dialog when command type detection is unclear
ShowCommandTypeChoiceDialog(command) {
    ; Create GUI for command type choice
    typeGui := Gui("+AlwaysOnTop", "Choose Command Type")
    typeGui.SetFont("s10", "Segoe UI")
    
    ; Command display
    typeGui.Add("Text", "x10 y10 w420", "Unable to automatically detect command type.")
    typeGui.Add("Text", "x10 y35", "Command:")
    typeGui.Add("Edit", "x10 y55 w420 h60 ReadOnly VScroll", command)
    
    ; Type selection
    typeGui.Add("Text", "x10 y130", "Please choose the command type:")
    
    ; PowerShell button
    psBtn := typeGui.Add("Button", "x10 y155 w200 h40", "🔷 PowerShell")
    psBtn.OnEvent("Click", (*) => SetChoice("PowerShell"))
    
    ; CMD button
    cmdBtn := typeGui.Add("Button", "x220 y155 w200 h40", "⚫ Command Prompt (CMD)")
    cmdBtn.OnEvent("Click", (*) => SetChoice("CMD"))
    
    ; Cancel button
    cancelBtn := typeGui.Add("Button", "x10 y205 w410 h30", "❌ Cancel")
    cancelBtn.OnEvent("Click", (*) => SetChoice(""))
    
    ; Hints
    typeGui.Add("Text", "x10 y245 w420 c0x666666", "Hint: PowerShell commands often use cmdlets (Get-, Set-, etc.) or aliases (iwr, irm, iex). CMD commands use traditional DOS commands (dir, copy, etc.).")
    
    ; Result variable
    chosenType := ""
    
    ; Function to set choice and close
    SetChoice(choice) {
        chosenType := choice
        typeGui.Destroy()
    }
    
    ; Event handlers
    typeGui.OnEvent("Close", (*) => SetChoice(""))
    typeGui.OnEvent("Escape", (*) => SetChoice(""))
    
    ; Show GUI and wait for choice
    typeGui.Show("w440 h290")
    
    ; Wait for user choice
    while typeGui.Hwnd {
        Sleep(50)
    }
    
    return chosenType
}

; Show dialog to choose execution method
ShowCommandExecutionDialog(command, commandType) {
    ; Create GUI for command execution choice
    cmdGui := Gui("+AlwaysOnTop", "Run Command - " . commandType)
    cmdGui.SetFont("s10", "Segoe UI")
    
    ; Command display
    cmdGui.Add("Text", "x10 y10", "Command Type: " . commandType)
    cmdGui.Add("Text", "x10 y35", "Command:")
    cmdGui.Add("Edit", "x10 y55 w400 h60 ReadOnly VScroll", command)
    
    ; Execution options
    cmdGui.Add("Text", "x10 y130", "Choose execution method:")
    
    ; Admin button
    adminBtn := cmdGui.Add("Button", "x10 y155 w180 h40", "🛡️ Run as Administrator")
    adminBtn.OnEvent("Click", (*) => ExecuteCommand(command, commandType, true, cmdGui))
    
    ; Normal button
    normalBtn := cmdGui.Add("Button", "x200 y155 w180 h40", "👤 Run as Normal User")
    normalBtn.OnEvent("Click", (*) => ExecuteCommand(command, commandType, false, cmdGui))
    
    ; Cancel button
    cancelBtn := cmdGui.Add("Button", "x390 y155 w40 h40", "❌")
    cancelBtn.OnEvent("Click", (*) => cmdGui.Destroy())
    
    ; Warning for potentially dangerous commands
    if ContainsDangerousCommand(command) {
        warningText := cmdGui.Add("Text", "x10 y205 w420 cRed", "⚠️ Warning: This command may modify system files or settings")
        warningText.SetFont("s9 Bold")
    }
    
    ; Event handlers
    cmdGui.OnEvent("Close", (*) => cmdGui.Destroy())
    cmdGui.OnEvent("Escape", (*) => cmdGui.Destroy())
    
    ; Show GUI
    cmdGui.Show("w440 h" . (ContainsDangerousCommand(command) ? "240" : "210"))
}

; Execute the command with chosen privileges
ExecuteCommand(command, commandType, asAdmin, gui) {
    gui.Destroy()
    
    ; Prepare execution parameters with pause to prevent auto-exit
    if (commandType == "PowerShell") {
        executable := "powershell.exe"
        ; Add Read-Host to prevent PowerShell from closing
        pausedCommand := command . "; Write-Host '`nPress Enter to exit...' -ForegroundColor Yellow; Read-Host"
        params := "-NoProfile -ExecutionPolicy Bypass -Command `"" . pausedCommand . "`""
    } else {
        executable := "cmd.exe"
        ; Add pause to prevent CMD from closing
        pausedCommand := command . " & echo. & echo Press any key to exit... & pause >nul"
        params := "/c `"" . pausedCommand . "`""
    }
    
    try {
        if (asAdmin) {
            ; Run as administrator
            Run("*RunAs " . executable . " " . params, , , &pid)
            ShowMouseTooltip("Command executed as Administrator (" . commandType . ")", 3000)
        } else {
            ; Run as normal user
            Run(executable . " " . params, , , &pid)
            ShowMouseTooltip("Command executed as Normal User (" . commandType . ")", 3000)
        }
    } catch as e {
        SafeMsgBox("Failed to execute command: " . e.Message, "Execution Error", "Iconx")
    }
}

; Check if command contains potentially dangerous operations
ContainsDangerousCommand(command) {
    dangerousPatterns := [
        "format ", "del /", "rd /", "rmdir /", "remove-item", "rm -rf",
        "reg delete", "reg add", "regedit", "bcdedit", "diskpart",
        "net user", "net localgroup", "cacls", "icacls", "takeown",
        "schtasks /delete", "sc delete", "wmic", "powercfg", "shutdown",
        "restart-computer", "stop-computer", "disable-computerrestore",
        "clear-eventlog", "remove-windowsfeature", "uninstall-windowsfeature"
    ]
    
    lowerCommand := StrLower(command)
    for pattern in dangerousPatterns {
        if InStr(lowerCommand, pattern) {
            return true
        }
    }
    return false
}

; =================== TEST HOTKEY ===================
; Test hotkey for mouse tooltip - Win + F11
#F11::TestMouseTooltip() 