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
    version: "1.0.1",
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
    opacity: 230              ; Window opacity (0 = fully transparent, 255 = fully opaque)
}

; =================== GLOBAL VARIABLES ===================
global userSelection := 0
global selectGui := 0
global guiClosed := false
global radioGroup := 0

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

; =================== SCRIPT INITIALIZATION ===================
; Ensure single instance
#SingleInstance Force

; Initialize the script
InitializeScript()

InitializeScript() {
    SetupTrayMenu()
    LoadConfiguration()
    CheckEnvironment()
    
    ; Show startup help message with 5-second timeout
    MsgBox "Press Win + F1 anytime to see keyboard shortcuts", "Keyboard Shortcuts Available", "T5 64"  ; T5 for 5-second timeout, 64 for information icon
}

SetupTrayMenu() {
    ; Clear default menu items and add custom ones
    A_TrayMenu.Delete()  ; Clear default items
    A_TrayMenu.Add("Settings", (*) => ShowSettings())
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

; Win + F1 to show help dialog using a real table format with a monospaced font
#F1::
{
    MyGui := Gui()  
    MyGui.Opt("+AlwaysOnTop")
    ; Use a monospaced font to ensure the table alignment is preserved
    MyGui.SetFont("s10", "Consolas")
    
    helpText := "
    (
┌───────────────┬───────────────────────────────────────────────┐
│   Shortcut    │                Description                    │
├───────────────┼───────────────────────────────────────────────┤
│ Win + Del     │ Suspend/Resume Script                         │
│ Win + Enter   │ Open Terminal as Administrator                │
│ Win + F1      │ Show This Help Dialog                         │
│ Win + F2      │ Toggle Numpad Mode (Row numbers 1-9,0)        │
│ Win + F3      │ Wi-Fi Reconnect and Flush DNS                 │
│ Win + F4      │ Toggle Hourly Chime (Plays sound every hour)  │
│ Win + F12     │ Check Windows File Integrity                  │
│ Win + C       │ Open Calculator                               │
│ Win + Q       │ Force Quit Active Application                 │
│ Win + X       │ System Power Options (Sleep/Shutdown/Logout)  │
├───────────────┼───────────────────────────────────────────────┤
│ Alt + A       │ WolframAlpha Search                           │
│ Alt + D       │ DuckDuckGo Search                             │
│ Alt + E       │ Open Selected Text in Editor                  │
│ Alt + F       │ DeepSeek AI Search                            │
│ Alt + G       │ Search in Game Databases                      │
│ Alt + S       │ Perplexity Search                             │
│ Alt + T       │ Open Selected Text in Notepad                  │
│ Alt + W       │ Open Selected URL in Browser                  │
└───────────────┴───────────────────────────────────────────────┘
    )"
    
    MyGui.Add("Text",, helpText)
    MyGui.Add("Link",, 'GitHub: <a href="https://github.com/ahmedalfahdi">https://github.com/ahmedalfahdi</a>')
    MyGui.Add("Button", "Default", "OK").OnEvent("Click", (*) => MyGui.Destroy())
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
                psCmd := '*RunAs powershell.exe -WindowStyle Normal -Command "Start-Process cmd -ArgumentList \"/k ' command '\" -Verb RunAs"'
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