#Requires AutoHotkey v2.0-*  ; Ensures only v2.x versions are used

; Version check at runtime
if (SubStr(A_AhkVersion, 1, 1) != "2") {
    MsgBox "This script requires AutoHotkey v2. You are using " A_AhkVersion
    ExitApp
}

; =================== CONFIGURATION SECTION ===================
; Configuration variables (previously config.ahk)
global CONFIG := {
    appName: "AHK Tools for power users",
    version: "2.0.1",
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
    opacity: 230             ; Window opacity (0 = fully transparent, 255 = fully opaque)
}

; =================== GLOBAL VARIABLES ===================
global userSelection := 0
global selectGui := 0
global guiClosed := false
global radioGroup := 0

; Global variable for currency converter GUI
global currencyConverterGui := ""

; =================== TEXT REPLACEMENT SECTION ===================
; Text replacement hotstrings (previously Txt-Replacment.ahk)
; Add your text replacements here using the format:
; ::abbreviation::full text

; Examples (uncomment and modify as needed):
; ::btw::by the way
; ::omg::oh my god
; ::email::your.email@example.com
; ::addr::Your full address here

; =================== UTILITY FUNCTIONS SECTION ===================
; Utility functions (previously functions.ahk)

LoadConfiguration() {
    ; Add any dynamic configuration loading or initialization logic here.
    ; For example, you might override defaults based on external files or user preferences.
    return
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
    ToolTip(currentTime)
    SetTimer () => ToolTip(), -CONFIG.tooltipDuration
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
        ExitApp
    } catch as e {
        MsgBox "Error reloading as admin: " e.Message, "Error", "Iconx"
    }
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
    SetupTrayMenu()
    LoadConfiguration()
    CheckEnvironment()
    
    ; Show startup/reload success message with custom GUI
    ShowSuccessMessage()
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
    
    ; Countdown logic with 10ms precision
    global remainingTime := 2.5
    SetTimer(UpdateCountdown, 10)
}

CloseSuccessGui() {
    global successGui
    SetTimer(UpdateCountdown, 0)  ; Stop the timer
    successGui.Destroy()
}

UpdateCountdown() {
    global remainingTime, okButton, successGui
    remainingTime -= 0.01
    
    if (remainingTime > 0) {
        okButton.Text := Format("OK ({:.3f}s)", remainingTime)
    } else {
        SetTimer(UpdateCountdown, 0)  ; Stop the timer
        successGui.Destroy()
    }
}

SetupTrayMenu() {
    ; Clear default menu items and add custom ones
    A_TrayMenu.Delete()  ; Clear default items
    
    ; Add startup toggle option
    if IsStartupEnabled() {
        A_TrayMenu.Add("Disable Startup", (*) => ToggleStartup(false))
    } else {
        A_TrayMenu.Add("Enable Startup", (*) => ToggleStartup(true))
    }
    
    A_TrayMenu.Add()  ; Separator
    A_TrayMenu.Add("Reload Script", (*) => ReloadScript())
    A_TrayMenu.Add("Reload as Admin", (*) => ReloadAsAdmin())
    A_TrayMenu.Add()  ; Separator
    A_TrayMenu.Add("About", (*) => ShowAbout())
    A_TrayMenu.Add("Exit", (*) => ExitScript())
}

CheckEnvironment() {
    if (!A_IsAdmin) {
        ; Optional: Warn if not running as admin
        MsgBox "Note: Some features may require admin rights. Right click on the tray icon to reload as admin.", "AutoHotkey v2", "Icon!"
    }
}

; =================== URL ENCODING UTILITY ===================
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

; =================== LANGUAGE DETECTION UTILITY ===================
; Function to detect programming language from code
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

; =================== HOTKEYS SECTION ===================

; Toggle numpad functionality with Win+F2
EnableNumpadToggle:=0
#F2::
{
    if !GetKeyState("NumLock", "T") {
        SetNumLockState "On"
        ToolTip "Numpad Mode: ON"
		global EnableNumpadToggle:=1
    } else {
        SetNumLockState "Off"
        ToolTip "Numpad Mode: OFF"
		global EnableNumpadToggle:=0
    }
    SetTimer () => ToolTip(), -1000  ; Hide tooltip after 1 second
}

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

; DuckDuckGo search hotkey
!d::DuckDuckGoSearch()  ; Alt+D triggers the search

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

; Perplexity search hotkey
!s::PerplexitySearch()  ; Alt+S triggers the search

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

; WolframAlpha search hotkey
!a::WolframSearch()  ; Alt+A triggers the search

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
    ToolTip "Searching with WolframAlpha..."
    SetTimer () => ToolTip(), -1000  ; Hide tooltip after 1 second
}

; Win + Enter to open Terminal as admin in the root directory
#Enter::
{
	try {
		Run "*RunAs wt.exe"  ; 'wt.exe' is the Windows Terminal executable
		; Alternative if you prefer PowerShell: Run "*RunAs powershell.exe"
		; Alternative if you prefer Command Prompt: Run "*RunAs cmd.exe"
	} catch as e {
		MsgBox "Error opening Terminal as admin (maybe you pressed 'No' :)):`n" e.Message, "Error", "Iconx"
	}
}

; Win + Delete to suspend/resume the script
#SuspendExempt  ; Following hotkey won't be affected by Suspend
~#Delete::
{
    static suspended := false
    suspended := !suspended
    if suspended {
        Suspend true
        ToolTip "Script Suspended"
    } else {
        Suspend false
        ToolTip "Script Active"
    }
    SetTimer () => ToolTip(), -1000  ; Hide tooltip after 1 second
}
#SuspendExempt false  ; End exempt section

; Win + Home to disconnect/reconnect Wi-Fi and flush DNS
#F3::
{
    if !CheckAdminRequired()
        return
    
    ; Disable Wi-Fi
    ToolTip "Disabling Wi-Fi..."
    RunWait "netsh interface set interface name=`"Wi-Fi`" admin=disable",, "Hide"
    Sleep 2000  ; Wait 2 seconds to ensure the interface is fully disabled
    ToolTip "Wi-Fi disabled"
    Sleep 1000  ; Show tooltip for 1 second

    ; Enable Wi-Fi
    ToolTip "Re-enabling Wi-Fi..."
    RunWait "netsh interface set interface name=`"Wi-Fi`" admin=enable",, "Hide"
    Sleep 2000  ; Wait 2 seconds to ensure the interface is fully enabled
    ToolTip "Wi-Fi re-enabled"
    Sleep 1000  ; Show tooltip for 1 second

    ; Flush DNS cache
    ToolTip "Flushing DNS cache..."
    RunWait "ipconfig /flushdns",, "Hide"
    ToolTip "DNS cache flushed"
    Sleep 1000  ; Show tooltip for 1 second

    ; Final confirmation
    ToolTip "Wi-Fi reconnected and DNS flushed"
    SetTimer () => ToolTip(), -2000  ; Hide tooltip after 2 seconds
}

; Win + Q to force quit active application
#q::
{
    ; Get the active window's process ID
    activePID := WinGetPID("A")  ; Correct syntax for getting PID
    
    ; Try to gracefully close the window first
    PostMessage 0x0010, 0, 0,, "ahk_id " WinGetID("A")  ; Send WM_CLOSE message to active window
    
    ; Wait a moment to see if the window closes
    Sleep 500
    
    ; If the window is still active, force terminate the process
    if WinExist("ahk_pid " activePID) {
        RunWait "taskkill /PID " activePID " /F",, "Hide"
        ToolTip "Application was force quit" 
    } else {
        ToolTip "Application closed "
    }
    
    SetTimer () => ToolTip(), -1500  ; Hide tooltip after 1.5 seconds
}

; Win + F1 to show help dialog with clean formatting
#F1::
{
    MyGui := Gui("+AlwaysOnTop", "Keyboard Shortcuts - AHK Tools")  
    MyGui.SetFont("s9", "Segoe UI")
    
    ; Simple, clean format that actually works in AutoHotkey
    helpText := "
(
SYSTEM SHORTCUTS (some need admin privileges):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Win + Del      →  Suspend/Resume Script

Win + Enter    →  Open Terminal as Administrator  🔐

Win + F1       →  Show This Help Dialog

Win + F2       →  Toggle Numpad Mode (Row numbers 1-9,0)

Win + F3       →  Wi-Fi Reconnect and Flush DNS  🔐

Win + F4       →  Toggle Hourly Chime (for timekeeping)

Win + F12      →  Check Windows File Integrity  🔐

Win + C        →  Open Calculator

Win + Q        →  Force Quit Active Application

Win + X        →  System Power Options


ALT SHORTCUTS (select the text first):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Alt + A        →  WolframAlpha Search

Alt + C        →  Currency Converter (Auto-detects amounts)

Alt + D        →  DuckDuckGo Search

Alt + E        →  Open Selected Text in Editor

Alt + G        →  Search in Game Databases

Alt + S        →  Perplexity Search

Alt + T        →  Open Selected Text in Notepad

Alt + W        →  Open Selected URL in Browser


🔐 = Requires Administrator Privileges
)"
    
    MyGui.Add("Text", "w450", helpText)
    MyGui.Add("Button", "w100 Default", "OK").OnEvent("Click", (*) => MyGui.Destroy())
    
    ; Add escape key handler
    MyGui.OnEvent("Escape", (*) => MyGui.Destroy())
    
    ; Apply theme
    ApplyThemeToGui(MyGui)
    
    MyGui.Show()
}

; Win + X for system power options
#x::
{
    ; Create the GUI
    powerGui := Gui()
    powerGui.Opt("+AlwaysOnTop")
    powerGui.SetFont("s10", "Segoe UI")
    powerGui.Add("Text",, "Select an option:")
    
    ; Add buttons for each option
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
    
    ; Make Sleep pre-selected (focused)
    btnSleep.Focus()
    
    ; Add Esc key to close the GUI
    powerGui.OnEvent("Escape", (*) => powerGui.Destroy())
    
    ; Apply theme
    ApplyThemeToGui(powerGui)
    
    ; Show the GUI
    powerGui.Show()
}

; Initialize script start time
scriptStartTime := A_TickCount

; Win + F4 to toggle hourly chime to keep track of time
#F4::
{
    static chimeActive := false
    chimeActive := !chimeActive  ; Toggle state
    
    if (chimeActive) {
        ToolTip "Hourly chime activated"
        ; Start timer and play immediately
        SetTimer PlayHourlyChime, 3600000  ; 3600000 ms = 1 hour
        PlayHourlyChime()
    } else {
        ToolTip "Hourly chime deactivated"
        SetTimer PlayHourlyChime, 0  ; Disable timer
    }
    
    SetTimer () => ToolTip(), -2000  ; Hide tooltip after 2 seconds
}

PlayHourlyChime() {
    global scriptStartTime
    
    ; Calculate hours since script started
    hoursPassed := ((A_TickCount - scriptStartTime) // 3600000)  ; Convert milliseconds to hours
    
    ; Show tooltip with hours passed
    ToolTip "Hourly chime`nHours since activation: " hoursPassed
    
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
    
    ; Remove tooltip after 3 seconds
    SetTimer () => ToolTip(), -3000
}

; Win + C to open calculator
#c::Run "calc.exe"

; Alt + E to open selected text in editor with language detection
!e::
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
        ToolTip "Opening " lineCount " lines of " language " code..."
    } catch as e {
        MsgBox "Failed to open editor: " e.Message, "Error", "Iconx"
    }
    
    ; Restore the original clipboard content
    A_Clipboard := savedClipboard
    savedClipboard := ""  ; Free memory
    
    ; Remove tooltip after 2 seconds
    SetTimer () => ToolTip(), -2000
}

; Alt + G to search selected text in game databases
!g::
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
        
        ToolTip "Searching game databases..."
    } catch as e {
        MsgBox "Failed to open game databases: " e.Message, "Error", "Iconx"
    }
    
    ; Restore the original clipboard content
    A_Clipboard := savedClipboard
    savedClipboard := ""  ; Free memory
    
    ; Remove tooltip after 1.5 seconds
    SetTimer () => ToolTip(), -1500
}

; Alt + W to open selected URL in web browser
!w::
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
            ToolTip "Opening URL in browser..."
        } catch as e {
            MsgBox "Failed to open URL: " e.Message, "Error", "Iconx"
        }
    } else {
        MsgBox "Selected text doesn't appear to be a valid URL.", "Error", "Iconx"
    }
    
    ; Restore the original clipboard content
    A_Clipboard := savedClipboard
    savedClipboard := ""  ; Free memory
    
    ; Remove tooltip after 1.5 seconds
    SetTimer () => ToolTip(), -1500
}

; Alt + T to open selected text in Notepad
!t::
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
        ToolTip "Opening selected text in Notepad..."
    } catch as e {
        MsgBox "Failed to open Notepad: " e.Message, "Error", "Iconx"
    }

    ; Restore the original clipboard content
    A_Clipboard := savedClipboard
    savedClipboard := ""  ; Free memory

    ; Remove tooltip after 1.5 seconds
    SetTimer () => ToolTip(), -1500
}

; Win + F12 to check Windows file integrity
#F12::
{
    if !CheckAdminRequired()
        return

    selectGui := Gui()
    selectGui.Opt("+AlwaysOnTop +ToolWindow")
    selectGui.SetFont("s10", "Segoe UI")
    selectGui.Title := "AHK-Tools.ahk"

    selectGui.Add("Text", "w400", "Windows File Integrity Check")
    selectGui.Add("Text", "w400", "Select the type of check to perform:")

    ; Only the first radio in the group should have "Group"
    selectGui.Add("Radio", "vCheckType Group checked", "Quick Check (DISM /ScanHealth) - Basic system file check")
    selectGui.Add("Radio",, "Full Check (DISM /CheckHealth) - Detailed system file check")
    selectGui.Add("Radio",, "Repair Check (DISM /RestoreHealth) - Attempt to repair system files")
    selectGui.Add("Radio",, "SFC Scan (sfc /scannow) - System File Checker scan")
    selectGui.Add("Radio",, "Complete Check (DISM + SFC) - Full repair and verification (recommended)")

    btnStart := selectGui.Add("Button", "xm w100", "Start Check")
    btnStart.OnEvent("Click", StartCheck)
    btnCancel := selectGui.Add("Button", "x+10 w100", "Cancel")
    btnCancel.OnEvent("Click", (*) => selectGui.Destroy())
    selectGui.OnEvent("Escape", (*) => selectGui.Destroy())
    selectGui.Show()

    StartCheck(*) {
        try {
            checkType := selectGui["CheckType"].Value
            if (!checkType)
                checkType := 1
            selectGui.Destroy()

            progressGui := Gui()
            progressGui.Opt("+AlwaysOnTop +ToolWindow")
            progressGui.SetFont("s10", "Segoe UI")
            progressGui.Add("Text", "w400", "Running Windows File Integrity Check...")
            progressGui.Add("Text", "w400", "This may take several minutes. Please wait.")
            progressGui.Show()

            command := ""
            switch checkType {
                case 1:
                    command := "DISM.exe /Online /Cleanup-Image /ScanHealth"
                case 2:
                    command := "DISM.exe /Online /Cleanup-Image /CheckHealth"
                case 3:
                    command := "DISM.exe /Online /Cleanup-Image /RestoreHealth"
                case 4:
                    command := "sfc /scannow"
                case 5:
                    command := "DISM.exe /Online /Cleanup-Image /RestoreHealth & sfc /scannow"
            }

            try {
                psCmd := '*RunAs powershell.exe -WindowStyle Normal -Command "Start-Process cmd -ArgumentList "/k ' command '\" -Verb RunAs"'
                Run(psCmd)
            } catch as e {
                MsgBox "Error running command: " e.Message, "Error", "Iconx"
            }

            progressGui.Destroy()
            ToolTip "File integrity check completed"
            SetTimer () => ToolTip(), -2000
        } catch as e {
            MsgBox "An error occurred: " e.Message, "Error", "Iconx"
        }
    }
}

; Win + C for currency converter with GUI and dropdowns
!c::
{
    ; Try to get selected text first
    selectedText := ""
    savedClip := ClipboardAll()
    A_Clipboard := ""
    Send "^c"
    if ClipWait(0.3) {
        selectedText := Trim(A_Clipboard)
    }
    A_Clipboard := savedClip
    
    ; Parse selected text for amount and currency
    parsedAmount := ""
    parsedCurrency := ""
    
    if selectedText {
        ; Currency symbol mappings
        currencyMap := Map(
            "$", "USD",
            "€", "EUR", 
            "£", "GBP",
            "¥", "JPY",
            "₹", "INR",
            "₩", "KRW",
            "¢", "USD",  ; cents
            "₽", "RUB",
            "₨", "PKR",
            "﷼", "OMR",
            "₪", "ILS",  ; Israeli Shekel
            "₦", "NGN",  ; Nigerian Naira
            "₡", "CRC",  ; Costa Rican Colón
            "₵", "GHS",  ; Ghanaian Cedi
            "₸", "KZT",  ; Kazakhstani Tenge
            "₴", "UAH",  ; Ukrainian Hryvnia
            "₱", "PHP",  ; Philippine Peso
            "₲", "PYG",  ; Paraguayan Guaraní
            "₫", "VND",  ; Vietnamese Dong
            "₭", "LAK",  ; Lao Kip
            "₯", "GRD",  ; Greek Drachma (historical)
            "₰", "PF",   ; German Pfennig (historical)
            "₳", "ARA",  ; Argentine Austral (historical)
            "₼", "AZN",  ; Azerbaijani Manat
            "₾", "GEL",  ; Georgian Lari
            "₿", "BTC",  ; Bitcoin
            "＄", "USD", ; Full-width dollar sign
            "￠", "USD", ; Full-width cent sign
            "￡", "GBP", ; Full-width pound sign
            "￥", "JPY", ; Full-width yen sign
            "￦", "KRW", ; Full-width won sign
            "﹩", "USD", ; Small dollar sign
            "＃", "USD", ; Number sign (sometimes used for USD)
            "₨", "INR",  ; Generic Rupee (could be multiple countries)
            "R", "ZAR",  ; South African Rand
            "R$", "BRL", ; Brazilian Real
            "kr", "SEK", ; Swedish Krona (also NOK, DKK)
            "zł", "PLN", ; Polish Złoty
            "₺", "TRY", ; Turkish Lira
            "₼", "AZN", ; Azerbaijani Manat
            "֏", "AMD", ; Armenian Dram
            "₶", "LVL", ; Latvian Lats (historical)
            "₷", "SPL", ; Seborgan Luigino
            "₹", "INR", ; Indian Rupee
            "₻", "CET", ; Ceti
            "₽", "RUB", ; Russian Ruble
            "₾", "GEL", ; Georgian Lari
            "₿", "BTC", ; Bitcoin
            "﷼", "SAR", ; Saudi Riyal (also used for other Gulf currencies)
            "₦", "NGN", ; Nigerian Naira
            "₡", "CRC", ; Costa Rican Colón
            "₹", "LKR", ; Sri Lankan Rupee
            "₨", "NPR", ; Nepalese Rupee
            "₹", "BTN", ; Bhutanese Ngultrum
            "₹", "MVR"  ; Maldivian Rufiyaa
        )
        
        ; Try different patterns to extract amount and currency
        ; Pattern 1: Single character symbols before amount: $45.50, €100, ₹500
        if RegExMatch(selectedText, "([€$£¥₹₩¢₽₨﷼₪₦₡₵₸₴₱₲₫₭₯₰₳₼₾₿＄￠￡￥￦﹩＃֏₶₷₻₺])(\d+(?:\.\d+)?)", &match) {
            symbol := match[1]
            parsedAmount := match[2]
            if currencyMap.Has(symbol)
                parsedCurrency := currencyMap[symbol]
        }
        ; Pattern 2: Multi-character symbols before amount: R$100, kr500
        else if RegExMatch(selectedText, "(R\$|kr|zł)\s*(\d+(?:\.\d+)?)", &match) {
            symbol := match[1]
            parsedAmount := match[2]
            if currencyMap.Has(symbol)
                parsedCurrency := currencyMap[symbol]
        }
        ; Pattern 3: Single character symbols after amount: 45.50$, 100€
        else if RegExMatch(selectedText, "(\d+(?:\.\d+)?)([€$£¥₹₩¢₽₨﷼₪₦₡₵₸₴₱₲₫₭₯₰₳₼₾₿＄￠￡￥￦﹩＃֏₶₷₻₺])", &match) {
            parsedAmount := match[1]
            symbol := match[2]
            if currencyMap.Has(symbol)
                parsedCurrency := currencyMap[symbol]
        }
        ; Pattern 4: Multi-character symbols after amount: 100R$, 500kr, 250zł
        else if RegExMatch(selectedText, "(\d+(?:\.\d+)?)\s*(R\$|kr|zł)", &match) {
            parsedAmount := match[1]
            symbol := match[2]
            if currencyMap.Has(symbol)
                parsedCurrency := currencyMap[symbol]
        }
        ; Pattern 5: Just a number (no currency symbol) - assume USD
        else if RegExMatch(selectedText, "^\d+(?:\.\d+)?$") {
            parsedAmount := selectedText
            parsedCurrency := "USD"  ; Default to USD for plain numbers
        }
        ; Pattern 6: Currency codes like "USD 100" or "100 USD"
        else if RegExMatch(selectedText, "([A-Z]{3})\s*(\d+(?:\.\d+)?)", &match) {
            parsedCurrency := match[1]
            parsedAmount := match[2]
        }
        else if RegExMatch(selectedText, "(\d+(?:\.\d+)?)\s*([A-Z]{3})", &match) {
            parsedAmount := match[1]
            parsedCurrency := match[2]
        }
    }
    
    ; Create GUI
    global currencyGui := Gui("+AlwaysOnTop", "Currency Converter")
    currencyGui.SetFont("s10", "Segoe UI")
    
    ; Common currencies list - expanded with more world currencies
    currencies := [
        "AED", "AFN", "ALL", "AMD", "ANG", "AOA", "ARS", "AUD", "AWG", "AZN",
        "BAM", "BBD", "BDT", "BGN", "BHD", "BIF", "BMD", "BND", "BOB", "BRL", "BSD", "BTN", "BWP", "BYN", "BZD",
        "CAD", "CDF", "CHF", "CLP", "CNY", "COP", "CRC", "CUC", "CUP", "CVE", "CZK",
        "DJF", "DKK", "DOP", "DZD",
        "EGP", "ERN", "ETB", "EUR",
        "FJD", "FKP",
        "GBP", "GEL", "GHS", "GIP", "GMD", "GNF", "GTQ", "GYD",
        "HKD", "HNL", "HRK", "HTG", "HUF",
        "IDR", "ILS", "INR", "IQD", "IRR", "ISK",
        "JMD", "JOD", "JPY",
        "KES", "KGS", "KHR", "KMF", "KPW", "KRW", "KWD", "KYD", "KZT",
        "LAK", "LBP", "LKR", "LRD", "LSL", "LYD",
        "MAD", "MDL", "MGA", "MKD", "MMK", "MNT", "MOP", "MRU", "MUR", "MVR", "MWK", "MXN", "MYR", "MZN",
        "NAD", "NGN", "NIO", "NOK", "NPR", "NZD",
        "OMR",
        "PAB", "PEN", "PGK", "PHP", "PKR", "PLN", "PYG",
        "QAR",
        "RON", "RSD", "RUB", "RWF",
        "SAR", "SBD", "SCR", "SDG", "SEK", "SGD", "SHP", "SLE", "SLL", "SOS", "SRD", "STN", "SYP", "SZL",
        "THB", "TJS", "TMT", "TND", "TOP", "TRY", "TTD", "TWD", "TZS",
        "UAH", "UGX", "USD", "UYU", "UZS",
        "VED", "VES", "VND", "VUV",
        "WST",
        "XAF", "XCD", "XDR", "XOF", "XPF",
        "YER",
        "ZAR", "ZMW", "ZWL"
    ]
    
    ; Amount input
    currencyGui.Add("Text", "x10 y10", "Amount:")
    global amountEdit := currencyGui.Add("Edit", "x10 y30 w150")
    amountEdit.OnEvent("Change", (*) => AutoConvert())
    
    ; Pre-fill amount if detected
    if parsedAmount
        amountEdit.Text := parsedAmount
    
    ; From currency dropdown
    currencyGui.Add("Text", "x10 y65", "From Currency:")
    global fromCombo := currencyGui.Add("ComboBox", "x10 y85 w150", currencies)
    fromCombo.OnEvent("Change", (*) => AutoConvert())
    
    ; Set detected currency or default to USD
    if parsedCurrency && HasValue(currencies, parsedCurrency)
        fromCombo.Text := parsedCurrency
    else
        fromCombo.Text := "USD"
    
    ; To currency dropdown
    currencyGui.Add("Text", "x10 y120", "To Currency:")
    global toCombo := currencyGui.Add("ComboBox", "x10 y140 w150", currencies)
    toCombo.Text := "OMR"  ; Default selection
    toCombo.OnEvent("Change", (*) => AutoConvert())
    
    ; Result display - Main conversion result
    global resultText := currencyGui.Add("Edit", "x10 y180 w300 h35 ReadOnly")
    resultText.SetFont("s12 Bold", "Segoe UI")  ; Larger, bold font for the result
    if parsedAmount && parsedCurrency
        resultText.Text := "Auto-detected: " parsedAmount " " parsedCurrency
    else if parsedAmount
        resultText.Text := "Auto-detected amount: " parsedAmount
    else
        resultText.Text := "Enter amount and select currencies"
    
    ; Timestamp display - Smaller font
    global timestampText := currencyGui.Add("Edit", "x10 y220 w300 h25 ReadOnly")
    timestampText.SetFont("s8", "Segoe UI")  ; Smaller font for timestamp
    timestampText.Text := "for automatic conversion"
    
    ; Buttons
    closeBtn := currencyGui.Add("Button", "x10 y255 w100 h30", "Close")
    closeBtn.OnEvent("Click", (*) => currencyGui.Destroy())
    
    swapBtn := currencyGui.Add("Button", "x120 y255 w100 h30", "Swap")
    swapBtn.OnEvent("Click", (*) => SwapCurrencies())
    
    ; Add escape key handler to close GUI
    currencyGui.OnEvent("Escape", (*) => currencyGui.Destroy())
    
    ; Show GUI
    currencyGui.Show("w320 h300")
    
    ; Apply theme after all controls are created
    ApplyThemeToGui(currencyGui)
    
    amountEdit.Focus()
    
    ; Auto-convert if we have both amount and currency (including plain numbers defaulting to USD)
    if parsedAmount && parsedCurrency {
        SetTimer () => AutoConvert(), -100  ; Small delay to ensure GUI is ready
    }
    else if parsedAmount {  ; Plain number detected, will use USD as default
        SetTimer () => AutoConvert(), -100  ; Convert with USD default
    }
}

; Helper function to check if value exists in array
HasValue(arr, value) {
    for item in arr {
        if (item = value)
            return true
    }
    return false
}

; Function to swap from/to currencies
SwapCurrencies() {
    try {
        fromCur := fromCombo.Text
        toCur := toCombo.Text
        fromCombo.Text := toCur
        toCombo.Text := fromCur
    } catch as e {
        ; If swap fails, show error in result
        try {
            resultText.Text := "Error swapping currencies: " e.Message
        }
    }
}

; Currency conversion function using Python instead of PowerShell
ConvertCurrencyPS() {
    AutoConvert()
}

AutoConvert() {
    ; Add a timer to delay conversion while user is still typing
    static conversionTimer := 0
    if conversionTimer
        SetTimer conversionTimer, 0  ; Cancel previous timer
    
    conversionTimer := () => DoConversion()
    SetTimer conversionTimer, -500  ; Convert after 500ms delay
}

DoConversion() {
    ; Get values from GUI controls properly
    try {
        amount := Trim(amountEdit.Text)
        fromCur := fromCombo.Text
        toCur := toCombo.Text
    } catch as e {
        ; If control access fails, show error
        try {
            resultText.Text := "Error accessing GUI controls: " e.Message
        }
        return
    }
    
    ; Validate inputs
    if !amount {
        resultText.Text := "Please enter an amount"
        timestampText.Text := ""
        return
    }
    
    if !RegExMatch(amount, "^\d+(\.\d+)?$") {
        resultText.Text := "Invalid amount. Please enter numbers only."
        timestampText.Text := ""
        return
    }
    
    if !fromCur || !toCur {
        resultText.Text := "Please select both currencies"
        timestampText.Text := ""
        return
    }
    
    if (fromCur = toCur) {
        currentTime := FormatTime(, "yyyy-MM-dd HH:mm:ss")
        resultText.Text := amount " " fromCur " = " amount " " toCur
        timestampText.Text := "Same currency: " currentTime
        return
    }
    
    ; Currency converter using Python instead of PowerShell
    try {
        resultText.Text := "Converting " amount " " fromCur " to " toCur "..."
        
        ; Initialize all variables to avoid scope issues
        tempScript := ""
        tempOutput := ""
        pythonScript := ""
        debugInfo := "Starting conversion...`n"
        
        ; Create Python script for currency conversion
        tempOutput := A_ScriptDir "\currency_output.txt"
        pythonScript := 'import sys' . "`n"
        pythonScript .= 'import json' . "`n"
        pythonScript .= 'try:' . "`n"
        pythonScript .= '    import urllib.request' . "`n"
        pythonScript .= '    from_cur, to_cur, amount = sys.argv[1], sys.argv[2], float(sys.argv[3])' . "`n"
        pythonScript .= '    url = f"https://api.exchangerate-api.com/v4/latest/{from_cur}"' . "`n"
        pythonScript .= '    ' . "`n"
        pythonScript .= '    # Write to hardcoded output file' . "`n"
        pythonScript .= '    with open(r"' . tempOutput . '", "w", encoding="utf-8") as output:' . "`n"
        pythonScript .= '        output.write(f"Fetching rates for {from_cur}...\\n")' . "`n"
        pythonScript .= '        output.flush()' . "`n"
        pythonScript .= '        ' . "`n"
        pythonScript .= '        with urllib.request.urlopen(url, timeout=10) as response:' . "`n"
        pythonScript .= '            data = json.loads(response.read().decode())' . "`n"
        pythonScript .= '        ' . "`n"
        pythonScript .= '        if to_cur in data["rates"]:' . "`n"
        pythonScript .= '            rate = data["rates"][to_cur]' . "`n"
        pythonScript .= '            result = amount * rate' . "`n"
        pythonScript .= '            output.write(f"{amount} {from_cur} = {result:.4f} {to_cur}\\n")' . "`n"
        pythonScript .= '            output.write(f"Rate: 1 {from_cur} = {rate:.6f} {to_cur}\\n")' . "`n"
        pythonScript .= '            output.write("API: exchangerate-api.com\\n")' . "`n"
        pythonScript .= '        else:' . "`n"
        pythonScript .= '            output.write(f"Currency {to_cur} not found\\n")' . "`n"
        pythonScript .= 'except Exception as e:' . "`n"
        pythonScript .= '    with open(r"' . tempOutput . '", "w", encoding="utf-8") as output:' . "`n"
        pythonScript .= '        output.write(f"Error: {e}\\n")' . "`n"
        
        ; Save Python script to file - try script directory instead of temp
        tempScript := A_ScriptDir "\currency_convert.py"
        
        debugInfo .= "Temp script: " tempScript "`n"
        debugInfo .= "Temp output: " tempOutput "`n"
        
        ; Clean up any existing files safely
        if FileExist(tempScript)
            try FileDelete(tempScript)
        if FileExist(tempOutput)
            try FileDelete(tempOutput)
        
        ; Create the Python script file
        try {
            FileAppend(pythonScript, tempScript)
            resultText.Text := "Python script created successfully. Testing Python..."
            
            ; Try Python commands
            pythonCommands := ["python", "python3", "py"]
            pythonWorked := false
            result := ""
            
            ; First, test if Python is accessible at all
            for index, pythonCmd in pythonCommands {
                debugInfo .= "Testing " pythonCmd " availability: "
                try {
                    ; Try to run Python version command without output redirection
                    RunWait(pythonCmd ' --version', , "Hide")
                    debugInfo .= "✓ Command runs (exit code 0)`n"
                    
                    ; Now try running our actual currency script (Python writes to file directly)
                    scriptCmd := pythonCmd ' "' tempScript '" "' fromCur '" "' toCur '" "' amount '"'
                    debugInfo .= "Running currency script: "
                    RunWait(scriptCmd, , "Hide")
                    
                    ; Check if Python created the output file
                    if FileExist(tempOutput) {
                        result := FileRead(tempOutput)
                        debugInfo .= "✓ Got output file`n"
                        if result && InStr(result, fromCur) && InStr(result, toCur) && !InStr(result, "Error:") {
                            pythonWorked := true
                            debugInfo .= "✓ SUCCESS!`n"
                            break
                        } else {
                            debugInfo .= "✗ Script error: " SubStr(result, 1, 100) "...`n"
                        }
                    } else {
                        debugInfo .= "✗ No output file created by Python script`n"
                    }
                } catch as e {
                    debugInfo .= "✗ Command failed: " e.Message "`n"
                }
            }
            
            try FileDelete(tempScript)
            
            if pythonWorked {
                try FileDelete(tempOutput)
                
                if result {
                    ; First, properly convert \n to actual newlines
                    result := StrReplace(result, "\n", "`n")
                    result := StrReplace(result, "\r", "")
                    
                    ; Parse the result to extract just the conversion value
                    lines := StrSplit(result, "`n")
                    conversionLine := ""
                    
                    for line in lines {
                        line := Trim(line)
                        ; Look for the main conversion line (contains = and both currencies)
                        if InStr(line, " = ") && InStr(line, fromCur) && InStr(line, toCur) && !InStr(line, "Rate:") {
                            conversionLine := Trim(line)  ; Extra trim to ensure clean line
                            break
                        }
                    }
                    
                    ; Format with timestamp
                    currentTime := FormatTime(, "yyyy-MM-dd HH:mm:ss")
                    if conversionLine {
                        resultText.Text := conversionLine
                        timestampText.Text := "Rate updated: " currentTime
                    } else {
                        resultText.Text := "Conversion completed"
                        timestampText.Text := "Rate updated: " currentTime
                    }
                } else {
                    resultText.Text := "No conversion data received"
                    timestampText.Text := ""
                }
            } else {
                try FileDelete(tempOutput)
                
                ; Fallback: Simple hardcoded converter for common currencies
                rates := Map(
                    "USD_OMR", 0.385,
                    "OMR_USD", 2.597,
                    "USD_EUR", 0.85,
                    "EUR_USD", 1.176,
                    "USD_GBP", 0.73,
                    "GBP_USD", 1.37
                )
                
                rateKey := fromCur "_" toCur
                if rates.Has(rateKey) {
                    rate := rates[rateKey]
                    result := amount * rate
                    currentTime := FormatTime(, "yyyy-MM-dd HH:mm:ss")
                    resultText.Text := amount " " fromCur " = " Round(result, 4) " " toCur
                    timestampText.Text := "Fallback rate used: " currentTime
                } else {
                    resultText.Text := "Currency pair not supported"
                    timestampText.Text := "Supported: USD⟷OMR, USD⟷EUR, USD⟷GBP"
                }
            }
            
        } catch as e {
            ; If we can't create files, skip Python and go straight to fallback
            ; Fallback: Simple hardcoded converter for common currencies
            rates := Map(
                "USD_OMR", 0.385,
                "OMR_USD", 2.597,
                "USD_EUR", 0.85,
                "EUR_USD", 1.176,
                "USD_GBP", 0.73,
                "GBP_USD", 1.37
            )
            
            rateKey := fromCur "_" toCur
            if rates.Has(rateKey) {
                rate := rates[rateKey]
                result := amount * rate
                currentTime := FormatTime(, "yyyy-MM-dd HH:mm:ss")
                resultText.Text := amount " " fromCur " = " Round(result, 4) " " toCur
                timestampText.Text := "Fallback rate used: " currentTime
            } else {
                resultText.Text := "Currency pair not supported"
                timestampText.Text := "Supported: USD⟷OMR, USD⟷EUR, USD⟷GBP"
            }
        }
        
    } catch as e {
        resultText.Text := "Error in currency conversion: " e.Message
        timestampText.Text := ""
    }
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
        MsgBox "Error: " e.Message "`n`nTo manually set startup:`n1. Copy a shortcut of this script`n2. Paste it to: " A_Startup, "Error", "Iconx"
    }
}

IsStartupEnabled() {
    ; Check if startup shortcut exists
    return FileExist(A_Startup "\AHK-Tools.lnk")
}

; Function to show help dialog
ShowHelpDialog() {
    MyGui := Gui("+AlwaysOnTop", "Keyboard Shortcuts - AHK Tools")  
    MyGui.SetFont("s9", "Segoe UI")
    
    ; Simple, clean format that actually works in AutoHotkey
    helpText := "
(
SYSTEM SHORTCUTS (some need admin privileges):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Win + Del      →  Suspend/Resume Script

Win + Enter    →  Open Terminal as Administrator  🔐

Win + F1       →  Show This Help Dialog

Win + F2       →  Toggle Numpad Mode (Row numbers 1-9,0)

Win + F3       →  Wi-Fi Reconnect and Flush DNS  🔐

Win + F4       →  Toggle Hourly Chime (for timekeeping)

Win + F12      →  Check Windows File Integrity  🔐

Win + C        →  Open Calculator

Win + Q        →  Force Quit Active Application

Win + X        →  System Power Options


ALT SHORTCUTS (select the text first):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Alt + A        →  WolframAlpha Search

Alt + C        →  Currency Converter (Auto-detects amounts)

Alt + D        →  DuckDuckGo Search

Alt + E        →  Open Selected Text in Editor

Alt + G        →  Search in Game Databases

Alt + S        →  Perplexity Search

Alt + T        →  Open Selected Text in Notepad

Alt + W        →  Open Selected URL in Browser


🔐 = Requires Administrator Privileges
)"
    
    MyGui.Add("Text", "w450", helpText)
    MyGui.Add("Button", "w100 Default", "OK").OnEvent("Click", (*) => MyGui.Destroy())
    
    ; Add escape key handler
    MyGui.OnEvent("Escape", (*) => MyGui.Destroy())
    
    ; Apply theme
    ApplyThemeToGui(MyGui)
    
    MyGui.Show()
}
