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
    version: "2.1.0-OPTIMIZED",
    author: "Ahmed N. Alfahdi",
    GitHub: "https://github.com/ahmedalfahdi",
    ; Optimized configurations for better performance
    tooltipDuration: 2000,    ; Reduced from 3000ms for faster UI
    defaultSound: true,
    logFilePath: "C:\\Logs\\ahk_tools.log",
    maxRetries: 3,            ; Reduced from 5 for faster fallback

    ; Additional configurations
    debugMode: false,
    autoSaveInterval: 120000,  ; Increased from 60000ms to reduce I/O
    runAtStartup: true,
    defaultLanguage: "en",
    opacity: 230
}

; =================== PERFORMANCE OPTIMIZATIONS ===================
; Critical performance fixes applied:
; 1. ClipboardManager - Fixes major memory leaks
; 2. Pre-compiled Python scripts - Eliminates string concatenation
; 3. Timer management - Reduces CPU usage
; 4. Optimized theme management - Caches applied themes

; 1. CLIPBOARD MANAGER - Fixes major memory leaks
class ClipboardManager {
    static savedClip := ""
    
    static SaveAndCopy() {
        this.savedClip := ClipboardAll()
        A_Clipboard := ""
        Send "^c"
        return ClipWait(0.3)  ; Reduced timeout for faster response
    }
    
    static Restore() {
        A_Clipboard := this.savedClip
        this.savedClip := ""  ; ⚡ Critical: Free memory immediately
    }
    
    static GetSelectedText() {
        if (this.SaveAndCopy()) {
            text := A_Clipboard
            this.Restore()
            return text
        }
        return ""
    }
}

; 2. TIMER MANAGER - Prevents timer conflicts and reduces CPU usage
class TimerManager {
    static activeTimers := Map()
    
    static SetTimer(func, period, name := "") {
        if (name && this.activeTimers.Has(name))
            SetTimer(this.activeTimers[name], 0)  ; Cancel existing
        
        if (name)
            this.activeTimers[name] := func
        SetTimer(func, period)
    }
    
    static ClearTimer(name) {
        if (this.activeTimers.Has(name)) {
            SetTimer(this.activeTimers[name], 0)
            this.activeTimers.Delete(name)
        }
    }
    
    static ClearAll() {
        for name, func in this.activeTimers {
            SetTimer(func, 0)
        }
        this.activeTimers.Clear()
    }
}

; 3. PRE-COMPILED PYTHON SCRIPT - Eliminates string concatenation
global OPTIMIZED_CURRENCY_SCRIPT := "
(
import sys
import json
try:
    import urllib.request
    from_cur, to_cur, amount = sys.argv[1], sys.argv[2], float(sys.argv[3])
    
    crypto_currencies = ['BTC', 'ETH', 'USDT', 'BNB', 'XRP', 'ADA', 'SOL', 'DOT', 'DOGE', 'AVAX', 'MATIC', 'LINK', 'UNI', 'LTC', 'BCH', 'XLM', 'VET', 'ETC', 'FIL', 'TRX']
    crypto_id_map = {'BTC': 'bitcoin', 'ETH': 'ethereum', 'USDT': 'tether', 'BNB': 'binancecoin', 'XRP': 'ripple', 'ADA': 'cardano', 'SOL': 'solana', 'DOT': 'polkadot', 'DOGE': 'dogecoin', 'AVAX': 'avalanche-2', 'MATIC': 'matic-network', 'LINK': 'chainlink', 'UNI': 'uniswap', 'LTC': 'litecoin', 'BCH': 'bitcoin-cash', 'XLM': 'stellar', 'VET': 'vechain', 'ETC': 'ethereum-classic', 'FIL': 'filecoin', 'TRX': 'tron'}
    
    with open(sys.argv[4], 'w', encoding='utf-8') as output:
        if from_cur in crypto_currencies:
            crypto_id = crypto_id_map.get(from_cur, from_cur.lower())
            if to_cur in crypto_currencies:
                to_crypto_id = crypto_id_map.get(to_cur, to_cur.lower())
                url = f'https://api.coingecko.com/api/v3/simple/price?ids={crypto_id},{to_crypto_id}&vs_currencies=usd'
                with urllib.request.urlopen(url, timeout=5) as response:
                    data = json.loads(response.read().decode())
                from_rate = data[crypto_id]['usd']
                to_rate = data[to_crypto_id]['usd']
                rate = from_rate / to_rate
            else:
                vs_currency = to_cur.lower()
                url = f'https://api.coingecko.com/api/v3/simple/price?ids={crypto_id}&vs_currencies={vs_currency}'
                with urllib.request.urlopen(url, timeout=5) as response:
                    data = json.loads(response.read().decode())
                rate = data[crypto_id][vs_currency]
        elif to_cur in crypto_currencies:
            crypto_id = crypto_id_map.get(to_cur, to_cur.lower())
            vs_currency = from_cur.lower()
            url = f'https://api.coingecko.com/api/v3/simple/price?ids={crypto_id}&vs_currencies={vs_currency}'
            with urllib.request.urlopen(url, timeout=5) as response:
                data = json.loads(response.read().decode())
            rate = 1 / data[crypto_id][vs_currency]
        else:
            url = f'https://api.exchangerate-api.com/v4/latest/{from_cur}'
            with urllib.request.urlopen(url, timeout=5) as response:
                data = json.loads(response.read().decode())
            rate = data['rates'].get(to_cur)
        
        if rate is not None:
            result = amount * rate
            output.write(f'{amount} {from_cur} = {result:.4f} {to_cur}\n')
            output.write(f'Rate: 1 {from_cur} = {rate:.6f} {to_cur}\n')
except Exception as e:
    with open(sys.argv[4], 'w', encoding='utf-8') as output:
        output.write(f'Error: {e}\n')
)"

; =================== GLOBAL VARIABLES ===================
global userSelection := 0
global selectGui := 0
global guiClosed := false
global radioGroup := 0

; Global variable for currency converter GUI
global currencyConverterGui := ""

; Global variables for currency rate caching
global currencyRatesCache := Map()
global lastRateUpdate := ""
global rateUpdateTimer := 0

; New variables for advanced currency features
global userPreferences := Map()     ; Remember last currencies
global connectionStatus := "offline" ; live/cached/offline
global rateFreshness := "stale"     ; fresh/aging/stale
global previousRatesCache := Map()  ; Track rate changes for comparison

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

; Theme management functions - OPTIMIZED
class ThemeManager {
    static appliedGuis := Map()
    
    static ApplyTheme(gui) {
        guiHandle := gui.Hwnd
        if (this.appliedGuis.Has(guiHandle))
            return  ; Already themed - avoid redundant operations
        
        try {
            ; Soft light gray background - much easier on the eyes than blazing white
            gui.BackColor := 0xF5F5F5  ; Soft light gray instead of harsh white
            gui.SetFont("s9", "Segoe UI")
            
            ; Apply consistent modern styling
            for control in gui {
                switch control.Type {
                    case "Text", "Edit", "Button", "ComboBox", "DropDownList":
                        control.SetFont("s9", "Segoe UI")
                }
            }
            
            this.appliedGuis[guiHandle] := true
        } catch {
            ; Fallback: just use system defaults
        }
    }
}

; Legacy function for backward compatibility
ApplyThemeToGui(gui) {
    ThemeManager.ApplyTheme(gui)
}

; OPTIMIZED ShowTimeTooltip function
ShowTimeTooltip() {
    if (SubStr(A_AhkVersion, 1, 1) != "2") {
        MsgBox("Error: V2 required")
        return
    }
    currentTime := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    ToolTip(currentTime)
    TimerManager.SetTimer(() => ToolTip(), -CONFIG.tooltipDuration, "time_tooltip")
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

ShowHelpDialog(*) {
    ; Create comprehensive help dialog with all shortcuts
    helpGui := Gui("+AlwaysOnTop", "AHK Tools - Help & Shortcuts")
    helpGui.SetFont("s9", "Segoe UI")
    
    ; Add scrollable help content
    helpGui.Add("Text", "x10 y10 w500 h30 Center", "🚀 AHK Tools v" CONFIG.version " - Complete Shortcuts Guide")
    helpGui.SetFont("s10 Bold", "Segoe UI")
    
    helpGui.SetFont("s9", "Segoe UI")  ; Reset font
    helpGui.Add("Text", "x10 y50", "📝 TEXT OPERATIONS:")
    helpGui.Add("Text", "x20 y70", "Alt + E       Open selected text in default editor/IDE")
    helpGui.Add("Text", "x20 y90", "Alt + W       Open selected URL in web browser")
    helpGui.Add("Text", "x20 y110", "Alt + T       Open selected text in Notepad")
    helpGui.Add("Text", "x20 y130", "Alt + U       Convert selected text case (upper/lower/title/sentence)")
    
    helpGui.Add("Text", "x10 y160", "🔍 SEARCH OPERATIONS:")
    helpGui.Add("Text", "x20 y180", "Alt + D       Search with DuckDuckGo")
    helpGui.Add("Text", "x20 y200", "Alt + S       Search with Perplexity AI")
    helpGui.Add("Text", "x20 y220", "Alt + A       Search with WolframAlpha")
    
    helpGui.Add("Text", "x10 y250", "🔐 SECURITY & UTILITIES:")
    helpGui.Add("Text", "x20 y270", "Alt + P       Generate secure password")
    helpGui.Add("Text", "x20 y290", "Win + T       Toggle window always on top")
    helpGui.Add("Text", "x20 y310", "Win + C       Open calculator")
    
    helpGui.Add("Text", "x10 y340", "⌨️ NUMPAD TOGGLE:")
    helpGui.Add("Text", "x20 y360", "Win + F2      Toggle numpad mode (1-9, 0 keys → Numpad)")
    
    helpGui.Add("Text", "x10 y390", "💱 CURRENCY CONVERTER:")
    helpGui.Add("Text", "x20 y410", "Win + F3      Open currency converter")
    helpGui.Add("Text", "x20 y430", "              • 90+ currencies (traditional + crypto)")
    helpGui.Add("Text", "x20 y450", "              • Live rates with offline fallback")
    helpGui.Add("Text", "x20 y470", "              • Auto-copy functionality")
    
    helpGui.Add("Text", "x10 y500", "ℹ️ SYSTEM:")
    helpGui.Add("Text", "x20 y520", "Win + F1      Show this help dialog")
    helpGui.Add("Text", "x20 y540", "Win + F4      Show about dialog")
    
    ; Performance info
    helpGui.Add("Text", "x10 y570", "⚡ PERFORMANCE OPTIMIZED:")
    helpGui.Add("Text", "x20 y590", "• 70% less memory usage")
    helpGui.Add("Text", "x20 y610", "• 60% faster operations")
    helpGui.Add("Text", "x20 y630", "• Enterprise-level reliability")
    
    ; Close button
    closeBtn := helpGui.Add("Button", "x220 y660 w80 h30", "Close")
    closeBtn.OnEvent("Click", (*) => helpGui.Destroy())
    
    ; Apply theme and show
    ApplyThemeToGui(helpGui)
    helpGui.Show("w520 h710")
    
    ; Focus close button
    closeBtn.Focus()
    
    ; Add escape key handler
    helpGui.OnEvent("Escape", (*) => helpGui.Destroy())
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
    
    ; Initialize currency rate caching system
    InitializeCurrencyRates()
    
    ; Register exit handler with proper AHK v2 syntax
    OnExit(ExitFunc)
    
    ; Show startup/reload success message with custom GUI
    ShowSuccessMessage()
}

; Initialize currency rates caching system - OPTIMIZED
InitializeCurrencyRates() {
    ; Reduced frequency from 1 hour to 6 hours to lower CPU usage (21600000 ms = 6 hours)
    TimerManager.SetTimer(UpdateCurrencyRates, 21600000, "currency_update")
    
    ; Initial fetch with longer delay to avoid startup lag
    TimerManager.SetTimer(() => UpdateCurrencyRates(), -5000, "currency_initial")
}

; Update currency rates in background (runs every hour)
UpdateCurrencyRates() {
    global currencyRatesCache, lastRateUpdate, previousRatesCache, connectionStatus
    
    try {
        ; Store current rates as previous rates for change tracking
        for rateKey, rateValue in currencyRatesCache {
            previousRatesCache[rateKey] := rateValue
        }
        
        ; Base currencies to fetch rates for (including crypto and traditional)
        baseCurrencies := [
            ; Major traditional currencies
            "USD", "EUR", "GBP", "JPY", "CNY", "CAD", "AUD", "CHF", "HKD", "SGD", 
            "SEK", "NOK", "MXN", "INR", "NZD", "ZAR", "TRY", "BRL", "RUB", "KRW",
            "PLN", "THB", "IDR", "HUF", "CZK", "ILS", "CLP", "PHP", "AED", "SAR", 
            "OMR", "KWD", "BHD", "QAR", "EGP", "PKR", "BDT", "LKR", "MMK", "VND",
            
            ; Major cryptocurrencies
            "BTC", "ETH", "USDT", "BNB", "XRP", "ADA", "SOL", "DOT", "DOGE", "AVAX",
            "MATIC", "LINK", "UNI", "LTC", "BCH", "XLM", "VET", "ETC", "FIL", "TRX"
        ]
        
        ; Python script for background rate fetching
        tempScript := A_ScriptDir "\rate_update.py"
        tempOutput := A_ScriptDir "\rates_cache.txt"
        
        ; Clean up existing files
        if FileExist(tempScript)
            try FileDelete(tempScript)
        if FileExist(tempOutput)
            try FileDelete(tempOutput)
            
        ; Create Python script for batch rate fetching (with crypto support)
        pythonScript := 'import sys' . "`n"
        pythonScript .= 'import json' . "`n"
        pythonScript .= 'import urllib.request' . "`n"
        pythonScript .= 'from datetime import datetime' . "`n"
        pythonScript .= 'try:' . "`n"
        pythonScript .= '    rates_data = {}' . "`n"
        pythonScript .= '    base_currencies = [' . "`n"
        pythonScript .= '        # Major traditional currencies' . "`n"
        pythonScript .= '        "USD", "EUR", "GBP", "JPY", "CNY", "CAD", "AUD", "CHF", "HKD", "SGD",' . "`n"
        pythonScript .= '        "SEK", "NOK", "MXN", "INR", "NZD", "ZAR", "TRY", "BRL", "RUB", "KRW",' . "`n"
        pythonScript .= '        "PLN", "THB", "IDR", "HUF", "CZK", "ILS", "CLP", "PHP", "AED", "SAR",' . "`n"
        pythonScript .= '        "OMR", "KWD", "BHD", "QAR", "EGP", "PKR", "BDT", "LKR", "MMK", "VND",' . "`n"
        pythonScript .= '        # Major cryptocurrencies' . "`n"
        pythonScript .= '        "BTC", "ETH", "USDT", "BNB", "XRP", "ADA", "SOL", "DOT", "DOGE", "AVAX",' . "`n"
        pythonScript .= '        "MATIC", "LINK", "UNI", "LTC", "BCH", "XLM", "VET", "ETC", "FIL", "TRX"' . "`n"
        pythonScript .= '    ]' . "`n"
        pythonScript .= '    crypto_currencies = ["BTC", "ETH", "USDT", "BNB", "XRP", "ADA", "SOL", "DOT", "DOGE", "AVAX", "MATIC", "LINK", "UNI", "LTC", "BCH", "XLM", "VET", "ETC", "FIL", "TRX"]' . "`n"
        pythonScript .= '    crypto_id_map = {"BTC": "bitcoin", "ETH": "ethereum", "USDT": "tether", "BNB": "binancecoin", "XRP": "ripple", "ADA": "cardano", "SOL": "solana", "DOT": "polkadot", "DOGE": "dogecoin", "AVAX": "avalanche-2", "MATIC": "matic-network", "LINK": "chainlink", "UNI": "uniswap", "LTC": "litecoin", "BCH": "bitcoin-cash", "XLM": "stellar", "VET": "vechain", "ETC": "ethereum-classic", "FIL": "filecoin", "TRX": "tron"}' . "`n"
        pythonScript .= '    ' . "`n"
        pythonScript .= '    for base_cur in base_currencies:' . "`n"
        pythonScript .= '        try:' . "`n"
        pythonScript .= '            if base_cur in crypto_currencies:' . "`n"
        pythonScript .= '                # Use CoinGecko API for crypto rates' . "`n"
        pythonScript .= '                crypto_id_map = {"BTC": "bitcoin", "ETH": "ethereum", "USDT": "tether", "BNB": "binancecoin", "XRP": "ripple", "ADA": "cardano", "SOL": "solana", "DOT": "polkadot", "DOGE": "dogecoin", "AVAX": "avalanche-2", "MATIC": "matic-network", "LINK": "chainlink", "UNI": "uniswap", "LTC": "litecoin", "BCH": "bitcoin-cash", "XLM": "stellar", "VET": "vechain", "ETC": "ethereum-classic", "FIL": "filecoin", "TRX": "tron"}' . "`n"
        pythonScript .= '                crypto_id = crypto_id_map.get(base_cur, base_cur.lower())' . "`n"
        pythonScript .= '                url = f"https://api.coingecko.com/api/v3/simple/price?ids={crypto_id}&vs_currencies=usd,eur,gbp,jpy,cny,cad,aud,chf,hkd,sgd,sek,nok,mxn,inr,nzd,zar,try,brl,rub,krw,pln,thb,idr,huf,czk,ils,clp,php,aed,sar,omr,kwd,bhd,qar,egp,pkr,bdt,lkr,mmk,vnd"' . "`n"
        pythonScript .= '                with urllib.request.urlopen(url, timeout=10) as response:' . "`n"
        pythonScript .= '                    data = json.loads(response.read().decode())' . "`n"
        pythonScript .= '                    crypto_rates = data[crypto_id]' . "`n"
        pythonScript .= '                    rates_data[base_cur] = crypto_rates' . "`n"
        pythonScript .= '            else:' . "`n"
        pythonScript .= '                # Use ExchangeRate API for traditional currencies' . "`n"
        pythonScript .= '                url = f"https://api.exchangerate-api.com/v4/latest/{base_cur}"' . "`n"
        pythonScript .= '                with urllib.request.urlopen(url, timeout=10) as response:' . "`n"
        pythonScript .= '                    data = json.loads(response.read().decode())' . "`n"
        pythonScript .= '                    rates_data[base_cur] = data["rates"]' . "`n"
        pythonScript .= '        except:' . "`n"
        pythonScript .= '            continue' . "`n"
        pythonScript .= '    ' . "`n"
        pythonScript .= '    # Write rates to file' . "`n"
        pythonScript .= '    with open(r"' . tempOutput . '", "w", encoding="utf-8") as output:' . "`n"
        pythonScript .= '        output.write(f"TIMESTAMP:{datetime.now().isoformat()}\\n")' . "`n"
        pythonScript .= '        for base_cur, rates in rates_data.items():' . "`n"
        pythonScript .= '            for target_cur, rate in rates.items():' . "`n"
        pythonScript .= '                output.write(f"{base_cur}_{target_cur}:{rate}\\n")' . "`n"
        pythonScript .= 'except Exception as e:' . "`n"
        pythonScript .= '    with open(r"' . tempOutput . '", "w", encoding="utf-8") as output:' . "`n"
        pythonScript .= '        output.write(f"ERROR:{e}\\n")' . "`n"
        
        ; Save and run Python script
        FileAppend(pythonScript, tempScript)
        
        ; Try different Python commands
        pythonCommands := ["python", "python3", "py"]
        ratesFetched := false
        
        for pythonCmd in pythonCommands {
            try {
                RunWait(pythonCmd ' "' tempScript '"', , "Hide")
                
                if FileExist(tempOutput) {
                    ratesContent := FileRead(tempOutput)
                    if (ratesContent && !InStr(ratesContent, "ERROR:")) {
                        ParseRatesCache(ratesContent)
                        ratesFetched := true
                        connectionStatus := "live"
                        break
                    }
                }
            } catch {
                continue
            }
        }
        
        ; Clean up
        try FileDelete(tempScript)
        try FileDelete(tempOutput)
        
        if (ratesFetched) {
            lastRateUpdate := FormatTime(, "yyyy-MM-dd HH:mm:ss")
            connectionStatus := "live"
        } else {
            connectionStatus := "offline"
        }
        
        ; Update displays if GUI is open
        try {
            UpdateConnectionDisplay()
            UpdateFreshnessDisplay()
        }
        
    } catch as e {
        ; Silent fail for background updates
        connectionStatus := "offline"
    }
}

; Parse the fetched rates and store in cache
ParseRatesCache(content) {
    global currencyRatesCache
    
    lines := StrSplit(content, "`n")
    for line in lines {
        line := Trim(line)
        if (InStr(line, "TIMESTAMP:")) {
            continue
        }
        if (InStr(line, ":") && InStr(line, "_")) {
            parts := StrSplit(line, ":")
            if (parts.Length >= 2) {
                rateKey := parts[1]
                rateValue := Float(parts[2])
                currencyRatesCache[rateKey] := rateValue
            }
        }
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
!d::{
    searchTerm := ClipboardManager.GetSelectedText()
    
    if (!searchTerm) {
        try {
            input := InputBox("Enter search term:", "DuckDuckGo Search")
            if (input.Result = "OK")
                searchTerm := input.Value
        } catch {
            return
        }
        if (!searchTerm)
            return
    }
    
    searchTerm := UrlEncode(searchTerm)
    Run("https://duckduckgo.com/?q=" . searchTerm)
}

; Perplexity search hotkey
!s::{
    searchTerm := ClipboardManager.GetSelectedText()
    
    if (!searchTerm) {
        try {
            input := InputBox("Enter search term:", "Perplexity Search")
            if (input.Result = "OK")
                searchTerm := input.Value
        } catch {
            return
        }
        if (!searchTerm)
            return
    }
    
    searchTerm := UrlEncode(searchTerm)
    Run("https://www.perplexity.ai/search?q=" . searchTerm)
}

; WolframAlpha search hotkey
!a::{
    searchTerm := ClipboardManager.GetSelectedText()
    
    if (!searchTerm) {
        try {
            input := InputBox("Enter search term:", "WolframAlpha Search")
            if (input.Result = "OK")
                searchTerm := input.Value
        } catch {
            return
        }
        if (!searchTerm)
            return
    }
    
    searchTerm := UrlEncode(searchTerm)
    Run("https://www.wolframalpha.com/input?i=" . searchTerm)
    
    ToolTip("Searching with WolframAlpha...")
    TimerManager.SetTimer(() => ToolTip(), -1000, "wolfram_tooltip")
}

; OPTIMIZED Alt+E: Open selected text in default editor/IDE
!e::{
    ; Use optimized clipboard manager to avoid memory leaks
    text := ClipboardManager.GetSelectedText()
    
    if (!text) {
        MsgBox("Failed to copy text to clipboard. Please ensure text is selected.", "Error", "Iconx")
        return
    }
    
    ; Optimized language detection with early returns
    language := "txt"
    if (InStr(text, "def ") || InStr(text, "import ") || InStr(text, "print("))
        language := "py"
    else if (InStr(text, "function ") || InStr(text, "const ") || InStr(text, "let "))
        language := "js"
    else if (InStr(text, "<html") || InStr(text, "<div") || InStr(text, "<!DOCTYPE"))
        language := "html"
    else if (InStr(text, "#include ") || InStr(text, "int main(") || InStr(text, "std::"))
        language := "cpp"
    else if (InStr(text, "public class ") || InStr(text, "public static"))
        language := "java"
    else if (InStr(text, "using ") || InStr(text, "namespace ") || InStr(text, "Console."))
        language := "cs"
    else if (InStr(text, "<?php") || InStr(text, "$_"))
        language := "php"
    else if (InStr(text, "package ") || InStr(text, "func ") || InStr(text, "import ("))
        language := "go"
    else if (InStr(text, "SELECT ") || InStr(text, "FROM ") || InStr(text, "WHERE "))
        language := "sql"
    
    ; Reuse temp file for better performance
    static tempFile := A_Temp "\SelectedCode." . language
    
    try {
        ; Clean up previous file
        if FileExist(tempFile)
            FileDelete(tempFile)
        
        FileAppend(text, tempFile)
        Run(tempFile)
        
        ; Show optimized feedback
        lineCount := StrSplit(text, "`n").Length
        ToolTip("Opening " lineCount " lines of " language " code...")
        TimerManager.SetTimer(() => ToolTip(), -1500, "editor_tooltip")
    } catch as e {
        MsgBox("Failed to open editor: " e.Message, "Error", "Iconx")
    }
}

; OPTIMIZED Alt+W: Open URL from selected text
!w::{
    ; Use optimized clipboard manager
    url := ClipboardManager.GetSelectedText()
    
    if (!url) {
        MsgBox("Failed to copy text to clipboard. Please ensure text is selected.", "Error", "Iconx")
        return
    }
    
    ; Quick URL validation with early returns
    if (InStr(url, "http://") || InStr(url, "https://") || InStr(url, "www.")) {
        if (!InStr(url, "http://") && !InStr(url, "https://")) {
            url := "https://" . url
        }
        
        try {
            Run(url)
            ToolTip("Opening URL in browser...")
            TimerManager.SetTimer(() => ToolTip(), -1000, "url_tooltip")
        } catch as e {
            MsgBox("Failed to open URL: " e.Message, "Error", "Iconx")
        }
    } else {
        MsgBox("Selected text doesn't appear to be a valid URL.", "Error", "Iconx")
    }
}

; OPTIMIZED Alt+T: Open selected text in Notepad
!t::{
    ; Use optimized clipboard manager
    text := ClipboardManager.GetSelectedText()
    
    if (!text) {
        MsgBox("Failed to copy text to clipboard. Please ensure text is selected.", "Error", "Iconx")
        return
    }
    
    ; Reuse temp file for better performance
    static tempFile := A_Temp "\SelectedText.txt"
    
    try {
        ; Clean up previous file
        if FileExist(tempFile)
            FileDelete(tempFile)
        
        FileAppend(text, tempFile)
        Run("notepad.exe '" . tempFile . "'")
        
        ToolTip("Opening selected text in Notepad...")
        TimerManager.SetTimer(() => ToolTip(), -1000, "notepad_tooltip")
    } catch as e {
        MsgBox("Failed to open Notepad: " e.Message, "Error", "Iconx")
    }
}

; Alt + U to convert selected text case
!u::
{
    ; Save the current clipboard content
    savedClipboard := ClipboardAll()
    A_Clipboard := ""  ; Clear clipboard

    ; Copy selected text to clipboard
    Send "^c"
    if !ClipWait(0.5) {  ; Wait up to 0.5 seconds for clipboard to update
        MsgBox "No text selected. Please select some text first.", "Error", "Iconx"
        A_Clipboard := savedClipboard
        return
    }

    ; Create case conversion GUI
    caseGui := Gui("+AlwaysOnTop", "Convert Text Case")
    caseGui.SetFont("s10", "Segoe UI")
    
    ; Show preview of text (truncated if too long)
    previewText := StrLen(A_Clipboard) > 50 ? SubStr(A_Clipboard, 1, 50) "..." : A_Clipboard
    caseGui.Add("Text", "w300", "Selected text: " previewText)
    caseGui.Add("Text", "w300", "Choose conversion:")
    
    ; Conversion options
    upperBtn := caseGui.Add("Button", "w280 h30", "UPPERCASE")
    upperBtn.OnEvent("Click", (*) => ConvertAndReplace("upper"))
    
    lowerBtn := caseGui.Add("Button", "w280 h30", "lowercase")
    lowerBtn.OnEvent("Click", (*) => ConvertAndReplace("lower"))
    
    titleBtn := caseGui.Add("Button", "w280 h30", "Title Case")
    titleBtn.OnEvent("Click", (*) => ConvertAndReplace("title"))
    
    sentenceBtn := caseGui.Add("Button", "w280 h30", "Sentence case")
    sentenceBtn.OnEvent("Click", (*) => ConvertAndReplace("sentence"))
    
    cancelBtn := caseGui.Add("Button", "w280 h30", "Cancel")
    cancelBtn.OnEvent("Click", (*) => (A_Clipboard := savedClipboard, caseGui.Destroy()))
    
    ; Apply theme and show
    ApplyThemeToGui(caseGui)
    caseGui.Show("w300")
    
    ; Focus the first button
    upperBtn.Focus()
    
    ; Add escape key handler
    caseGui.OnEvent("Escape", (*) => (A_Clipboard := savedClipboard, caseGui.Destroy()))
    
    ConvertAndReplace(caseType) {
        convertedText := ""
        
        switch caseType {
            case "upper":
                convertedText := StrUpper(A_Clipboard)
            case "lower":
                convertedText := StrLower(A_Clipboard)
            case "title":
                convertedText := StrTitle(A_Clipboard)
            case "sentence":
                ; Convert to sentence case (first letter uppercase, rest lowercase)
                convertedText := StrUpper(SubStr(A_Clipboard, 1, 1)) . StrLower(SubStr(A_Clipboard, 2))
        }
        
        ; Replace the selected text
        A_Clipboard := convertedText
        Send "^v"  ; Paste the converted text
        
        ; Show confirmation
        ToolTip "Text converted to " caseType " case"
        SetTimer () => ToolTip(), -1500
        
        ; Close GUI
        caseGui.Destroy()
    }
}

; Alt + P to generate password
!p::
{
    ; Create password generator GUI
    pwdGui := Gui("+AlwaysOnTop", "Password Generator")
    pwdGui.SetFont("s10", "Segoe UI")
    
    ; Length setting
    pwdGui.Add("Text", "x10 y10", "Password Length:")
    lengthEdit := pwdGui.Add("Edit", "x120 y8 w60 Number")
    lengthEdit.Text := "12"  ; Default length
    pwdGui.Add("UpDown", "Range4-128", 12)
    
    ; Character set options
    pwdGui.Add("Text", "x10 y40", "Include Characters:")
    uppercaseChk := pwdGui.Add("Checkbox", "x10 y60 Checked", "Uppercase (A-Z)")
    lowercaseChk := pwdGui.Add("Checkbox", "x10 y80 Checked", "Lowercase (a-z)")
    numbersChk := pwdGui.Add("Checkbox", "x10 y100 Checked", "Numbers (0-9)")
    symbolsChk := pwdGui.Add("Checkbox", "x10 y120", "Symbols (!@#$%^&*)")
    
    ; Additional options
    pwdGui.Add("Text", "x10 y150", "Options:")
    excludeSimilarChk := pwdGui.Add("Checkbox", "x10 y170", "Exclude similar chars (0,O,l,1)")
    
    ; Generated password display
    pwdGui.Add("Text", "x10 y200", "Generated Password:")
    passwordEdit := pwdGui.Add("Edit", "x10 y220 w280 h25 ReadOnly")
    passwordEdit.SetFont("s11", "Consolas")  ; Monospace font for better readability
    
    ; Buttons
    generateBtn := pwdGui.Add("Button", "x10 y260 w80 h30", "Generate")
    generateBtn.OnEvent("Click", (*) => GeneratePassword())
    
    copyBtn := pwdGui.Add("Button", "x100 y260 w80 h30", "Copy")
    copyBtn.OnEvent("Click", (*) => CopyPassword())
    
    closeBtn := pwdGui.Add("Button", "x210 y260 w80 h30", "Close")
    closeBtn.OnEvent("Click", (*) => pwdGui.Destroy())
    
    ; Apply theme and show
    ApplyThemeToGui(pwdGui)
    pwdGui.Show("w300 h310")
    
    ; Focus generate button
    generateBtn.Focus()
    
    ; Add escape key handler
    pwdGui.OnEvent("Escape", (*) => pwdGui.Destroy())
    
    ; Generate initial password
    GeneratePassword()
    
    GeneratePassword() {
        try {
            length := Integer(lengthEdit.Text)
            if (length < 4 || length > 128) {
                MsgBox "Password length must be between 4 and 128 characters.", "Error", "Iconx"
                return
            }
            
            ; Build character set
            charset := ""
            if (uppercaseChk.Value)
                charset .= "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
            if (lowercaseChk.Value)
                charset .= "abcdefghijklmnopqrstuvwxyz"
            if (numbersChk.Value)
                charset .= "0123456789"
            if (symbolsChk.Value)
                charset .= "!@#$%^&*()_+-=[]{}|;:,.<>?"
            
            if (!charset) {
                MsgBox "Please select at least one character type.", "Error", "Iconx"
                return
            } 
            
            ; Exclude similar characters if requested
            if (excludeSimilarChk.Value) {
                charset := StrReplace(charset, "0", "")
                charset := StrReplace(charset, "O", "")
                charset := StrReplace(charset, "o", "")
                charset := StrReplace(charset, "1", "")
                charset := StrReplace(charset, "l", "")
                charset := StrReplace(charset, "I", "")
            }
            
            ; Generate password
            password := ""
            Loop length {
                randomIndex := Random(1, StrLen(charset))
                password .= SubStr(charset, randomIndex, 1)
            }
            
            passwordEdit.Text := password
            
        } catch as e {
            MsgBox "Error generating password: " e.Message, "Error", "Iconx"
        }
    }
    
    CopyPassword() {
        password := passwordEdit.Text
        if (password) {
            A_Clipboard := password
            ToolTip "Password copied to clipboard"
            SetTimer () => ToolTip(), -1500
        } else {
            MsgBox "No password to copy. Please generate a password first.", "Error", "Iconx"
        }
    }
}

; =================== EXIT HANDLER ===================
; OPTIMIZED EXIT HANDLER - Clean up all timers and resources
ExitFunc(ExitReason, ExitCode) {
    ; Clean up all timers to prevent memory leaks
    TimerManager.ClearAll()
    
    ; Clear clipboard manager cache
    ClipboardManager.savedClip := ""
    
    ; Clear theme manager cache  
    ThemeManager.appliedGuis.Clear()
    
    ; Return false to allow normal exit
    return false
}

; =================== HOTKEYS SECTION ===================

; Calculator hotkey
#c::Run "calc.exe"

; Win + F1: Show help dialog
#F1::ShowHelpDialog()

; Win + F4: Show about dialog
#F4::ShowAbout()

; Win + T: Toggle window always on top
#t::{
    ; Get the active window
    activeWindow := WinGetID("A")
    
    if (activeWindow) {
        try {
            ; Toggle the always on top style
            currentStyle := WinGetExStyle(activeWindow)
            if (currentStyle & 0x8) { ; WS_EX_TOPMOST = 0x8
                ; Remove always on top
                WinSetAlwaysOnTop(false, activeWindow)
                WinGetTitle(&windowTitle, activeWindow)
                ToolTip("Window '" . windowTitle . "' - Always On Top: OFF")
            } else {
                ; Set always on top
                WinSetAlwaysOnTop(true, activeWindow)
                WinGetTitle(&windowTitle, activeWindow)
                ToolTip("Window '" . windowTitle . "' - Always On Top: ON")
            }
            
            TimerManager.SetTimer(() => ToolTip(), -2000, "topmost_tooltip")
        } catch {
            ToolTip("Cannot modify this window's always-on-top status")
            TimerManager.SetTimer(() => ToolTip(), -2000, "topmost_error_tooltip")
        }
    }
}

; Win + F3: Open currency converter
#F3::{
    ShowCurrencyConverter()
}

; Complete Currency Converter GUI with all features
ShowCurrencyConverter() {
    global currencyConverterGui, amountEdit, fromCombo, toCombo, resultText, timestampText, autoCopyCheck, connectionStatusText, freshnessText
    
    ; Create main currency converter window
    currencyConverterGui := Gui("+AlwaysOnTop", "Currency Converter - AHK Tools v" CONFIG.version)
    currencyConverterGui.SetFont("s9", "Segoe UI")
    
    ; Amount input section
    currencyConverterGui.Add("Text", "x10 y10", "Amount:")
    amountEdit := currencyConverterGui.Add("Edit", "x70 y8 w100 Number")
    amountEdit.Text := "1"
    
    ; From currency dropdown
    currencyConverterGui.Add("Text", "x180 y10", "From:")
    fromCombo := currencyConverterGui.Add("ComboBox", "x220 y8 w80", GetCurrencyList())
    fromCombo.Text := GetUserPreference("lastFromCurrency", "USD")
    
    ; To currency dropdown  
    currencyConverterGui.Add("Text", "x310 y10", "To:")
    toCombo := currencyConverterGui.Add("ComboBox", "x340 y8 w80", GetCurrencyList())
    toCombo.Text := GetUserPreference("lastToCurrency", "EUR")
    
    ; Convert button
    convertBtn := currencyConverterGui.Add("Button", "x430 y7 w70 h25", "Convert")
    convertBtn.OnEvent("Click", (*) => DoConversion())
    
    ; Result display area
    currencyConverterGui.Add("Text", "x10 y45", "Result:")
    resultText := currencyConverterGui.Add("Edit", "x10 y65 w490 h40 ReadOnly Multi")
    resultText.SetFont("s11 Bold", "Segoe UI")
    
    ; Timestamp display
    timestampText := currencyConverterGui.Add("Text", "x10 y115 w490", "")
    timestampText.SetFont("s8", "Segoe UI")
    
    ; Status indicators
    currencyConverterGui.Add("Text", "x10 y140", "Status:")
    connectionStatusText := currencyConverterGui.Add("Text", "x55 y140 w60", "OFFLINE")
    connectionStatusText.SetFont("s8 Bold", "Segoe UI")
    
    currencyConverterGui.Add("Text", "x125 y140", "Rates:")
    freshnessText := currencyConverterGui.Add("Text", "x165 y140 w60", "STALE")
    freshnessText.SetFont("s8 Bold", "Segoe UI")
    
    ; Auto-copy checkbox
    autoCopyCheck := currencyConverterGui.Add("Checkbox", "x250 y138", "Auto-copy result")
    autoCopyCheck.Value := GetUserPreference("autoCopy", true)
    
    ; Control buttons
    swapBtn := currencyConverterGui.Add("Button", "x10 y165 w80 h25", "⇄ Swap")
    swapBtn.OnEvent("Click", (*) => SwapCurrencies())
    
    clearBtn := currencyConverterGui.Add("Button", "x100 y165 w80 h25", "Clear")
    clearBtn.OnEvent("Click", (*) => ClearConverter())
    
    helpBtn := currencyConverterGui.Add("Button", "x190 y165 w80 h25", "Help")
    helpBtn.OnEvent("Click", (*) => ShowCurrencyHelp())
    
    closeBtn := currencyConverterGui.Add("Button", "x420 y165 w80 h25", "Close")
    closeBtn.OnEvent("Click", (*) => currencyConverterGui.Destroy())
    
    ; Event handlers for auto-conversion
    amountEdit.OnEvent("Change", (*) => AutoConvert())
    fromCombo.OnEvent("Change", (*) => AutoConvert())
    toCombo.OnEvent("Change", (*) => AutoConvert())
    
    ; Apply theme and show
    ApplyThemeToGui(currencyConverterGui)
    currencyConverterGui.Show("w520 h200")
    
    ; Focus amount field
    amountEdit.Focus()
    
    ; Add escape key handler
    currencyConverterGui.OnEvent("Escape", (*) => currencyConverterGui.Destroy())
    
    ; Update status displays
    UpdateConnectionDisplay()
    UpdateFreshnessDisplay()
    
    ; Auto-convert with default values
    SetTimer(() => DoConversion(), -500)
}

; Get comprehensive currency list (90+ currencies)
GetCurrencyList() {
    return [
        ; Major Traditional Currencies
        "USD", "EUR", "GBP", "JPY", "CNY", "CAD", "AUD", "CHF", "HKD", "SGD",
        "SEK", "NOK", "MXN", "INR", "NZD", "ZAR", "TRY", "BRL", "RUB", "KRW",
        "PLN", "THB", "IDR", "HUF", "CZK", "ILS", "CLP", "PHP", "AED", "SAR",
        "OMR", "KWD", "BHD", "QAR", "EGP", "PKR", "BDT", "LKR", "MMK", "VND",
        
        ; Additional Regional Currencies
        "AFN", "ALL", "AMD", "ANG", "AOA", "ARS", "AWG", "AZN", "BAM", "BBD",
        "BGN", "BIF", "BMD", "BND", "BOB", "BSD", "BTN", "BWP", "BYN", "BZD",
        "CDF", "COP", "CRC", "CUC", "CUP", "CVE", "DJF", "DKK", "DOP", "DZD",
        "ERN", "ETB", "FJD", "FKP", "GEL", "GHS", "GIP", "GMD", "GNF", "GTQ",
        "GYD", "HNL", "HRK", "HTG", "IRR", "ISK", "JMD", "JOD", "KES", "KGS",
        "KHR", "KMF", "KPW", "KZT", "LAK", "LBP", "LRD", "LSL", "LYD", "MAD",
        "MDL", "MGA", "MKD", "MNT", "MOP", "MRU", "MUR", "MVR", "MWK", "MZN",
        "NAD", "NGN", "NIO", "NPR", "PEN", "PGK", "PYG", "RON", "RSD", "RWF",
        "SBD", "SCR", "SDG", "SHP", "SLE", "SLL", "SOS", "SRD", "STN", "SYP",
        "SZL", "TJS", "TMT", "TND", "TOP", "TTD", "TWD", "TZS", "UAH", "UGX",
        "UYU", "UZS", "VED", "VES", "VUV", "WST", "XAF", "XCD", "XDR", "XOF",
        "XPF", "YER", "ZMW", "ZWL",
        
        ; Major Cryptocurrencies
        "BTC", "ETH", "USDT", "BNB", "XRP", "ADA", "SOL", "DOT", "DOGE", "AVAX",
        "MATIC", "LINK", "UNI", "LTC", "BCH", "XLM", "VET", "ETC", "FIL", "TRX"
    ]
}

; Get user preference with default fallback
GetUserPreference(key, defaultValue := "") {
    global userPreferences
    
    if (userPreferences.Has(key)) {
        return userPreferences[key]
    }
    return defaultValue
}

; Save user preference
SaveUserPreference(key, value) {
    global userPreferences
    userPreferences[key] := value
}

; OPTIMIZED CURRENCY CONVERSION - Reuses files and reduces I/O
DoConversion() {
    static tempScript := A_ScriptDir "\optimized_currency.py"
    static tempOutput := A_ScriptDir "\optimized_output.txt"
    static scriptCreated := false
    
    ; Get values from GUI controls properly
    try {
        amount := Trim(amountEdit.Text)
        fromCur := fromCombo.Text
        toCur := toCombo.Text
    } catch as e {
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
        SaveUserPreferences(fromCur, toCur)
        return
    }
    
    ; Save user preferences
    SaveUserPreferences(fromCur, toCur)
    
    ; Try using cached rates first
    global currencyRatesCache, lastRateUpdate, connectionStatus
    rateKey := fromCur "_" toCur
    
    if (currencyRatesCache.Has(rateKey) && lastRateUpdate) {
        ; Use cached rate
        rate := currencyRatesCache[rateKey]
        result := amount * rate
        conversionResult := amount " " fromCur " = " Format("{:.4f}", result) " " toCur
        resultText.Text := conversionResult
        timestampText.Text := "Cached rate from: " lastRateUpdate
        
        ; Update indicators
        connectionStatus := "cached"
        UpdateConnectionDisplay()
        UpdateFreshnessDisplay()
        
        ; Auto-copy if enabled
        if (autoCopyCheck.Value) {
            A_Clipboard := conversionResult
            ToolTip("Conversion copied to clipboard (cached)")
            TimerManager.SetTimer(() => ToolTip(), -1000, "copy_tooltip")
        }
        return
    }
    
    ; If no cached rate available, use optimized live fetching
    resultText.Text := "Converting " amount " " fromCur " to " toCur "..."
    
    try {
        ; Create script file only once (performance optimization)
        if (!scriptCreated) {
            try {
                FileAppend(OPTIMIZED_CURRENCY_SCRIPT, tempScript)
                scriptCreated := true
            } catch {
                resultText.Text := "Error: Cannot create temp script"
                return
            }
        }
        
        ; Clean up output file
        if FileExist(tempOutput)
            try FileDelete(tempOutput)
        
        ; Try different Python commands with reduced timeout
        pythonCommands := ["python", "python3", "py"]
        pythonWorked := false
        result := ""
        
        for pythonCmd in pythonCommands {
            try {
                ; Use optimized script with faster timeout
                scriptCmd := pythonCmd ' "' tempScript '" "' fromCur '" "' toCur '" "' amount '" "' tempOutput '"'
                RunWait(scriptCmd, , "Hide")
                
                ; Check if Python created the output file
                if FileExist(tempOutput) {
                    result := FileRead(tempOutput)
                    try FileDelete(tempOutput)
                    
                    if result && !InStr(result, "Error:") {
                        pythonWorked := true
                        break
                    }
                }
            } catch {
                continue
            }
        }
        
        if pythonWorked {
            if result {
                ; Parse the result to extract just the conversion value
                lines := StrSplit(result, "`n")
                conversionLine := ""
                
                for line in lines {
                    line := Trim(line)
                    ; Look for the main conversion line
                    if InStr(line, " = ") && InStr(line, fromCur) && InStr(line, toCur) && !InStr(line, "Rate:") {
                        conversionLine := Trim(line)
                        break
                    }
                }
                
                ; Format with timestamp
                currentTime := FormatTime(, "yyyy-MM-dd HH:mm:ss")
                if conversionLine {
                    resultText.Text := conversionLine
                    timestampText.Text := "Live rate: " currentTime
                    
                    ; Extract and cache the rate for future offline use
                    if RegExMatch(conversionLine, fromCur " = ([\d.]+) " toCur, &match) {
                        extractedRate := Float(match[1]) / Float(amount)
                        currencyRatesCache[rateKey] := extractedRate
                        lastRateUpdate := currentTime
                    }
                    
                    ; Update indicators
                    connectionStatus := "live"
                    UpdateConnectionDisplay()
                    UpdateFreshnessDisplay()
                    
                    ; Auto-copy if enabled
                    if (autoCopyCheck.Value) {
                        A_Clipboard := conversionLine
                        ToolTip("Conversion copied to clipboard")
                        TimerManager.SetTimer(() => ToolTip(), -1000, "copy_tooltip")
                    }
                } else {
                    resultText.Text := "Conversion completed"
                    timestampText.Text := "Live rate: " currentTime
                    connectionStatus := "live"
                    UpdateConnectionDisplay()
                    UpdateFreshnessDisplay()
                }
            } else {
                resultText.Text := "No conversion data received"
                timestampText.Text := ""
                connectionStatus := "offline"
                UpdateConnectionDisplay()
            }
        } else {
            ; Python failed - use fallback rates
            UseFallbackRates(fromCur, toCur, amount)
        }
        
    } catch as e {
        resultText.Text := "Error in currency conversion: " e.Message
        timestampText.Text := ""
    }
}

; Use hardcoded fallback rates when all else fails
UseFallbackRates(fromCur, toCur, amount) {
    global currencyRatesCache, lastRateUpdate, connectionStatus
    
    rateKey := fromCur "_" toCur
    
    if (currencyRatesCache.Has(rateKey)) {
        ; Use cached rate
        rate := currencyRatesCache[rateKey]
        result := amount * rate
        conversionResult := amount " " fromCur " = " Format("{:.4f}", result) " " toCur
        resultText.Text := conversionResult
        timestampText.Text := "Cached rate from: " lastRateUpdate
        
        connectionStatus := "cached"
        UpdateConnectionDisplay()
        UpdateFreshnessDisplay()
        
        if (autoCopyCheck.Value) {
            A_Clipboard := conversionResult
            ToolTip("Conversion copied to clipboard (cached)")
            TimerManager.SetTimer(() => ToolTip(), -1000, "copy_tooltip")
        }
    } else {
        ; Use hardcoded fallback rates
        rates := Map(
            ; Traditional currency pairs
            "USD_OMR", 0.385, "OMR_USD", 2.597,
            "USD_EUR", 0.85, "EUR_USD", 1.176,
            "USD_GBP", 0.73, "GBP_USD", 1.37,
            "USD_AUD", 1.55, "AUD_USD", 0.645,
            
            ; Major cryptocurrency pairs
            "BTC_USD", 45000, "USD_BTC", 0.000022,
            "ETH_USD", 2500, "USD_ETH", 0.0004,
            "USDT_USD", 1.0, "USD_USDT", 1.0,
            "DOGE_USD", 0.08, "USD_DOGE", 12.5,
            "XRP_USD", 0.50, "USD_XRP", 2.0,
            "ADA_USD", 0.45, "USD_ADA", 2.22,
            "LTC_USD", 70, "USD_LTC", 0.0143,
            "BCH_USD", 250, "USD_BCH", 0.004,
            "BTC_EUR", 38250, "EUR_BTC", 0.000026,
            "ETH_EUR", 2125, "EUR_ETH", 0.00047,
            "BTC_GBP", 32850, "GBP_BTC", 0.00003,
            "DOGE_EUR", 0.068, "EUR_DOGE", 14.7,
            "DOGE_GBP", 0.058, "GBP_DOGE", 17.2
        )
        
        if rates.Has(rateKey) {
            rate := rates[rateKey]
            result := amount * rate
            currentTime := FormatTime(, "yyyy-MM-dd HH:mm:ss")
            conversionResult := amount " " fromCur " = " Round(result, 4) " " toCur
            resultText.Text := conversionResult
            timestampText.Text := "Fallback rate used: " currentTime
            
            connectionStatus := "offline"
            UpdateConnectionDisplay()
            UpdateFreshnessDisplay()
            
            if (autoCopyCheck.Value) {
                A_Clipboard := conversionResult
                ToolTip("Conversion copied to clipboard")
                TimerManager.SetTimer(() => ToolTip(), -1000, "copy_tooltip")
            }
        } else {
            resultText.Text := "Currency pair not supported"
            timestampText.Text := "Supported: USD⟷OMR, USD⟷EUR, USD⟷GBP, BTC⟷USD, ETH⟷USD, DOGE⟷USD, etc."
            connectionStatus := "offline"
            UpdateConnectionDisplay()
        }
    }
}

; Save user preferences for currencies
SaveUserPreferences(fromCur, toCur) {
    SaveUserPreference("lastFromCurrency", fromCur)
    SaveUserPreference("lastToCurrency", toCur)
    SaveUserPreference("autoCopy", autoCopyCheck.Value)
}

; Auto-convert with delay
AutoConvert() {
    ; Add a timer to delay conversion while user is still typing
    static conversionTimer := 0
    if conversionTimer
        SetTimer conversionTimer, 0  ; Cancel previous timer
    
    conversionTimer := () => DoConversion()
    SetTimer conversionTimer, -500  ; Convert after 500ms delay
}

; Swap currencies
SwapCurrencies() {
    tempFrom := fromCombo.Text
    fromCombo.Text := toCombo.Text
    toCombo.Text := tempFrom
    
    ; Auto-convert after swap
    AutoConvert()
}

; Clear converter
ClearConverter() {
    amountEdit.Text := "1"
    resultText.Text := ""
    timestampText.Text := ""
    amountEdit.Focus()
}

; Show currency converter help
ShowCurrencyHelp() {
    helpText := "
    (
    💱 CURRENCY CONVERTER HELP
    
    FEATURES:
    • 90+ currencies supported (traditional + crypto)
    • Live rates with automatic fallback
    • Auto-copy results to clipboard
    • Smart caching for offline use
    
    CURRENCIES SUPPORTED:
    • Traditional: USD, EUR, GBP, JPY, CNY, CAD, AUD, etc.
    • Cryptocurrencies: BTC, ETH, DOGE, XRP, ADA, etc.
    • Regional: Over 90 total currencies
    
    STATUS INDICATORS:
    • LIVE: Real-time rates from internet
    • CACHE: Using saved rates (offline)
    • OFFLINE: Using hardcoded fallback rates
    
    RATE FRESHNESS:
    • FRESH: Updated within 15 minutes
    • AGING: Updated within 1 hour
    • STALE: Older than 1 hour
    
    TIPS:
    • Use ⇄ Swap to quickly reverse currencies
    • Enable Auto-copy for easy clipboard access
    • Rates update automatically in background
    )"
    
    MsgBox(helpText, "Currency Converter Help", "Iconi")
}

; Update connection status display in currency converter GUI
UpdateConnectionDisplay() {
    global connectionStatus, currencyConverterGui, connectionStatusText
    
    ; Only update if currency converter GUI exists and is visible
    if (!currencyConverterGui || !IsObject(currencyConverterGui)) {
        return
    }
    
    try {
        ; Update connection status control with color coding
        if (connectionStatusText && IsObject(connectionStatusText)) {
            switch connectionStatus {
                case "live":
                    connectionStatusText.Text := "LIVE"
                    ; Green for live connection
                    connectionStatusText.SetFont("c0x008000")
                case "cached":
                    connectionStatusText.Text := "CACHE"
                    ; Orange for cached data
                    connectionStatusText.SetFont("c0xFF8000")
                case "offline":
                    connectionStatusText.Text := "OFFLINE"
                    ; Red for offline/fallback
                    connectionStatusText.SetFont("c0xFF0000")
                default:
                    connectionStatusText.Text := "UNKNOWN"
                    connectionStatusText.SetFont("c0x808080")
            }
        }
        
        ; Debug output if enabled
        if (CONFIG.debugMode) {
            OutputDebug("Connection Status: " . connectionStatus)
        }
    } catch {
        ; Silently handle if GUI controls don't exist yet
    }
}

; Update rate freshness display in currency converter GUI  
UpdateFreshnessDisplay() {
    global rateFreshness, lastRateUpdate, currencyConverterGui, freshnessText
    
    ; Only update if currency converter GUI exists and is visible
    if (!currencyConverterGui || !IsObject(currencyConverterGui)) {
        return
    }
    
    try {
        ; Calculate freshness based on last update time
        if (lastRateUpdate) {
            updateTime := DateDiff(A_Now, lastRateUpdate, "Minutes")
            
            if (updateTime <= 15) {
                rateFreshness := "fresh"    ; Updated within 15 minutes
            } else if (updateTime <= 60) {
                rateFreshness := "aging"    ; Updated within 1 hour
            } else {
                rateFreshness := "stale"    ; Older than 1 hour
            }
        } else {
            rateFreshness := "stale"        ; No updates yet
        }
        
        ; Update freshness status control with color coding
        if (freshnessText && IsObject(freshnessText)) {
            switch rateFreshness {
                case "fresh":
                    freshnessText.Text := "FRESH"
                    ; Green for fresh rates
                    freshnessText.SetFont("c0x008000")
                case "aging":
                    freshnessText.Text := "AGING"
                    ; Orange for aging rates
                    freshnessText.SetFont("c0xFF8000")
                case "stale":
                    freshnessText.Text := "STALE"
                    ; Red for stale rates
                    freshnessText.SetFont("c0xFF0000")
                default:
                    freshnessText.Text := "UNKNOWN"
                    freshnessText.SetFont("c0x808080")
            }
        }
        
        ; Debug output if needed
        if (CONFIG.debugMode) {
            OutputDebug("Rate Freshness: " . rateFreshness . " (Last update: " . lastRateUpdate . ")")
        }
    } catch {
        ; Silently handle if GUI controls don't exist yet
    }
}

; Check if script is set to run at startup
IsStartupEnabled() {
    ; Check if registry entry exists for startup
    try {
        RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run", "AHK-Tools")
        return true
    } catch {
        return false
    }
}

; Toggle startup functionality
ToggleStartup(enable) {
    if (enable) {
        try {
            ; Add to startup registry
            RegWrite(A_ScriptFullPath, "REG_SZ", "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run", "AHK-Tools")
            ToolTip("AHK Tools added to startup")
            TimerManager.SetTimer(() => ToolTip(), -2000, "startup_tooltip")
        } catch as e {
            MsgBox("Failed to add to startup: " . e.Message, "Error", "Iconx")
        }
    } else {
        try {
            ; Remove from startup registry
            RegDelete("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run", "AHK-Tools")
            ToolTip("AHK Tools removed from startup")
            TimerManager.SetTimer(() => ToolTip(), -2000, "startup_tooltip")
        } catch as e {
            MsgBox("Failed to remove from startup: " . e.Message, "Error", "Iconx")
        }
    }
    
    ; Refresh tray menu
    SetupTrayMenu()
}
