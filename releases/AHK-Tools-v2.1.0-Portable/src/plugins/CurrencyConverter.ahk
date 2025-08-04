; Currency Converter Plugin - Working Version
class CurrencyConverterPlugin extends Plugin {
    static Name := "Currency Converter"
    static Description := "Convert currencies with live exchange rates"
    static Version := "3.0.0"
    static Author := "AHK-Tools"
    
    gui := ""
    
    __New() {
        super.__New()
    }
    
    Initialize() {
        ; Register Alt+C hotkey directly - bypass main system to get text selection
        Hotkey "!c", this.HandleAltC.Bind(this)
        return true
    }
    
    Enable() {
        try {
            Hotkey "!c", "On"
            this.Enabled := true
        } catch as e {
            MsgBox("Error enabling Currency Converter: " e.Message)
            return false
        }
        return true
    }
    
    Disable() {
        try {
            Hotkey "!c", "Off"
            this.Enabled := false
        } catch as e {
            MsgBox("Error disabling Currency Converter: " e.Message)
            return false
        }
        return true
    }
    
    ; Method called by main system
    ShowCurrencyConverter() {
        this.ShowAltCConverter("", "")
    }
    
    ; Main Alt+C handler - copied exactly from working original script
    HandleAltC(*) {
        ; Try to get selected text first (exact copy from working script)
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
                "$", "USD", "€", "EUR", "£", "GBP", "¥", "JPY", "₹", "INR", "₩", "KRW", "¢", "USD",
                "₽", "RUB", "₨", "PKR", "﷼", "OMR", "₪", "ILS", "₦", "NGN", "₡", "CRC", "₵", "GHS",
                "₸", "KZT", "₴", "UAH", "₱", "PHP", "₲", "PYG", "₫", "VND", "₭", "LAK", "₯", "GRD",
                "₰", "PF", "₳", "ARA", "₼", "AZN", "₾", "GEL", "₿", "BTC", "＄", "USD", "￠", "USD",
                "￡", "GBP", "￥", "JPY", "￦", "KRW", "﹩", "USD", "＃", "USD", "R", "ZAR",
                "R$", "BRL", "kr", "SEK", "zł", "PLN", "₺", "TRY", "֏", "AMD", "₶", "LVL",
                "₷", "SPL", "₻", "CET"
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
                parsedCurrency := "USD"
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
        
        ; Show the currency converter GUI
        this.ShowAltCConverter(parsedAmount, parsedCurrency)
    }
    
    ; Show Currency Converter GUI
    ShowAltCConverter(parsedAmount := "", parsedCurrency := "") {
        ; Create GUI
        this.gui := Gui("+AlwaysOnTop", "Currency Converter")
        this.gui.SetFont("s10", "Segoe UI")
        
        ; Common currencies list
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
        this.gui.Add("Text", "x10 y10", "Amount:")
        this.amountEdit := this.gui.Add("Edit", "x10 y30 w150")
        this.amountEdit.OnEvent("Change", (*) => this.AutoConvert())
        
        ; Pre-fill amount if detected
        if parsedAmount
            this.amountEdit.Text := parsedAmount
        
        ; From currency dropdown
        this.gui.Add("Text", "x10 y65", "From Currency:")
        this.fromCombo := this.gui.Add("ComboBox", "x10 y85 w150", currencies)
        this.fromCombo.SetFont("s8", "Segoe UI")
        this.fromCombo.OnEvent("Change", (*) => this.AutoConvert())
        
        ; Set detected currency or default to USD
        if parsedCurrency && this.HasValueInCurrencies(currencies, parsedCurrency)
            this.fromCombo.Text := parsedCurrency
        else
            this.fromCombo.Text := "USD"
        
        ; To currency dropdown
        this.gui.Add("Text", "x10 y120", "To Currency:")
        this.toCombo := this.gui.Add("ComboBox", "x10 y140 w150", currencies)
        this.toCombo.SetFont("s8", "Segoe UI")
        this.toCombo.Text := "OMR"
        this.toCombo.OnEvent("Change", (*) => this.AutoConvert())
        
        ; Result display
        this.resultText := this.gui.Add("Edit", "x10 y175 w260 h25 ReadOnly")
        this.resultText.SetFont("s11 Bold", "Segoe UI")
        if parsedAmount && parsedCurrency
            this.resultText.Text := "Auto-detected: " parsedAmount " " parsedCurrency
        else if parsedAmount
            this.resultText.Text := "Auto-detected amount: " parsedAmount
        else
            this.resultText.Text := "Enter amount and select currencies"
        
        ; Copy button
        this.copyEmojiBtn := this.gui.Add("Button", "x275 y175 w35 h25", "📋")
        this.copyEmojiBtn.SetFont("s10", "Segoe UI")
        this.copyEmojiBtn.OnEvent("Click", (*) => this.CopyResultText())
        
        ; Timestamp display
        this.timestampText := this.gui.Add("Edit", "x10 y205 w300 h20 ReadOnly")
        this.timestampText.SetFont("s8", "Segoe UI")
        this.timestampText.Text := "for automatic conversion"
        
        ; Auto-copy checkbox
        this.autoCopyCheck := this.gui.Add("Checkbox", "x10 y235 w200", "Auto-copy to clipboard")
        this.autoCopyCheck.Value := 0
        
        ; Buttons
        closeBtn := this.gui.Add("Button", "x10 y265 w80 h30", "Close")
        closeBtn.OnEvent("Click", (*) => this.gui.Destroy())
        
        swapBtn := this.gui.Add("Button", "x100 y265 w80 h30", "Swap")
        swapBtn.OnEvent("Click", (*) => this.SwapCurrenciesInGUI())
        
        ; Event handlers
        this.gui.OnEvent("Escape", (*) => this.gui.Destroy())
        
        ; Show GUI
        this.gui.Show("w320 h310")
        this.amountEdit.Focus()
        
        ; Auto-convert if we have data
        if parsedAmount && parsedCurrency {
            SetTimer(() => this.AutoConvert(), -100)
        } else if parsedAmount {
            SetTimer(() => this.AutoConvert(), -100)
        }
    }
    
    ; Helper function to check if value exists in array
    HasValueInCurrencies(arr, value) {
        for item in arr {
            if (item = value)
                return true
        }
        return false
    }
    
    ; Function to swap from/to currencies
    SwapCurrenciesInGUI() {
        try {
            fromCur := this.fromCombo.Text
            toCur := this.toCombo.Text
            this.fromCombo.Text := toCur
            this.toCombo.Text := fromCur
        } catch as e {
            try {
                this.resultText.Text := "Error swapping currencies: " e.Message
            }
        }
    }
    
    ; Function to copy the result
    CopyResultText() {
        try {
            currentResult := this.resultText.Text
            if (currentResult && currentResult != "Enter amount and select currencies" && !InStr(currentResult, "Auto-detected")) {
                A_Clipboard := currentResult
                ShowMouseTooltip("Result copied to clipboard", 1000)
            } else {
                ShowMouseTooltip("No conversion result to copy", 1000)
            }
        } catch as e {
            ShowMouseTooltip("Error copying to clipboard", 1000)
        }
    }
    
    ; Auto-convert with delay - optimized to reduce performance impact
    AutoConvert() {
        static conversionTimer := 0
        if conversionTimer
            SetTimer conversionTimer, 0
        
        ; Only trigger conversion if we have valid input to avoid unnecessary processing
        amount := Trim(this.amountEdit.Text)
        fromCur := this.fromCombo.Text
        toCur := this.toCombo.Text
        
        ; Quick validation to avoid heavy processing for incomplete input
        if (!amount || !RegExMatch(amount, "^\d+(\.\d+)?$") || !fromCur || !toCur) {
            this.resultText.Text := "Enter amount and select currencies"
            this.timestampText.Text := ""
            return
        }
        
        ; Increase delay to reduce frequency of expensive operations
        conversionTimer := () => this.DoConversion()
        SetTimer conversionTimer, -1500  ; Increased from 500ms to 1500ms to reduce performance impact
    }
    
    ; Main conversion function
    DoConversion() {
        try {
            amount := Trim(this.amountEdit.Text)
            fromCur := this.fromCombo.Text
            toCur := this.toCombo.Text
        } catch as e {
            try {
                this.resultText.Text := "Error accessing GUI controls: " e.Message
            }
            return
        }
        
        ; Validate inputs
        if !amount {
            this.resultText.Text := "Please enter an amount"
            this.timestampText.Text := ""
            return
        }
        
        if !RegExMatch(amount, "^\d+(\.\d+)?$") {
            this.resultText.Text := "Invalid amount. Please enter numbers only."
            this.timestampText.Text := ""
            return
        }
        
        if !fromCur || !toCur {
            this.resultText.Text := "Please select both currencies"
            this.timestampText.Text := ""
            return
        }
        
        if (fromCur = toCur) {
            currentTime := FormatTime(, "yyyy-MM-dd HH:mm:ss")
            this.resultText.Text := amount " " fromCur " = " amount " " toCur
            this.timestampText.Text := "Same currency: " currentTime
            return
        }
        
        ; Currency conversion
        try {
            this.resultText.Text := "Converting " amount " " fromCur " to " toCur "..."
            
            ; Python script for conversion
            tempOutput := A_ScriptDir "\currency_output.txt"
            pythonScript := 'import sys' . "`n"
            pythonScript .= 'import json' . "`n"
            pythonScript .= 'try:' . "`n"
            pythonScript .= '    import urllib.request' . "`n"
            pythonScript .= '    from_cur, to_cur, amount = sys.argv[1], sys.argv[2], float(sys.argv[3])' . "`n"
            pythonScript .= '    url = f"https://api.exchangerate-api.com/v4/latest/{from_cur}"' . "`n"
            pythonScript .= '    with open(r"' . tempOutput . '", "w", encoding="utf-8") as output:' . "`n"
            pythonScript .= '        output.write(f"Fetching rates for {from_cur}...\\n")' . "`n"
            pythonScript .= '        output.flush()' . "`n"
            pythonScript .= '        with urllib.request.urlopen(url, timeout=10) as response:' . "`n"
            pythonScript .= '            data = json.loads(response.read().decode())' . "`n"
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
            
            ; Save and run Python script
            tempScript := A_ScriptDir "\currency_convert.py"
            
            ; Clean up existing files
            if FileExist(tempScript)
                try FileDelete(tempScript)
            if FileExist(tempOutput)
                try FileDelete(tempOutput)
            
            try {
                FileAppend(pythonScript, tempScript)
                this.resultText.Text := "Python script created successfully. Testing Python..."
                
                ; Try Python commands
                pythonCommands := ["python", "python3", "py"]
                pythonWorked := false
                result := ""
                
                for index, pythonCmd in pythonCommands {
                    try {
                        RunWait(pythonCmd ' --version', , "Hide")
                        scriptCmd := pythonCmd ' "' tempScript '" "' fromCur '" "' toCur '" "' amount '"'
                        RunWait(scriptCmd, , "Hide")
                        
                        if FileExist(tempOutput) {
                            result := FileRead(tempOutput)
                            if result && InStr(result, fromCur) && InStr(result, toCur) && !InStr(result, "Error:") {
                                pythonWorked := true
                                break
                            }
                        }
                    } catch {
                        continue
                    }
                }
                
                try FileDelete(tempScript)
                
                if pythonWorked {
                    try FileDelete(tempOutput)
                    
                    if result {
                        result := StrReplace(result, "\n", "`n")
                        result := StrReplace(result, "\r", "")
                        
                        lines := StrSplit(result, "`n")
                        conversionLine := ""
                        
                        for line in lines {
                            line := Trim(line)
                            if InStr(line, " = ") && InStr(line, fromCur) && InStr(line, toCur) && !InStr(line, "Rate:") {
                                conversionLine := Trim(line)
                                break
                            }
                        }
                        
                        currentTime := FormatTime(, "yyyy-MM-dd HH:mm:ss")
                        if conversionLine {
                            this.resultText.Text := conversionLine
                            this.timestampText.Text := "Rate updated: " currentTime
                            
                            if (this.autoCopyCheck.Value) {
                                A_Clipboard := conversionLine
                                ShowMouseTooltip("Conversion copied to clipboard", 1000)
                            }
                        } else {
                            this.resultText.Text := "Conversion completed"
                            this.timestampText.Text := "Rate updated: " currentTime
                        }
                    } else {
                        this.resultText.Text := "No conversion data received"
                        this.timestampText.Text := ""
                    }
                } else {
                    try FileDelete(tempOutput)
                    
                    ; Fallback rates
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
                        conversionResult := amount " " fromCur " = " Round(result, 4) " " toCur
                        this.resultText.Text := conversionResult
                        this.timestampText.Text := "Fallback rate used: " currentTime
                        
                        if (this.autoCopyCheck.Value) {
                            A_Clipboard := conversionResult
                            ShowMouseTooltip("Conversion copied to clipboard", 1000)
                        }
                    } else {
                        this.resultText.Text := "Currency pair not supported"
                        this.timestampText.Text := "Supported: USD⟷OMR, USD⟷EUR, USD⟷GBP"
                    }
                }
                
            } catch as e {
                ; Fallback rates if file operations fail
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
                    conversionResult := amount " " fromCur " = " Round(result, 4) " " toCur
                    this.resultText.Text := conversionResult
                    this.timestampText.Text := "Fallback rate used: " currentTime
                    
                    if (this.autoCopyCheck.Value) {
                        A_Clipboard := conversionResult
                        ShowMouseTooltip("Conversion copied to clipboard", 1000)
                    }
                } else {
                    this.resultText.Text := "Currency pair not supported"
                    this.timestampText.Text := "Supported: USD⟷OMR, USD⟷EUR, USD⟷GBP"
                }
            }
            
        } catch as e {
            this.resultText.Text := "Error in currency conversion: " e.Message
            this.timestampText.Text := ""
        }
    }
} 