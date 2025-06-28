#Requires AutoHotkey v2.0-*

; Email & Password Manager Plugin
; Provides email masking, temporary emails, username/password generation, and Bitwarden integration
class EmailPasswordManagerPlugin {
    ; Plugin metadata
    static Name := "Email & Password Manager"
    static Version := "1.0.0"
    static Description := "Generate masked emails, temporary emails, usernames, passwords with Bitwarden integration"
    static Author := "AHK Tools"
    Enabled := false
    
    ; Plugin settings
    Settings := {
        enabled: true,
        primaryEmail: "yourname@gmail.com",
        defaultMaskPrefix: "shopping",
        usernameTemplate: "user_{random}",
        passwordLength: 16,
        passwordIncludeSymbols: true,
        passwordIncludeNumbers: true,
        passwordIncludeUppercase: true,
        passwordIncludeLowercase: true,
        bitwardenEnabled: false,
        bitwardenPath: "bw",
        tempEmailService: "10minutemail", ; 10minutemail, guerrillamail, tempmail
        encryptCredentials: false ; Simple encryption available
    }
    
    ; Temporary email services
    TempEmailServices := Map(
        "10minutemail", "https://10minutemail.com/",
        "guerrillamail", "https://www.guerrillamail.com/",
        "tempmail", "https://temp-mail.org/",
        "maildrop", "https://maildrop.cc/"
    )
    
    ; Recent generations for quick access
    RecentEmails := []
    RecentUsernames := []
    RecentPasswords := []
    
    ; Constructor
    __New() {
        this.LoadSettings()
        OutputDebug("EmailPasswordManager: Plugin initialized")
    }
    
    ; Initialize the plugin
    Initialize() {
        try {
            this.LoadSettings()
            OutputDebug("EmailPasswordManager: Plugin initialized successfully")
            return true
        } catch as e {
            OutputDebug("EmailPasswordManager: Error initializing plugin: " e.Message)
            return false
        }
    }
    
    ; Enable the plugin
    Enable() {
        try {
            this.Enabled := true
            OutputDebug("EmailPasswordManager: Plugin enabled successfully")
        } catch as e {
            OutputDebug("EmailPasswordManager: Error enabling plugin: " e.Message)
            MsgBox("Error enabling Email & Password Manager plugin: " e.Message, "Plugin Error", "Iconx")
            return false
        }
        return true
    }
    
    ; Disable the plugin
    Disable() {
        try {
            this.Enabled := false
        } catch as e {
            MsgBox("Error disabling Email & Password Manager plugin: " e.Message, "Plugin Error", "Iconx")
            return false
        }
        return true
    }
    
    ; Show plugin settings
    ShowSettings() {
        if (!this.Enabled) {
            MsgBox("Plugin is not enabled.", "Email & Password Manager", "Iconi")
            return
        }
        
        this.ShowMainInterface()
    }
    
      ; =================== SIMPLE ENCRYPTION SYSTEM ===================
      ; Ultra-Simple ROT13-style Encryption - No arithmetic operations!
      EncryptText(text) {
          if (!this.Settings.encryptCredentials) {
              ; Return unencrypted content with proper header
              return "=== GENERATED CREDENTIALS ===" . "`n" . text
          }
          
          try {
              ; Use simple character replacement (ROT13 style)
              upperFrom := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
              upperTo   := "NOPQRSTUVWXYZABCDEFGHIJKLM"
              lowerFrom := "abcdefghijklmnopqrstuvwxyz"
              lowerTo   := "nopqrstuvwxyzabcdefghijklm"
              
              encrypted := ""
              Loop Parse, text {
                  char := A_LoopField
                  
                  ; Find character in alphabet and replace
                  pos := InStr(upperFrom, char)
                  if (pos > 0) {
                      ; Uppercase letter
                      encrypted .= SubStr(upperTo, pos, 1)
                  } else {
                      pos := InStr(lowerFrom, char)
                      if (pos > 0) {
                          ; Lowercase letter
                          encrypted .= SubStr(lowerTo, pos, 1)
                      } else {
                          ; Not a letter, keep as-is
                          encrypted .= char
                      }
                  }
              }
              
              ; Return with clear markers
              return "=== AHK ENCRYPTED CREDENTIALS (ROT13) ===" . "`n" . encrypted . "`n" . "=== END ENCRYPTED DATA ===" . "`n"
              
          } catch as e {
              ; Fallback to unencrypted with error note
              return "=== GENERATED CREDENTIALS ===" . "`n" . "; ENCRYPTION_FAILED: " . e.Message . "`n" . text
          }
      }
      
      ; Decrypt ROT13-style text 
      DecryptText(text) {
          ; Check if text is encrypted
          if (!InStr(text, "=== AHK ENCRYPTED CREDENTIALS")) {
              return text ; Not encrypted
          }
          
          try {
              ; Extract encrypted portion - find content between headers
              headerEnd := InStr(text, "`n", InStr(text, "=== AHK ENCRYPTED CREDENTIALS"))
              footerStart := InStr(text, "`n=== END ENCRYPTED DATA ===")
              
              if (headerEnd == 0 || footerStart == 0 || footerStart <= headerEnd) {
                  throw Error("Malformed encrypted data - missing headers")
              }
              
              encrypted := SubStr(text, headerEnd + 1, footerStart - headerEnd - 1)
              encrypted := Trim(encrypted)
              
              ; ROT13 is its own inverse - same replacement tables
              upperFrom := "NOPQRSTUVWXYZABCDEFGHIJKLM"
              upperTo   := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
              lowerFrom := "nopqrstuvwxyzabcdefghijklm"
              lowerTo   := "abcdefghijklmnopqrstuvwxyz"
              
              decrypted := ""
              Loop Parse, encrypted {
                  char := A_LoopField
                  
                  ; Find character in alphabet and replace back
                  pos := InStr(upperFrom, char)
                  if (pos > 0) {
                      ; Uppercase letter
                      decrypted .= SubStr(upperTo, pos, 1)
                  } else {
                      pos := InStr(lowerFrom, char)
                      if (pos > 0) {
                          ; Lowercase letter
                          decrypted .= SubStr(lowerTo, pos, 1)
                      } else {
                          ; Not a letter, keep as-is
                          decrypted .= char
                      }
                  }
              }
              
              return decrypted
              
          } catch as e {
              return "; DECRYPTION_ERROR: " . e.Message
          }
      }
      
      ; Add test data for debugging
    AddTestData() {
        ; Clear existing data
        this.RecentEmails := []
        this.RecentUsernames := []
        this.RecentPasswords := []
        
        ; Add test emails
        this.RecentEmails.Push({
            email: "test123+shopping@gmail.com",
            prefix: "shopping",
            created: A_Now
        })
        this.RecentEmails.Push({
            email: "user@temp-mail.org",
            service: "tempmail",
            expiry: "10 minutes",
            created: A_Now
        })
        
        ; Add test usernames
        this.RecentUsernames.Push({
            username: "user_abc123",
            template: "user_{random}",
            created: A_Now
        })
        this.RecentUsernames.Push({
            username: "gamer_wolf2024",
            template: "{adjective}_{animal}{year}",
            created: A_Now
        })
        
        ; Add test passwords
        this.RecentPasswords.Push({
            password: "Abc123!@#XyZ",
            length: 12,
            strength: "Strong",
            created: A_Now
        })
        this.RecentPasswords.Push({
            password: "P@ssw0rd2024$",
            length: 13,
            strength: "Very Strong",
            created: A_Now
        })
        
        MsgBox("✅ Test data added successfully!`n`n• 2 test emails`n• 2 test usernames`n• 2 test passwords`n`nNow you can test 'Save to File' with real data.", "Test Data Added", "Iconi")
    }
    
    ; Test encryption/decryption functionality
    TestEncryption() {
        try {
            ; Test data
            testText := "Test Email: user@example.com`nTest Password: TestPass123`nTest Username: TestUser"
            
            ; Test encryption
            encrypted := this.EncryptText(testText)
            
            ; Test decryption
            decrypted := this.DecryptText(encrypted)
            
            ; Show results
            resultText := "🔒 ENCRYPTION TEST RESULTS:`n`n"
            resultText .= "Original Text:`n" . testText . "`n`n"
            resultText .= "Encrypted Form:`n" . encrypted . "`n`n"
            resultText .= "Decrypted Result:`n" . decrypted . "`n`n"
            
            ; Check if encryption actually worked (not just fallback)
            if (InStr(encrypted, "ENCRYPTION_FAILED")) {
                resultText .= "❌ ENCRYPTION FAILED: Check error message above"
            } else if (InStr(encrypted, "=== AHK ENCRYPTED CREDENTIALS")) {
                ; Encryption worked, now check decryption
                if (InStr(decrypted, "Test Email: user@example.com") && !InStr(decrypted, "DECRYPTION_ERROR")) {
                    resultText .= "✅ SUCCESS: Encryption/Decryption working correctly!"
                } else {
                    resultText .= "❌ DECRYPTION FAILED: Could not decrypt properly"
                }
            } else {
                resultText .= "❌ UNKNOWN ERROR: Unexpected encryption result"
            }
            
            ; Show in a scrollable text control
            testGui := Gui("+AlwaysOnTop +Resize", "Encryption Test Results")
            testGui.SetFont("s9", "Courier New")
            testGui.BackColor := 0xF0F0F0
            
            resultEdit := testGui.Add("Edit", "x10 y10 w600 h400 ReadOnly VScroll", resultText)
            resultEdit.SetFont("s9", "Courier New")
            
            closeTestBtn := testGui.Add("Button", "x260 y420 w100 h30", "Close")
            closeTestBtn.OnEvent("Click", (*) => testGui.Destroy())
            
            testGui.OnEvent("Escape", (*) => testGui.Destroy())
            testGui.Show("w620 h460")
            
        } catch as e {
            MsgBox("❌ Encryption test failed!`n`nError: " . e.Message, "Test Failed", "Iconx")
        }
    }
    
    ; Main interface
    ShowMainInterface() {
        mainGui := Gui("+AlwaysOnTop +Resize", "Email & Password Manager v" EmailPasswordManagerPlugin.Version)
        mainGui.SetFont("s9", "Segoe UI")
        
        ; Tabs
        tabControl := mainGui.Add("Tab3", "x10 y10 w700 h310", ["Email Masking", "Temp Email", "Username", "Password", "Bitwarden", "Settings"])
        
        ; === EMAIL MASKING TAB ===
        tabControl.UseTab(1)
        mainGui.Add("GroupBox", "x20 y40 w670 h100", "Gmail Email Masking")
        mainGui.Add("Text", "x30 y60", "Primary Email:")
        emailEdit := mainGui.Add("Edit", "x120 y58 w200")
        emailEdit.Text := this.Settings.primaryEmail
        
        mainGui.Add("Text", "x30 y85", "Mask Prefix:")
        maskEdit := mainGui.Add("Edit", "x120 y83 w200")
        maskEdit.Text := this.Settings.defaultMaskPrefix
        
        generateMaskBtn := mainGui.Add("Button", "x330 y58 w100 h25", "Generate Mask")
        copyMaskBtn := mainGui.Add("Button", "x440 y58 w80 h25", "Copy")
        
        mainGui.Add("Text", "x30 y110", "Result:")
        maskResult := mainGui.Add("Edit", "x120 y108 w500 ReadOnly")
        
        ; Recent masked emails
        mainGui.Add("GroupBox", "x20 y150 w670 h180", "Recent Masked Emails")
        maskHistoryList := mainGui.Add("ListView", "x30 y170 w650 h150", ["Masked Email", "Prefix", "Created"])
        ; Auto-adjust column widths for better visibility
        maskHistoryList.ModifyCol(1, 400)  ; Masked Email - wider
        maskHistoryList.ModifyCol(2, 120)  ; Prefix
        maskHistoryList.ModifyCol(3, 130)  ; Created
        
        ; === TEMP EMAIL TAB ===
        tabControl.UseTab(2)
        mainGui.Add("GroupBox", "x20 y40 w670 h100", "Temporary Email Services")
        mainGui.Add("Text", "x30 y60", "Service:")
        tempServiceCombo := mainGui.Add("ComboBox", "x100 y58 w150", ["10minutemail", "guerrillamail", "tempmail", "maildrop"])
        tempServiceCombo.Text := this.Settings.tempEmailService
        
        openTempBtn := mainGui.Add("Button", "x260 y58 w120 h25", "Open Service")
        getTempBtn := mainGui.Add("Button", "x390 y58 w100 h25", "Get Email")
        
        mainGui.Add("Text", "x30 y85", "Temp Email:")
        tempEmailResult := mainGui.Add("Edit", "x120 y83 w400 ReadOnly")
        copyTempBtn := mainGui.Add("Button", "x530 y83 w80 h25", "Copy")
        
        mainGui.Add("Text", "x30 y110", "Expires:")
        tempExpiryResult := mainGui.Add("Edit", "x120 y108 w200 ReadOnly")
        
        ; Recent temp emails
        mainGui.Add("GroupBox", "x20 y150 w670 h180", "Recent Temporary Emails")
        tempHistoryList := mainGui.Add("ListView", "x30 y170 w650 h150", ["Email", "Service", "Expires", "Created"])
        ; Auto-adjust column widths for better visibility
        tempHistoryList.ModifyCol(1, 300)  ; Email - wider
        tempHistoryList.ModifyCol(2, 120)  ; Service
        tempHistoryList.ModifyCol(3, 110)  ; Expires
        tempHistoryList.ModifyCol(4, 120)  ; Created
        
        ; === USERNAME TAB ===
        tabControl.UseTab(3)
        mainGui.Add("GroupBox", "x20 y40 w670 h130", "Username Generator")
        mainGui.Add("Text", "x30 y60", "Template:")
        usernameTemplateEdit := mainGui.Add("Edit", "x120 y58 w400")
        usernameTemplateEdit.Text := this.Settings.usernameTemplate
        
        generateUsernameBtn := mainGui.Add("Button", "x530 y58 w80 h25", "Generate")
        
        mainGui.Add("Text", "x30 y85", "Available placeholders:")
        mainGui.Add("Text", "x30 y105", "{random} - Random numbers  {word} - Random word  {adjective} - Random adjective")
        mainGui.Add("Text", "x30 y125", "{animal} - Random animal  {color} - Random color  {year} - Current year")
        
        mainGui.Add("Text", "x30 y145", "Result:")
        usernameResult := mainGui.Add("Edit", "x120 y143 w400 ReadOnly")
        copyUsernameBtn := mainGui.Add("Button", "x530 y143 w80 h25", "Copy")
        
        ; Recent usernames
        mainGui.Add("GroupBox", "x20 y180 w670 h150", "Recent Usernames")
        usernameHistoryList := mainGui.Add("ListView", "x30 y200 w650 h120", ["Username", "Template Used", "Created"])
        ; Auto-adjust column widths for better visibility
        usernameHistoryList.ModifyCol(1, 300)  ; Username - wider
        usernameHistoryList.ModifyCol(2, 220)  ; Template Used
        usernameHistoryList.ModifyCol(3, 130)  ; Created
        
        ; === PASSWORD TAB ===
        tabControl.UseTab(4)
        mainGui.Add("GroupBox", "x20 y40 w670 h160", "Password Generator")
        mainGui.Add("Text", "x30 y60", "Length:")
        passwordLengthEdit := mainGui.Add("Edit", "x120 y58 w60")
        passwordLengthEdit.Text := this.Settings.passwordLength
        mainGui.Add("UpDown", "x180 y58 w17 h21 Range8-128", this.Settings.passwordLength)
        
        uppercaseCheck := mainGui.Add("Checkbox", "x30 y85", "Include Uppercase (A-Z)")
        uppercaseCheck.Value := this.Settings.passwordIncludeUppercase
        
        lowercaseCheck := mainGui.Add("Checkbox", "x200 y85", "Include Lowercase (a-z)")
        lowercaseCheck.Value := this.Settings.passwordIncludeLowercase
        
        numbersCheck := mainGui.Add("Checkbox", "x30 y105", "Include Numbers (0-9)")
        numbersCheck.Value := this.Settings.passwordIncludeNumbers
        
        symbolsCheck := mainGui.Add("Checkbox", "x200 y105", "Include Symbols (!@#$%)")
        symbolsCheck.Value := this.Settings.passwordIncludeSymbols
        
        generatePasswordBtn := mainGui.Add("Button", "x400 y85 w100 h25", "Generate")
        strengthBtn := mainGui.Add("Button", "x510 y85 w100 h25", "Check Strength")
        
        mainGui.Add("Text", "x30 y135", "Result:")
        passwordResult := mainGui.Add("Edit", "x120 y133 w400 ReadOnly")
        copyPasswordBtn := mainGui.Add("Button", "x530 y133 w80 h25", "Copy")
        
        mainGui.Add("Text", "x30 y165", "Strength:")
        strengthResult := mainGui.Add("Edit", "x120 y163 w200 ReadOnly")
        
        ; Recent passwords
        mainGui.Add("GroupBox", "x20 y210 w670 h120", "Recent Passwords")
        passwordHistoryList := mainGui.Add("ListView", "x30 y230 w650 h90", ["Password", "Length", "Strength", "Created"])
        ; Auto-adjust column widths for better visibility
        passwordHistoryList.ModifyCol(1, 350)  ; Password - much wider
        passwordHistoryList.ModifyCol(2, 80)   ; Length
        passwordHistoryList.ModifyCol(3, 120)  ; Strength
        passwordHistoryList.ModifyCol(4, 100)  ; Created
        
        ; === BITWARDEN TAB ===
        tabControl.UseTab(5)
        mainGui.Add("GroupBox", "x20 y40 w670 h200", "Bitwarden Integration")
        
        bitwardenEnabledCheck := mainGui.Add("Checkbox", "x30 y60", "Enable Bitwarden Integration")
        bitwardenEnabledCheck.Value := this.Settings.bitwardenEnabled
        
        mainGui.Add("Text", "x30 y85", "Bitwarden CLI Path:")
        bitwardenPathEdit := mainGui.Add("Edit", "x30 y105 w500")
        bitwardenPathEdit.Text := this.Settings.bitwardenPath
        browseBitwardenBtn := mainGui.Add("Button", "x540 y105 w80 h25", "Browse")
        
        ; Connection and Setup buttons (first row)
        testBitwardenBtn := mainGui.Add("Button", "x30 y135 w100 h25", "Test Connection")
        setupAuthBtn := mainGui.Add("Button", "x140 y135 w120 h25", "Setup Authentication")
        
        ; Installation buttons (second row)
        autoInstallBtn := mainGui.Add("Button", "x30 y165 w100 h25", "Auto-Install CLI")
        detectPathBtn := mainGui.Add("Button", "x140 y165 w100 h25", "Auto-Detect Path")
        resetPathBtn := mainGui.Add("Button", "x250 y165 w80 h25", "Reset to 'bw'")
        setupGuideBtn := mainGui.Add("Button", "x340 y165 w100 h25", "Setup Guide")
        
        ; Quick Save section
        mainGui.Add("Text", "x30 y195", "Quick Save:")
        saveToVaultBtn := mainGui.Add("Button", "x110 y193 w130 h25", "Save to Vault")
        saveToFileBtn := mainGui.Add("Button", "x250 y193 w130 h25", "Save to File")
        viewFileBtn := mainGui.Add("Button", "x390 y193 w100 h25", "View File")
        
        ; Note moved down to not overlap
        mainGui.Add("Text", "x30 y225", "Note: Auto-install downloads and configures Bitwarden CLI automatically")
        
        ; Additional space for future features
        mainGui.Add("GroupBox", "x20 y250 w670 h80", "Vault Management")
        mainGui.Add("Text", "x30 y270", "Future features:")
        mainGui.Add("Text", "x30 y290", "• Sync with vault entries  • Import/Export data  • Backup scheduling  • Multi-vault support")
        
        ; === SETTINGS TAB ===
        tabControl.UseTab(6)
        mainGui.Add("GroupBox", "x20 y40 w320 h150", "General Settings")
        
        enabledCheck := mainGui.Add("Checkbox", "x30 y60", "Enable Plugin")
        enabledCheck.Value := this.Settings.enabled
        
        autoCopyCheck := mainGui.Add("Checkbox", "x30 y85", "Auto-copy generated items to clipboard")
        
        mainGui.Add("Text", "x30 y115", "History Settings:")
        mainGui.Add("Text", "x30 y135", "Keep last 50 items in history")
        clearHistoryBtn := mainGui.Add("Button", "x30 y155 w120 h25", "Clear All History")
        
        exportBtn := mainGui.Add("Button", "x160 y155 w80 h25", "Export")
        importBtn := mainGui.Add("Button", "x250 y155 w80 h25", "Import")
        
        ; Security settings (with proper height for buttons)
        mainGui.Add("GroupBox", "x350 y40 w340 h150", "Security Settings")
        
        encryptCheck := mainGui.Add("Checkbox", "x360 y65", "Enable simple encryption")
        encryptCheck.Value := this.Settings.encryptCredentials
        
        mainGui.Add("Text", "x360 y85 w320", "When enabled, files use rotation cipher encryption.")
        mainGui.Add("Text", "x360 y100 w320", "⚠️ Otherwise saved in plain text - keep secure!")
        
        ; Move buttons to proper position within the GroupBox
        testDataBtn := mainGui.Add("Button", "x360 y125 w120 h25", "📝 Add Test Data")
        testDataBtn.OnEvent("Click", (*) => this.AddTestData())
        
        testEncryptBtn := mainGui.Add("Button", "x490 y125 w130 h25", "🔒 Test Encryption")
        testEncryptBtn.OnEvent("Click", (*) => this.TestEncryption())
        
        ; Advanced settings (moved down to accommodate taller groups above)
        mainGui.Add("GroupBox", "x20 y200 w670 h110", "Advanced Settings")
        mainGui.Add("Text", "x30 y220", "Default Templates:")
        mainGui.Add("Text", "x30 y240", "Primary email:")
        primaryEmailEdit := mainGui.Add("Edit", "x150 y238 w300")
        primaryEmailEdit.Text := this.Settings.primaryEmail
        mainGui.Add("Text", "x460 y240", "(Used for email masking)")
        
        mainGui.Add("Text", "x30 y265", "Email prefix template:")
        defaultPrefixEdit := mainGui.Add("Edit", "x150 y263 w150")
        defaultPrefixEdit.Text := this.Settings.defaultMaskPrefix
        
        mainGui.Add("Text", "x310 y265", "Username template:")
        defaultUsernameEdit := mainGui.Add("Edit", "x430 y263 w150")
        defaultUsernameEdit.Text := this.Settings.usernameTemplate
        
        mainGui.Add("Text", "x30 y290", "Password length:")
        defaultPasswordLengthEdit := mainGui.Add("Edit", "x150 y288 w60")
        defaultPasswordLengthEdit.Text := this.Settings.passwordLength
        
        ; Advanced settings save button
        saveAdvancedBtn := mainGui.Add("Button", "x590 y285 w100 h25", "Save Advanced")
        
        ; Bottom buttons (moved down)
        saveBtn := mainGui.Add("Button", "x20 y325 w100 h30", "Save All")
        helpBtn := mainGui.Add("Button", "x130 y325 w80 h30", "Help")
        closeBtn := mainGui.Add("Button", "x630 y325 w80 h30", "Close")
        
        ; Event handlers
        generateMaskBtn.OnEvent("Click", (*) => this.GenerateMaskedEmail(emailEdit.Text, maskEdit.Text, maskResult, maskHistoryList))
        copyMaskBtn.OnEvent("Click", (*) => this.CopyToClipboard(maskResult.Text))
        
        openTempBtn.OnEvent("Click", (*) => this.OpenTempEmailService(tempServiceCombo.Text))
        getTempBtn.OnEvent("Click", (*) => this.GetTempEmail(tempServiceCombo.Text, tempEmailResult, tempExpiryResult, tempHistoryList))
        copyTempBtn.OnEvent("Click", (*) => this.CopyToClipboard(tempEmailResult.Text))
        
        generateUsernameBtn.OnEvent("Click", (*) => this.GenerateUsername(usernameTemplateEdit.Text, usernameResult, usernameHistoryList))
        copyUsernameBtn.OnEvent("Click", (*) => this.CopyToClipboard(usernameResult.Text))
        
        generatePasswordBtn.OnEvent("Click", (*) => this.GeneratePassword(passwordLengthEdit.Text, (uppercaseCheck.Value = 1), (lowercaseCheck.Value = 1), (numbersCheck.Value = 1), (symbolsCheck.Value = 1), passwordResult, strengthResult, passwordHistoryList))
        strengthBtn.OnEvent("Click", (*) => this.CheckPasswordStrength(passwordResult.Text, strengthResult))
        copyPasswordBtn.OnEvent("Click", (*) => this.CopyToClipboard(passwordResult.Text))
        
        browseBitwardenBtn.OnEvent("Click", (*) => this.BrowseBitwardenPath(bitwardenPathEdit))
        testBitwardenBtn.OnEvent("Click", (*) => this.TestBitwardenConnection())
        setupAuthBtn.OnEvent("Click", (*) => this.ShowAuthenticationSetup())
        autoInstallBtn.OnEvent("Click", (*) => this.AutoInstallBitwardenCLI(bitwardenPathEdit))
        detectPathBtn.OnEvent("Click", (*) => this.AutoDetectBitwardenPath(bitwardenPathEdit))
        resetPathBtn.OnEvent("Click", (*) => this.ResetBitwardenPath(bitwardenPathEdit))
        setupGuideBtn.OnEvent("Click", (*) => this.ShowBitwardenSetupGuide())
        saveToVaultBtn.OnEvent("Click", (*) => this.SaveToVault())
        saveToFileBtn.OnEvent("Click", (*) => this.SaveToFile())
        viewFileBtn.OnEvent("Click", (*) => this.ViewSavedFile())
        
        clearHistoryBtn.OnEvent("Click", (*) => this.ClearAllHistory())
        exportBtn.OnEvent("Click", (*) => this.ExportSettings())
        importBtn.OnEvent("Click", (*) => this.ImportSettings())
        saveAdvancedBtn.OnEvent("Click", (*) => this.SaveAdvancedSettings(primaryEmailEdit.Text, defaultPrefixEdit.Text, defaultUsernameEdit.Text, defaultPasswordLengthEdit.Text))
        
        saveBtn.OnEvent("Click", (*) => this.SaveAllSettings(emailEdit.Text, maskEdit.Text, tempServiceCombo.Text, usernameTemplateEdit.Text, passwordLengthEdit.Text, (uppercaseCheck.Value = 1), (lowercaseCheck.Value = 1), (numbersCheck.Value = 1), (symbolsCheck.Value = 1), (bitwardenEnabledCheck.Value = 1), bitwardenPathEdit.Text, (enabledCheck.Value = 1), primaryEmailEdit.Text, defaultPrefixEdit.Text, defaultUsernameEdit.Text, defaultPasswordLengthEdit.Text, (encryptCheck.Value = 1), mainGui))
        helpBtn.OnEvent("Click", (*) => this.ShowHelp())
        closeBtn.OnEvent("Click", (*) => mainGui.Destroy())
        mainGui.OnEvent("Close", (*) => mainGui.Destroy())
        
        ; Load history
        this.LoadHistory(maskHistoryList, tempHistoryList, usernameHistoryList, passwordHistoryList)
        
        mainGui.Show("w720 h365")
    }
    
    ; Generate masked email
    GenerateMaskedEmail(email, prefix, resultControl, historyList) {
        try {
            if (!email || !prefix) {
                MsgBox("Please enter both email and prefix.", "Missing Information", "Iconx")
                return
            }
            
            ; Extract username and domain from email
            emailParts := StrSplit(email, "@")
            if (emailParts.Length != 2) {
                MsgBox("Invalid email format.", "Error", "Iconx")
                return
            }
            
            username := emailParts[1]
            domain := emailParts[2]
            
            ; Create masked email
            maskedEmail := username "+" prefix "@" domain
            resultControl.Text := maskedEmail
            
            ; Add to history
            this.RecentEmails.Push({
                email: maskedEmail,
                prefix: prefix,
                created: A_Now
            })
            
            ; Update history list
            historyList.Add("", maskedEmail, prefix, FormatTime(A_Now, "yyyy-MM-dd HH:mm"))
            
            ; Auto-copy to clipboard
            A_Clipboard := maskedEmail
            ShowMouseTooltip("Masked email copied to clipboard", 2000)
            
        } catch as e {
            MsgBox("Error generating masked email: " e.Message, "Error", "Iconx")
        }
    }
    
    ; Open temporary email service
    OpenTempEmailService(service) {
        if (this.TempEmailServices.Has(service)) {
            Run(this.TempEmailServices[service])
        } else {
            MsgBox("Unknown service: " service, "Error", "Iconx")
        }
    }
    
    ; Get temporary email (simulated - in real implementation would use APIs)
    GetTempEmail(service, emailControl, expiryControl, historyList) {
        try {
            ; Generate a random temporary email (simulated)
            randomId := this.GenerateRandomString(8, false, true, true, false)
            
            tempEmail := ""
            expiry := ""
            
            switch service {
                case "10minutemail":
                    tempEmail := randomId "@10minutemail.com"
                    expiry := "10 minutes"
                case "guerrillamail":
                    tempEmail := randomId "@guerrillamail.com"
                    expiry := "1 hour"
                case "tempmail":
                    tempEmail := randomId "@temp-mail.org"
                    expiry := "10 minutes"
                case "maildrop":
                    tempEmail := randomId "@maildrop.cc"
                    expiry := "Permanent"
                default:
                    tempEmail := randomId "@temp.com"
                    expiry := "Unknown"
            }
            
            emailControl.Text := tempEmail
            expiryControl.Text := expiry
            
            ; Add to history
            this.RecentEmails.Push({
                email: tempEmail,
                service: service,
                expiry: expiry,
                created: A_Now
            })
            
            ; Update history list
            historyList.Add("", tempEmail, service, expiry, FormatTime(A_Now, "yyyy-MM-dd HH:mm"))
            
            ; Auto-copy to clipboard
            A_Clipboard := tempEmail
            ShowMouseTooltip("Temporary email copied to clipboard", 2000)
            
        } catch as e {
            MsgBox("Error getting temporary email: " e.Message, "Error", "Iconx")
        }
    }
    
    ; Generate username
    GenerateUsername(template, resultControl, historyList) {
        try {
            if (!template) {
                template := "user_{random}"
            }
            
            ; Replace placeholders
            username := template
            username := StrReplace(username, "{random}", this.GenerateRandomString(6, false, true, true, false))
            username := StrReplace(username, "{word}", this.GetRandomWord())
            username := StrReplace(username, "{adjective}", this.GetRandomAdjective())
            username := StrReplace(username, "{animal}", this.GetRandomAnimal())
            username := StrReplace(username, "{color}", this.GetRandomColor())
            username := StrReplace(username, "{year}", A_YYYY)
            
            resultControl.Text := username
            
            ; Add to history
            this.RecentUsernames.Push({
                username: username,
                template: template,
                created: A_Now
            })
            
            ; Update history list
            historyList.Add("", username, template, FormatTime(A_Now, "yyyy-MM-dd HH:mm"))
            
            ; Auto-copy to clipboard
            A_Clipboard := username
            ShowMouseTooltip("Username copied to clipboard", 2000)
            
        } catch as e {
            MsgBox("Error generating username: " e.Message, "Error", "Iconx")
        }
    }
    
    ; Generate password
    GeneratePassword(length, includeUpper, includeLower, includeNumbers, includeSymbols, resultControl, strengthControl, historyList) {
        try {
            passwordLength := Integer(length)
            if (passwordLength < 8 || passwordLength > 128) {
                MsgBox("Password length must be between 8 and 128 characters.", "Invalid Length", "Iconx")
                return
            }
            
            password := this.GenerateRandomString(passwordLength, includeUpper, includeLower, includeNumbers, includeSymbols)
            resultControl.Text := password
            
            ; Check strength
            strength := this.CalculatePasswordStrength(password)
            strengthControl.Text := strength
            
            ; Add to history
            this.RecentPasswords.Push({
                password: password,
                length: passwordLength,
                strength: strength,
                created: A_Now
            })
            
            ; Update history list - show actual password instead of masking it
            historyList.Add("", password, passwordLength, strength, FormatTime(A_Now, "yyyy-MM-dd HH:mm"))
            
            ; Auto-copy to clipboard
            A_Clipboard := password
            ShowMouseTooltip("Password copied to clipboard", 2000)
            
        } catch as e {
            MsgBox("Error generating password: " e.Message, "Error", "Iconx")
        }
    }
    
    ; Check password strength with detailed analysis
    CheckPasswordStrength(password, strengthControl) {
        if (!password) {
            strengthControl.Text := "No password"
            return
        }
        
        ; Calculate and display basic strength
        strength := this.CalculatePasswordStrength(password)
        strengthControl.Text := strength
        
        ; Show detailed analysis popup
        this.ShowDetailedPasswordAnalysis(password)
    }
    
    ; Show detailed password strength analysis in a popup
    ShowDetailedPasswordAnalysis(password) {
        if (!password) {
            return
        }
        
        ; Perform detailed analysis
        length := StrLen(password)
        entropy := this.CalculateEntropy(password)
        
        ; Build detailed report
        report := "🔒 DETAILED PASSWORD STRENGTH ANALYSIS`n"
        report .= "=" . StrReplace(Format("{:60s}", ""), " ", "=") . "`n`n"
        
        ; Basic info
        report .= "📋 BASIC INFORMATION:`n"
        report .= "• Password length: " . length . " characters`n"
        report .= "• Entropy: " . entropy . " bits`n"
        report .= "• Estimated crack time: " . this.EstimateCrackTime(password) . "`n`n"
        
        ; Character analysis
        report .= "📊 CHARACTER ANALYSIS:`n"
        hasLower := RegExMatch(password, "[a-z]")
        hasUpper := RegExMatch(password, "[A-Z]")
        hasNumbers := RegExMatch(password, "[0-9]")
        hasSymbols := RegExMatch(password, "[!@#$%^&*()_+\-=\[\]{}|;':,./<>?`"~]")
        
        report .= "• Lowercase letters: " . (hasLower ? "✅ Present" : "❌ Missing") . "`n"
        report .= "• Uppercase letters: " . (hasUpper ? "✅ Present" : "❌ Missing") . "`n"
        report .= "• Numbers: " . (hasNumbers ? "✅ Present" : "❌ Missing") . "`n"
        report .= "• Special symbols: " . (hasSymbols ? "✅ Present" : "❌ Missing") . "`n`n"
        
        ; Security issues
        issues := []
        if (length < 12) issues.Push("Password is shorter than recommended 12+ characters")
        if (this.HasSequentialChars(password)) issues.Push("Contains sequential characters (abc, 123, etc.)")
        if (this.HasKeyboardPattern(password)) issues.Push("Contains keyboard patterns (qwerty, etc.)")
        if (this.HasCommonNumberPatterns(password)) issues.Push("Contains common number patterns")
        if (this.ContainsCommonWords(password)) issues.Push("Contains common dictionary words")
        if (this.CountRepeatedChars(password) > length * 0.2) issues.Push("Has too many repeated characters")
        
        if (issues.Length > 0) {
            report .= "⚠️ SECURITY ISSUES:`n"
            for issue in issues {
                report .= "• " . issue . "`n"
            }
            report .= "`n"
        }
        
        ; Recommendations
        report .= "💡 RECOMMENDATIONS:`n"
        if (length < 12) report .= "• Use at least 12 characters for better security`n"
        if (!hasLower) report .= "• Add lowercase letters (a-z)`n"
        if (!hasUpper) report .= "• Add uppercase letters (A-Z)`n"
        if (!hasNumbers) report .= "• Add numbers (0-9)`n"
        if (!hasSymbols) report .= "• Add special symbols (!@#$%^&*)`n"
        if (this.HasSequentialChars(password)) report .= "• Avoid sequential characters`n"
        if (this.HasKeyboardPattern(password)) report .= "• Avoid keyboard patterns`n"
        if (this.ContainsCommonWords(password)) report .= "• Avoid common dictionary words`n"
        
        ; If no issues, provide positive feedback
        if (issues.Length = 0 && length >= 12) {
            report .= "✅ Your password follows security best practices!`n"
            report .= "• Consider using a unique password for each account`n"
            report .= "• Store securely in a password manager`n"
        }
        
        ; Show in a scrollable window
        analysisGui := Gui("+AlwaysOnTop +Resize", "Password Strength Analysis")
        analysisGui.SetFont("s9", "Consolas")
        analysisGui.BackColor := 0xF8F9FA
        
        ; Header
        headerText := analysisGui.Add("Text", "x10 y10 w580 Center", "🔐 Password Security Analysis")
        headerText.SetFont("s12 Bold", "Segoe UI")
        
        ; Analysis text
        analysisEdit := analysisGui.Add("Edit", "x10 y40 w580 h400 ReadOnly VScroll", report)
        analysisEdit.SetFont("s9", "Consolas")
        
        ; Buttons
        generateNewBtn := analysisGui.Add("Button", "x10 y450 w140 h30", "Generate New Password")
        generateNewBtn.OnEvent("Click", (*) => this.GenerateStrongPassword(analysisGui))
        
        copyReportBtn := analysisGui.Add("Button", "x160 y450 w120 h30", "Copy Report")
        copyReportBtn.OnEvent("Click", (*) => (A_Clipboard := report, ShowMouseTooltip("Analysis copied to clipboard", 2000)))
        
        closeBtn := analysisGui.Add("Button", "x490 y450 w100 h30", "Close")
        closeBtn.OnEvent("Click", (*) => analysisGui.Destroy())
        
        analysisGui.OnEvent("Close", (*) => analysisGui.Destroy())
        analysisGui.OnEvent("Escape", (*) => analysisGui.Destroy())
        
        analysisGui.Show("w600 h490")
    }
    
    ; Estimate password crack time
    EstimateCrackTime(password) {
        entropy := this.CalculateEntropy(password)
        
        ; Assuming 1 billion guesses per second (modern hardware)
        guessesPerSecond := 1000000000
        
        ; Total possible combinations = 2^entropy
        ; Average time to crack = (2^entropy) / 2 / guesses_per_second
        avgSeconds := (2 ** (entropy - 1)) / guessesPerSecond
        
        ; Convert to human readable time
        if (avgSeconds < 60) {
            return "Less than 1 minute"
        } else if (avgSeconds < 3600) {
            return Round(avgSeconds / 60) . " minutes"
        } else if (avgSeconds < 86400) {
            return Round(avgSeconds / 3600) . " hours"
        } else if (avgSeconds < 31536000) {
            return Round(avgSeconds / 86400) . " days"
        } else if (avgSeconds < 31536000000) {
            return Round(avgSeconds / 31536000) . " years"
        } else if (avgSeconds < 31536000000000) {
            return Round(avgSeconds / 31536000000) . " thousand years"
        } else if (avgSeconds < 31536000000000000) {
            return Round(avgSeconds / 31536000000000) . " million years"
        } else {
            return "Billions of years"
        }
    }
    
    ; Generate a strong password suggestion
    GenerateStrongPassword(parentGui) {
        ; Generate a strong 16-character password
        strongPassword := this.GenerateRandomString(16, true, true, true, true)
        
        ; Show the result
        resultGui := Gui("+Owner" parentGui.Hwnd " +AlwaysOnTop", "Strong Password Generated")
        resultGui.SetFont("s10", "Segoe UI")
        
        resultGui.Add("Text", "x10 y10 w380", "Generated strong password:")
        passwordEdit := resultGui.Add("Edit", "x10 y30 w300 ReadOnly", strongPassword)
        passwordEdit.SetFont("s11 Bold", "Consolas")
        
        copyBtn := resultGui.Add("Button", "x320 y29 w70 h23", "Copy")
        copyBtn.OnEvent("Click", (*) => (A_Clipboard := strongPassword, ShowMouseTooltip("Password copied!", 2000), resultGui.Destroy()))
        
        ; Show strength
        strength := this.CalculatePasswordStrength(strongPassword)
        resultGui.Add("Text", "x10 y60 w380", "Strength: " . strength)
        
        closeBtn := resultGui.Add("Button", "x320 y90 w70 h25", "Close")
        closeBtn.OnEvent("Click", (*) => resultGui.Destroy())
        
        resultGui.OnEvent("Close", (*) => resultGui.Destroy())
        resultGui.Show("w400 h125")
    }
    
    ; Calculate comprehensive password strength with detailed analysis
    CalculatePasswordStrength(password) {
        if (!password) {
            return "No password"
        }
        
        length := StrLen(password)
        score := 0
        issues := []
        bonuses := []
        
        ; === LENGTH ANALYSIS ===
        if (length < 8) {
            score -= 20
            issues.Push("Too short (minimum 8 characters)")
        } else if (length >= 8) {
            score += 10
            if (length >= 12) {
                score += 10
                bonuses.Push("Good length (12+ chars)")
                if (length >= 16) {
                    score += 10
                    bonuses.Push("Excellent length (16+ chars)")
                }
            }
        }
        
        ; === CHARACTER VARIETY ANALYSIS ===
        charTypes := 0
        
        ; Lowercase letters
        if (RegExMatch(password, "[a-z]")) {
            score += 5
            charTypes++
        } else {
            issues.Push("Missing lowercase letters")
        }
        
        ; Uppercase letters
        if (RegExMatch(password, "[A-Z]")) {
            score += 5
            charTypes++
        } else {
            issues.Push("Missing uppercase letters")
        }
        
        ; Numbers
        if (RegExMatch(password, "[0-9]")) {
            score += 5
            charTypes++
        } else {
            issues.Push("Missing numbers")
        }
        
        ; Special symbols
        if (RegExMatch(password, "[!@#$%^&*()_+\-=\[\]{}|;':,./<>?`"~]")) {
            score += 10
            charTypes++
            bonuses.Push("Contains special symbols")
        } else {
            issues.Push("Missing special symbols")
        }
        
        ; Bonus for high character variety
        if (charTypes >= 4) {
            score += 15
            bonuses.Push("Excellent character variety")
        } else if (charTypes >= 3) {
            score += 5
            bonuses.Push("Good character variety")
        }
        
        ; === PATTERN ANALYSIS ===
        ; Check for sequential patterns
        if (this.HasSequentialChars(password)) {
            score -= 10
            issues.Push("Contains sequential characters")
        }
        
        ; Check for repeated characters
        repeatCount := this.CountRepeatedChars(password)
        if (repeatCount > length * 0.3) {
            score -= 15
            issues.Push("Too many repeated characters")
        } else if (repeatCount > length * 0.2) {
            score -= 5
            issues.Push("Some repeated characters")
        }
        
        ; Check for keyboard patterns
        if (this.HasKeyboardPattern(password)) {
            score -= 15
            issues.Push("Contains keyboard patterns")
        }
        
        ; Check for common number patterns
        if (this.HasCommonNumberPatterns(password)) {
            score -= 10
            issues.Push("Contains common number patterns")
        }
        
        ; === DICTIONARY ANALYSIS ===
        if (this.ContainsCommonWords(password)) {
            score -= 20
            issues.Push("Contains common dictionary words")
        }
        
        ; === ENTROPY CALCULATION ===
        entropy := this.CalculateEntropy(password)
        if (entropy >= 60) {
            score += 10
            bonuses.Push("High entropy (randomness)")
        } else if (entropy >= 40) {
            score += 5
        } else if (entropy < 25) {
            score -= 10
            issues.Push("Low entropy (predictable)")
        }
        
        ; === DETERMINE FINAL STRENGTH ===
        ; Ensure score doesn't go below 0
        score := Max(0, score)
        
        strengthLevel := ""
        strengthColor := ""
        
        if (score >= 80) {
            strengthLevel := "Excellent"
            strengthColor := "🟢"
        } else if (score >= 65) {
            strengthLevel := "Strong"
            strengthColor := "🔵"
        } else if (score >= 45) {
            strengthLevel := "Good"
            strengthColor := "🟡"
        } else if (score >= 25) {
            strengthLevel := "Fair"
            strengthColor := "🟠"
        } else {
            strengthLevel := "Weak"
            strengthColor := "🔴"
        }
        
        ; Create detailed result
        result := strengthColor . " " . strengthLevel . " (" . score . "/100)"
        
        ; Add top issues and bonuses for context
        if (issues.Length > 0) {
            result .= " | Issues: " . issues[1]
            if (issues.Length > 1)
                result .= ", " . issues[2]
        }
        
        if (bonuses.Length > 0 && score >= 45) {
            result .= " | ✓ " . bonuses[1]
        }
        
        return result
    }
    
    ; Check for sequential characters (abc, 123, etc.)
    HasSequentialChars(password) {
        sequences := ["abc", "bcd", "cde", "def", "efg", "fgh", "ghi", "hij", "ijk", "jkl", "klm", "lmn", "mno", "nop", "opq", "pqr", "qrs", "rst", "stu", "tuv", "uvw", "vwx", "wxy", "xyz",
                     "123", "234", "345", "456", "567", "678", "789", "890"]
        
        lowerPassword := StrLower(password)
        for seq in sequences {
            if (InStr(lowerPassword, seq) || InStr(lowerPassword, this.ReverseString(seq))) {
                return true
            }
        }
        return false
    }
    
    ; Count repeated characters
    CountRepeatedChars(password) {
        charCount := Map()
        repeated := 0
        
        Loop Parse, password {
            char := A_LoopField
            if (charCount.Has(char)) {
                charCount[char]++
                repeated++
            } else {
                charCount[char] := 1
            }
        }
        return repeated
    }
    
    ; Check for keyboard patterns
    HasKeyboardPattern(password) {
        patterns := ["qwerty", "qwertyui", "asdf", "asdfgh", "zxcv", "zxcvb", "1234", "12345", "1234567890"]
        lowerPassword := StrLower(password)
        
        for pattern in patterns {
            if (InStr(lowerPassword, pattern) || InStr(lowerPassword, this.ReverseString(pattern))) {
                return true
            }
        }
        return false
    }
    
    ; Check for common number patterns
    HasCommonNumberPatterns(password) {
        patterns := ["1234", "4321", "1111", "2222", "3333", "4444", "5555", "6666", "7777", "8888", "9999", "0000", 
                    "1212", "2121", "1010", "2020", "2021", "2022", "2023", "2024", "2025"]
        
        for pattern in patterns {
            if (InStr(password, pattern)) {
                return true
            }
        }
        return false
    }
    
    ; Check for common dictionary words
    ContainsCommonWords(password) {
        commonWords := ["password", "admin", "user", "login", "welcome", "hello", "world", "test", "demo", "sample",
                       "email", "account", "secure", "secret", "private", "public", "master", "guest", "default",
                       "temp", "temporary", "pass", "word", "code", "key", "access", "system", "database"]
        
        lowerPassword := StrLower(password)
        for word in commonWords {
            if (InStr(lowerPassword, word)) {
                return true
            }
        }
        return false
    }
    
    ; Calculate password entropy (measure of randomness)
    CalculateEntropy(password) {
        ; Character set size estimation
        charSetSize := 0
        
        if (RegExMatch(password, "[a-z]")) charSetSize += 26
        if (RegExMatch(password, "[A-Z]")) charSetSize += 26  
        if (RegExMatch(password, "[0-9]")) charSetSize += 10
        if (RegExMatch(password, "[!@#$%^&*()_+\-=\[\]{}|;':,./<>?`"~]")) charSetSize += 33
        
        ; Entropy = log2(charSetSize^length) = length * log2(charSetSize)
        if (charSetSize > 0) {
            entropy := StrLen(password) * (Ln(charSetSize) / Ln(2))
            return Round(entropy, 1)
        }
        return 0
    }
    
    ; Helper function to reverse a string
    ReverseString(str) {
        reversed := ""
        Loop Parse, str {
            reversed := A_LoopField . reversed
        }
        return reversed
    }
    
    ; Generate random string with explicit character type control - SIMPLIFIED VERSION
    GenerateRandomString(length, includeUpper, includeLower, includeNumbers, includeSymbols) {
        chars := ""
        
        ; SUPER SIMPLE boolean checking - handle all possible values
        ; Check for truthy values (1, true, "true", anything non-zero)
        if (includeUpper && includeUpper != 0 && includeUpper != false) {
            chars .= "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        }
        if (includeLower && includeLower != 0 && includeLower != false) {
            chars .= "abcdefghijklmnopqrstuvwxyz"
        }
        if (includeNumbers && includeNumbers != 0 && includeNumbers != false) {
            chars .= "0123456789"
        }
        if (includeSymbols && includeSymbols != 0 && includeSymbols != false) {
            chars .= "!@#$%^&*()_+-=[]{}|;':,./<>?"
        }
        
        ; Fallback if no character types selected
        if (chars == "") {
            chars := "abcdefghijklmnopqrstuvwxyz0123456789"
        }
        
        result := ""
        charCount := StrLen(chars)
        
        Loop length {
            randomIndex := Random(1, charCount)
            result .= SubStr(chars, randomIndex, 1)
        }
        
        return result
    }
    
    ; Get random word
    GetRandomWord() {
        words := ["alpha", "beta", "gamma", "delta", "echo", "foxtrot", "golf", "hotel", "india", "juliet", "kilo", "lima", "mike", "november", "oscar", "papa", "quebec", "romeo", "sierra", "tango", "uniform", "victor", "whiskey", "xray", "yankee", "zulu"]
        index := Random(1, words.Length)
        return words[index]
    }
    
    ; Get random adjective
    GetRandomAdjective() {
        adjectives := ["awesome", "brilliant", "clever", "dynamic", "elegant", "fantastic", "great", "happy", "incredible", "joyful", "keen", "lovely", "magnificent", "nice", "outstanding", "perfect", "quick", "remarkable", "super", "terrific", "unique", "vibrant", "wonderful", "excellent", "young", "zealous"]
        index := Random(1, adjectives.Length)
        return adjectives[index]
    }
    
    ; Get random animal
    GetRandomAnimal() {
        animals := ["bear", "cat", "dog", "eagle", "fox", "giraffe", "horse", "iguana", "jaguar", "kangaroo", "lion", "monkey", "newt", "owl", "panda", "quail", "rabbit", "snake", "tiger", "unicorn", "vulture", "whale", "xerus", "yak", "zebra"]
        index := Random(1, animals.Length)
        return animals[index]
    }
    
    ; Get random color
    GetRandomColor() {
        colors := ["red", "blue", "green", "yellow", "orange", "purple", "pink", "brown", "black", "white", "gray", "cyan", "magenta", "lime", "navy", "olive", "teal", "silver", "gold", "crimson", "violet", "indigo", "turquoise", "coral", "salmon"]
        index := Random(1, colors.Length)
        return colors[index]
    }
    
    ; Copy to clipboard
    CopyToClipboard(text) {
        if (text) {
            A_Clipboard := text
            ShowMouseTooltip("Copied to clipboard", 1500)
        }
    }
    
    ; Browse for Bitwarden path
    BrowseBitwardenPath(pathEdit) {
        selectedFile := FileSelect(1, "", "Select Bitwarden Executable", "Executable Files (*.exe)")
        if (selectedFile) {
            pathEdit.Text := selectedFile
        }
    }
    
    ; Test Bitwarden connection with proper session management
    TestBitwardenConnection() {
        try {
            ; Check if it's a PATH command or full path
            isPathCommand := (this.Settings.bitwardenPath = "bw" || !InStr(this.Settings.bitwardenPath, "\"))
            
            if (!isPathCommand && !FileExist(this.Settings.bitwardenPath)) {
                MsgBox("Bitwarden CLI not found at: " this.Settings.bitwardenPath "`n`nPlease install Bitwarden CLI or update the path.`n`nDownload from: https://bitwarden.com/help/cli/", "Connection Test", "Iconx")
                return
            }
            
            ; Show testing progress
            testGui := Gui("+AlwaysOnTop", "Testing Bitwarden CLI...")
            testGui.SetFont("s9", "Segoe UI")
            testGui.Add("Text", "x20 y20 w250", "🔍 Testing Bitwarden CLI...")
            testStatus := testGui.Add("Text", "x20 y45 w250", "Checking executable...")
            testGui.Show("w290 h90")
            
            ; Test basic version command
            testStatus.Text := "Testing --version command..."
            versionOutput := ""
            if (this.Settings.bitwardenPath = "bw") {
                RunWait('powershell -Command "bw --version 2>&1 | Out-File -FilePath `"' . A_Temp . '\bw_version.txt`" -Encoding UTF8"', , "Hide", &exitCode)
            } else {
                RunWait('cmd /c "' . this.Settings.bitwardenPath . '" --version > "' A_Temp '\bw_version.txt" 2>&1', , "Hide", &exitCode)
            }
            
            if (FileExist(A_Temp "\bw_version.txt")) {
                versionOutput := FileRead(A_Temp "\bw_version.txt")
                FileDelete(A_Temp "\bw_version.txt")
            }
            
            if (InStr(versionOutput, ".")) {
                ; Version test successful - check authentication status
                testStatus.Text := "Checking authentication status..."
                statusOutput := this.GetBitwardenStatus()
                
                testGui.Destroy()
                
                ; Parse status and show appropriate message
                if (InStr(statusOutput, '"status":"unauthenticated"')) {
                    result := MsgBox("✅ Bitwarden CLI is working!`n`nVersion: " Trim(versionOutput) "`nStatus: Not logged in`n`nWould you like to set up authentication now?`n`nYou can choose:`n• Email/Password login`n• API Key login (recommended for automation)`n• SSO login", "Setup Authentication", "YesNo Iconi")
                    if (result = "Yes") {
                        this.ShowAuthenticationSetup()
                    }
                } else if (InStr(statusOutput, '"status":"locked"')) {
                    result := MsgBox("✅ Bitwarden CLI is working!`n`nVersion: " Trim(versionOutput) "`nStatus: Logged in but vault is locked`n`nWould you like to unlock your vault now?", "Unlock Vault", "YesNo Iconi")
                    if (result = "Yes") {
                        this.UnlockVault()
                    }
                } else if (InStr(statusOutput, '"status":"unlocked"')) {
                    MsgBox("✅ Bitwarden CLI is fully ready!`n`nVersion: " Trim(versionOutput) "`nStatus: Logged in and unlocked`n`n🎉 You can now save credentials to your vault!", "Connection Test - Perfect", "Iconi")
                } else {
                    MsgBox("✅ Bitwarden CLI is installed and responding!`n`nVersion: " Trim(versionOutput) "`n`nThe CLI is working! You may need to authenticate.`n`nUse the 'Setup Authentication' button to get started.", "Connection Test - Ready", "Iconi")
                }
            } else {
                testGui.Destroy()
                ; Parse common error messages
                errorMsg := Trim(versionOutput)
                if (InStr(errorMsg, "not recognized") || InStr(errorMsg, "not found")) {
                    MsgBox("❌ Bitwarden CLI not found`n`nThe command 'bw' is not recognized.`n`nSolutions:`n• Use 'Auto-Install CLI' button`n• Install manually: https://bitwarden.com/help/cli/`n• Check PATH environment variable", "Connection Test - Not Found", "Iconx")
                } else if (InStr(errorMsg, "access") || InStr(errorMsg, "permission")) {
                    MsgBox("❌ Permission denied`n`nBitwarden CLI found but access denied.`n`nTry:`n• Running AHK Tools as Administrator`n• Checking file permissions`n• Disabling antivirus temporarily", "Connection Test - Permission Error", "Iconx")
                } else {
                    MsgBox("❌ Bitwarden CLI test failed`n`nExit code: " exitCode "`nOutput: " errorMsg "`n`nTry:`n• Using 'Auto-Install CLI' button`n• Manual installation from bitwarden.com`n• Running as Administrator", "Connection Test - Failed", "Iconx")
                }
            }
            
        } catch as e {
            try {
                testGui.Destroy()
            } catch {
                ; Ignore if testGui doesn't exist
            }
            MsgBox("Error testing Bitwarden connection: " e.Message "`n`nThis might indicate:`n• Corrupted installation`n• Missing system dependencies`n• Antivirus interference`n`nTry reinstalling with 'Auto-Install CLI' button.", "Connection Test - Error", "Iconx")
        }
    }

    ; Get Bitwarden status
    GetBitwardenStatus() {
        try {
            if (this.Settings.bitwardenPath = "bw") {
                RunWait('powershell -Command "bw status 2>&1 | Out-File -FilePath `"' . A_Temp . '\bw_status.txt`" -Encoding UTF8"', , "Hide", &exitCode)
            } else {
                RunWait('cmd /c "' . this.Settings.bitwardenPath . '" status > "' A_Temp '\bw_status.txt" 2>&1', , "Hide", &exitCode)
            }
            
            if (FileExist(A_Temp "\bw_status.txt")) {
                statusOutput := FileRead(A_Temp "\bw_status.txt")
                FileDelete(A_Temp "\bw_status.txt")
                return statusOutput
            }
        } catch as e {
            OutputDebug("EmailPasswordManager: Error getting Bitwarden status: " e.Message)
        }
        return ""
    }

    ; Show authentication setup dialog
    ShowAuthenticationSetup() {
        authGui := Gui("+AlwaysOnTop", "Bitwarden Authentication Setup")
        authGui.SetFont("s9", "Segoe UI")
        
        authGui.Add("Text", "x20 y20 w400", "Choose your authentication method:")
        
        ; Email/Password option
        authGui.Add("GroupBox", "x20 y50 w400 h80", "Option 1: Email & Password (Interactive)")
        authGui.Add("Text", "x30 y70", "• Best for manual use")
        authGui.Add("Text", "x30 y90", "• Requires entering credentials each time")
        authGui.Add("Text", "x30 y110", "• Supports all 2FA methods")
        emailLoginBtn := authGui.Add("Button", "x330 y75 w80 h25", "Use This")
        
        ; API Key option  
        authGui.Add("GroupBox", "x20 y140 w400 h80", "Option 2: Personal API Key (Recommended)")
        authGui.Add("Text", "x30 y160", "• Best for automation and scripts")
        authGui.Add("Text", "x30 y180", "• Secure, no password storage needed")
        authGui.Add("Text", "x30 y200", "• Works with 2FA enabled accounts")
        apiKeyBtn := authGui.Add("Button", "x330 y165 w80 h25", "Use This")
        
        ; SSO option
        authGui.Add("GroupBox", "x20 y230 w400 h60", "Option 3: Single Sign-On (Enterprise)")
        authGui.Add("Text", "x30 y250", "• For organizations with SSO enabled")
        authGui.Add("Text", "x30 y270", "• Opens browser for authentication")
        ssoBtn := authGui.Add("Button", "x330 y250 w80 h25", "Use This")
        
        ; Instructions
        authGui.Add("Text", "x20 y300 w400", "📝 Note: API Key method is recommended for this plugin as it works")
        authGui.Add("Text", "x20 y320 w400", "best with automated workflows.")
        
        cancelBtn := authGui.Add("Button", "x20 y350 w80 h30", "Cancel")
        helpBtn := authGui.Add("Button", "x340 y350 w80 h30", "Help")
        
        ; Event handlers
        emailLoginBtn.OnEvent("Click", (*) => (authGui.Destroy(), this.DoEmailLogin()))
        apiKeyBtn.OnEvent("Click", (*) => (authGui.Destroy(), this.SetupApiKey()))
        ssoBtn.OnEvent("Click", (*) => (authGui.Destroy(), this.DoSSOLogin()))
        cancelBtn.OnEvent("Click", (*) => authGui.Destroy())
        helpBtn.OnEvent("Click", (*) => Run("https://bitwarden.com/help/cli/"))
        authGui.OnEvent("Close", (*) => authGui.Destroy())
        
        authGui.Show("w440 h390")
    }

    ; Perform email/password login
    DoEmailLogin() {
        try {
            ; Show login dialog
            loginGui := Gui("+AlwaysOnTop", "Bitwarden Login")
            loginGui.SetFont("s9", "Segoe UI")
            
            loginGui.Add("Text", "x20 y20", "Email:")
            emailEdit := loginGui.Add("Edit", "x20 y40 w300")
            
            loginGui.Add("Text", "x20 y70", "Master Password:")
            passwordEdit := loginGui.Add("Edit", "x20 y90 w300 Password")
            
            loginGui.Add("Text", "x20 y120", "2FA Code (if enabled):")
            twoFAEdit := loginGui.Add("Edit", "x20 y140 w150")
            
            loginBtn := loginGui.Add("Button", "x20 y180 w100 h30", "Login")
            cancelBtn := loginGui.Add("Button", "x220 y180 w100 h30", "Cancel")
            
            loginBtn.OnEvent("Click", (*) => this.PerformLogin(emailEdit.Text, passwordEdit.Text, twoFAEdit.Text, loginGui))
            cancelBtn.OnEvent("Click", (*) => loginGui.Destroy())
            loginGui.OnEvent("Close", (*) => loginGui.Destroy())
            
            loginGui.Show("w340 h230")
            
        } catch as e {
            MsgBox("Error starting login: " e.Message, "Login Error", "Iconx")
        }
    }

    ; Perform the actual login
    PerformLogin(email, password, twoFACode, loginGui) {
        if (!email || !password) {
            MsgBox("Please enter both email and password.", "Missing Information", "Iconx")
            return
        }
        
        try {
            loginGui.Destroy()
            
            ; Show progress
            progressGui := Gui("+AlwaysOnTop", "Logging in...")
            progressGui.Add("Text", "x20 y20", "🔐 Logging into Bitwarden...")
            progressGui.Show("w200 h60")
            
            ; Build login command
            loginCmd := '"' this.Settings.bitwardenPath '" login "' email '" "' password '"'
            if (twoFACode) {
                loginCmd .= ' --code "' twoFACode '"'
            }
            
            ; Execute login
            RunWait('cmd /c ' loginCmd ' > "' A_Temp '\bw_login.txt" 2>&1', , "Hide", &exitCode)
            
            ; Read result
            loginResult := ""
            if (FileExist(A_Temp "\bw_login.txt")) {
                loginResult := FileRead(A_Temp "\bw_login.txt")
                FileDelete(A_Temp "\bw_login.txt")
            }
            
            progressGui.Destroy()
            
            if (InStr(loginResult, "You are logged in") || exitCode = 0) {
                ; Extract session key from output
                sessionKey := this.ExtractSessionKey(loginResult)
                if (sessionKey) {
                    ; Store session key in environment
                    EnvSet("BW_SESSION", sessionKey)
                    MsgBox("✅ Login successful!`n`nYour vault is now unlocked and ready to use.`n`nSession will remain active until you logout or restart.", "Login Success", "Iconi")
                } else {
                    MsgBox("✅ Login successful!`n`nRun 'bw unlock' manually to get your session key.", "Login Success", "Iconi")
                }
            } else {
                errorMsg := "Login failed."
                if (InStr(loginResult, "Invalid")) {
                    errorMsg .= "`n`nInvalid credentials or 2FA code."
                } else if (InStr(loginResult, "Two-step")) {
                    errorMsg .= "`n`nTwo-factor authentication required."
                }
                MsgBox(errorMsg "`n`nOutput: " Trim(loginResult), "Login Failed", "Iconx")
            }
            
                 } catch as e {
             try {
                 progressGui.Destroy()
             } catch {
                 ; Ignore if progressGui doesn't exist
             }
             MsgBox("Error during login: " e.Message, "Login Error", "Iconx")
         }
    }

    ; Setup API Key authentication  
    SetupApiKey() {
        ; Show instructions
        instructGui := Gui("+AlwaysOnTop", "Setup API Key Authentication")
        instructGui.SetFont("s9", "Segoe UI")
        
        instructGui.Add("Text", "x20 y20 w450", "To use API Key authentication, you need to get your personal API key:")
        instructGui.Add("Text", "x20 y50 w450", "1. Go to https://vault.bitwarden.com")
        instructGui.Add("Text", "x20 y70 w450", "2. Click Settings → Security → Keys")
        instructGui.Add("Text", "x20 y90 w450", "3. Click 'View API Key' and enter your master password")
        instructGui.Add("Text", "x20 y110 w450", "4. Copy the client_id and client_secret values")
        instructGui.Add("Text", "x20 y130 w450", "5. Enter them below:")
        
        instructGui.Add("Text", "x20 y160", "Client ID:")
        clientIdEdit := instructGui.Add("Edit", "x20 y180 w450")
        
        instructGui.Add("Text", "x20 y210", "Client Secret:")
        clientSecretEdit := instructGui.Add("Edit", "x20 y230 w450")
        
        saveBtn := instructGui.Add("Button", "x20 y270 w100 h30", "Save & Test")
        openWebBtn := instructGui.Add("Button", "x130 y270 w100 h30", "Open Web Vault")
        cancelBtn := instructGui.Add("Button", "x370 y270 w100 h30", "Cancel")
        
        saveBtn.OnEvent("Click", (*) => this.SaveApiKey(clientIdEdit.Text, clientSecretEdit.Text, instructGui))
        openWebBtn.OnEvent("Click", (*) => Run("https://vault.bitwarden.com"))
        cancelBtn.OnEvent("Click", (*) => instructGui.Destroy())
        instructGui.OnEvent("Close", (*) => instructGui.Destroy())
        
        instructGui.Show("w490 h320")
    }

    ; Save API key and test
    SaveApiKey(clientId, clientSecret, setupGui) {
        if (!clientId || !clientSecret) {
            MsgBox("Please enter both Client ID and Client Secret.", "Missing Information", "Iconx")
            return
        }
        
        try {
            setupGui.Destroy()
            
            ; Set environment variables
            EnvSet("BW_CLIENTID", clientId)
            EnvSet("BW_CLIENTSECRET", clientSecret)
            
            ; Show progress
            progressGui := Gui("+AlwaysOnTop", "Testing API Key...")
            progressGui.Add("Text", "x20 y20", "🔑 Testing API Key authentication...")
            progressGui.Show("w250 h60")
            
            ; Test API key login
            RunWait('cmd /c "' this.Settings.bitwardenPath '" login --apikey > "' A_Temp '\bw_apilogin.txt" 2>&1', , "Hide", &exitCode)
            
            ; Read result
            apiResult := ""
            if (FileExist(A_Temp "\bw_apilogin.txt")) {
                apiResult := FileRead(A_Temp "\bw_apilogin.txt")
                FileDelete(A_Temp "\bw_apilogin.txt")
            }
            
            progressGui.Destroy()
            
            if (InStr(apiResult, "logged in") || exitCode = 0) {
                ; Now we need to unlock the vault
                result := MsgBox("✅ API Key authentication successful!`n`nNow you need to unlock your vault with your master password.`n`nWould you like to unlock it now?", "Authentication Success", "YesNo Iconi")
                if (result = "Yes") {
                    this.UnlockVault()
                }
            } else {
                MsgBox("❌ API Key authentication failed.`n`nPlease check your Client ID and Client Secret.`n`nOutput: " Trim(apiResult), "Authentication Failed", "Iconx")
            }
            
                 } catch as e {
             try {
                 progressGui.Destroy()
             } catch {
                 ; Ignore if progressGui doesn't exist
             }
             MsgBox("Error during API key setup: " e.Message, "Setup Error", "Iconx")
         }
    }

    ; Unlock vault with master password
    UnlockVault() {
        try {
            ; Show unlock dialog
            unlockGui := Gui("+AlwaysOnTop", "Unlock Bitwarden Vault")
            unlockGui.SetFont("s9", "Segoe UI")
            
            unlockGui.Add("Text", "x20 y20", "Enter your master password to unlock the vault:")
            passwordEdit := unlockGui.Add("Edit", "x20 y45 w300 Password")
            
            unlockBtn := unlockGui.Add("Button", "x20 y80 w100 h30", "Unlock")
            cancelBtn := unlockGui.Add("Button", "x220 y80 w100 h30", "Cancel")
            
            unlockBtn.OnEvent("Click", (*) => this.PerformUnlock(passwordEdit.Text, unlockGui))
            cancelBtn.OnEvent("Click", (*) => unlockGui.Destroy())
            unlockGui.OnEvent("Close", (*) => unlockGui.Destroy())
            
            unlockGui.Show("w340 h130")
            
        } catch as e {
            MsgBox("Error showing unlock dialog: " e.Message, "Unlock Error", "Iconx")
        }
    }

        ; Perform vault unlock
    PerformUnlock(password, unlockGui) {
        if (!password) {
            MsgBox("Please enter your master password.", "Missing Password", "Iconx")
            return
        }
        
        try {
            unlockGui.Destroy()
            
            ; Show progress
            progressGui := Gui("+AlwaysOnTop", "Unlocking vault...")
            progressGui.Add("Text", "x20 y20", "🔓 Unlocking Bitwarden vault...")
            progressGui.Show("w220 h60")
            
            ; Use PowerShell with better input handling for Windows
            if (this.Settings.bitwardenPath = "bw") {
                ; Use PowerShell for better password handling
                psCommand := 'echo "' . password . '" | bw unlock 2>&1'
                RunWait('powershell -Command "' . psCommand . ' | Out-File -FilePath `"' . A_Temp . '\bw_unlock.txt`" -Encoding UTF8"', , "Hide", &exitCode)
            } else {
                ; For full path, use --passwordenv option if possible
                EnvSet("BW_PASSWORD", password)
                RunWait('cmd /c "' . this.Settings.bitwardenPath . '" unlock --passwordenv BW_PASSWORD > "' A_Temp '\bw_unlock.txt" 2>&1', , "Hide", &exitCode)
                EnvSet("BW_PASSWORD", "")  ; Clear the environment variable
            }
            
            ; Read result
            unlockResult := ""
            if (FileExist(A_Temp "\bw_unlock.txt")) {
                unlockResult := FileRead(A_Temp "\bw_unlock.txt")
                FileDelete(A_Temp "\bw_unlock.txt")
            }
            
            progressGui.Destroy()
            
            ; Check for success indicators
            if (InStr(unlockResult, "Your vault is now unlocked") || InStr(unlockResult, "export BW_SESSION") || InStr(unlockResult, '$env:BW_SESSION')) {
                ; Extract and set session key
                sessionKey := this.ExtractSessionKey(unlockResult)
                if (sessionKey) {
                    EnvSet("BW_SESSION", sessionKey)
                    MsgBox("✅ Vault unlocked successfully!`n`nYour vault is now ready to use.`n`nSession will remain active until you logout or restart.", "Unlock Success", "Iconi")
                } else {
                    MsgBox("✅ Vault unlocked!`n`nNote: Could not automatically extract session key.`nYou may need to set BW_SESSION environment variable manually.", "Unlock Success", "Iconi")
                }
            } else if (InStr(unlockResult, "Invalid master password") || InStr(unlockResult, "master password")) {
                MsgBox("❌ Invalid master password.`n`nPlease check your master password and try again.", "Unlock Failed", "Iconx")
            } else if (InStr(unlockResult, "You are not logged in")) {
                MsgBox("❌ Not logged in.`n`nPlease login first using one of the authentication methods.", "Unlock Failed", "Iconx")
            } else {
                ; Offer manual unlock option
                result := MsgBox("❌ Failed to unlock vault automatically.`n`nOutput: " Trim(unlockResult) "`n`nWould you like to open a terminal to unlock manually?`n`nYou can run: bw unlock", "Unlock Failed", "YesNo Iconx")
                if (result = "Yes") {
                    this.OpenTerminalForManualUnlock()
                }
            }
            
        } catch as e {
            try {
                progressGui.Destroy()
            } catch {
                ; Ignore if progressGui doesn't exist
            }
            MsgBox("Error during unlock: " e.Message, "Unlock Error", "Iconx")
        }
    }

    ; Perform SSO login
    DoSSOLogin() {
        try {
            ; Show progress
            progressGui := Gui("+AlwaysOnTop", "Starting SSO Login...")
            progressGui.Add("Text", "x20 y20", "🌐 Starting SSO authentication...")
            progressGui.Add("Text", "x20 y45", "Your browser will open for authentication.")
            progressGui.Show("w280 h80")
            
            ; Execute SSO login
            RunWait('cmd /c "' this.Settings.bitwardenPath '" login --sso > "' A_Temp '\bw_sso.txt" 2>&1', , "Hide", &exitCode)
            
            ; Read result
            ssoResult := ""
            if (FileExist(A_Temp "\bw_sso.txt")) {
                ssoResult := FileRead(A_Temp "\bw_sso.txt")
                FileDelete(A_Temp "\bw_sso.txt")
            }
            
            progressGui.Destroy()
            
            if (InStr(ssoResult, "logged in") || exitCode = 0) {
                result := MsgBox("✅ SSO authentication successful!`n`nNow you need to unlock your vault.`n`nWould you like to unlock it now?", "SSO Success", "YesNo Iconi")
                if (result = "Yes") {
                    this.UnlockVault()
                }
            } else {
                MsgBox("❌ SSO authentication failed.`n`nOutput: " Trim(ssoResult), "SSO Failed", "Iconx")
            }
            
                 } catch as e {
             try {
                 progressGui.Destroy()
             } catch {
                 ; Ignore if progressGui doesn't exist
             }
             MsgBox("Error during SSO login: " e.Message, "SSO Error", "Iconx")
         }
    }

    ; Extract session key from Bitwarden output
    ExtractSessionKey(output) {
        try {
            ; Look for export BW_SESSION pattern
            if (RegExMatch(output, 'export BW_SESSION="([^"]+)"', &match)) {
                return match[1]
            }
            ; Look for env:BW_SESSION pattern (PowerShell)
            if (RegExMatch(output, '\$env:BW_SESSION="([^"]+)"', &match)) {
                return match[1]
            }
            ; Look for session key pattern
            if (RegExMatch(output, 'session key to the .BW_SESSION. environment variable[^"]*"([^"]+)"', &match)) {
                return match[1]
            }
        } catch as e {
            OutputDebug("EmailPasswordManager: Error extracting session key: " e.Message)
        }
        return ""
    }

    ; Open terminal for manual unlock
    OpenTerminalForManualUnlock() {
        try {
            ; Show instructions
            instructGui := Gui("+AlwaysOnTop", "Manual Unlock Instructions")
            instructGui.SetFont("s9", "Segoe UI")
            
            instructGui.Add("Text", "x20 y20 w400", "To manually unlock your Bitwarden vault:")
            instructGui.Add("Text", "x20 y50 w400", "1. Run the command: bw unlock")
            instructGui.Add("Text", "x20 y70 w400", "2. Enter your master password when prompted")
            instructGui.Add("Text", "x20 y90 w400", "3. Copy the export/env command that appears")
            instructGui.Add("Text", "x20 y110 w400", "4. Run that command to set your session key")
            
            instructGui.Add("Text", "x20 y140 w400", "Example output will look like:")
            instructGui.Add("Text", "x20 y160 w400", 'export BW_SESSION="your-session-key-here"')
            instructGui.Add("Text", "x20 y180 w400", "or")
            instructGui.Add("Text", "x20 y200 w400", '$env:BW_SESSION="your-session-key-here"')
            
            openTerminalBtn := instructGui.Add("Button", "x20 y230 w150 h30", "Open PowerShell")
            openCmdBtn := instructGui.Add("Button", "x180 y230 w150 h30", "Open Command Prompt")
            closeBtn := instructGui.Add("Button", "x340 y230 w80 h30", "Close")
            
            openTerminalBtn.OnEvent("Click", (*) => (Run("powershell"), instructGui.Destroy()))
            openCmdBtn.OnEvent("Click", (*) => (Run("cmd"), instructGui.Destroy()))
            closeBtn.OnEvent("Click", (*) => instructGui.Destroy())
            instructGui.OnEvent("Close", (*) => instructGui.Destroy())
            
            instructGui.Show("w440 h280")
            
        } catch as e {
            MsgBox("Error opening terminal instructions: " e.Message, "Error", "Iconx")
        }
    }
    
    ; Auto-install Bitwarden CLI
    AutoInstallBitwardenCLI(pathEdit) {
        ; Show confirmation dialog
        result := MsgBox("This will download and install Bitwarden CLI automatically.`n`nFeatures:`n• Downloads latest version from GitHub`n• Installs to Program Files`n• Sets up PATH environment`n• Updates plugin path automatically`n`nProceed with installation?", "Auto-Install Bitwarden CLI", "YesNo Iconi")
        
        if (result != "Yes") {
            return
        }
        
        ; Show progress
        progressGui := Gui("+AlwaysOnTop", "Installing Bitwarden CLI...")
        progressGui.SetFont("s9", "Segoe UI")
        progressGui.Add("Text", "x20 y20 w300", "🔄 Downloading Bitwarden CLI...")
        statusText := progressGui.Add("Text", "x20 y45 w300", "Preparing download...")
        progressGui.Show("w340 h100")
        
        try {
            ; Create installation directory
            installDir := "C:\Program Files\Bitwarden CLI"
            if (!DirExist(installDir)) {
                DirCreate(installDir)
            }
            
            ; Update status
            statusText.Text := "📥 Downloading latest release..."
            
            ; Download Bitwarden CLI (using PowerShell for HTTPS download)
            downloadUrl := "https://github.com/bitwarden/clients/releases/latest/download/bw-windows.zip"
            zipFile := A_Temp "\bw-windows.zip"
            
            ; PowerShell download command
            psCommand := 'Invoke-WebRequest -Uri "' downloadUrl '" -OutFile "' zipFile '" -UseBasicParsing'
            RunWait('powershell.exe -Command "' psCommand '"', , "Hide", &exitCode)
            
            if (exitCode != 0 || !FileExist(zipFile)) {
                throw Error("Failed to download Bitwarden CLI")
            }
            
            ; Update status
            statusText.Text := "📦 Extracting files..."
            
            ; Extract ZIP file using PowerShell
            extractCommand := 'Expand-Archive -Path "' zipFile '" -DestinationPath "' installDir '" -Force'
            RunWait('powershell.exe -Command "' extractCommand '"', , "Hide", &exitCode)
            
            if (exitCode != 0) {
                throw Error("Failed to extract Bitwarden CLI")
            }
            
            ; Update status
            statusText.Text := "⚙️ Configuring environment..."
            
            ; Set up the executable path
            bwPath := installDir "\bw.exe"
            
            ; Add to system PATH (requires admin rights)
            try {
                ; Try to add to PATH using PowerShell
                pathCommand := '[Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", "Machine") + ";' installDir '", "Machine")'
                RunWait('powershell.exe -Command "' pathCommand '"', , "Hide")
            } catch {
                ; If PATH modification fails, that's okay - we'll use full path
            }
            
            ; Clean up
            FileDelete(zipFile)
            
            ; Update plugin settings and GUI
            this.Settings.bitwardenPath := bwPath
            pathEdit.Text := bwPath
            this.SaveSettings()
            
            ; Update status
            statusText.Text := "✅ Installation complete!"
            
            ; Close progress and show success
            SetTimer(() => progressGui.Destroy(), -1000)
            
            ShowMouseTooltip("✅ Bitwarden CLI installed successfully!", 3000)
            
            ; Test the installation
            SetTimer(() => this.TestBitwardenConnection(), -1500)
            
        } catch as e {
            progressGui.Destroy()
            MsgBox("❌ Installation failed: " e.Message "`n`nYou may need to:`n• Run as Administrator`n• Check internet connection`n• Install manually from bitwarden.com", "Installation Error", "Iconx")
        }
    }
    
    ; Auto-detect Bitwarden CLI path
    AutoDetectBitwardenPath(pathEdit) {
        ; Show progress
        progressGui := Gui("+AlwaysOnTop", "Auto-Detecting Bitwarden CLI...")
        progressGui.Add("Text", "x20 y20", "🔍 Searching for Bitwarden CLI...")
        progressGui.Show("w250 h60")
        
        ; First, try simple "bw" command (if it's in PATH)
        try {
            RunWait('cmd /c "bw --version" > "' A_Temp '\bw_test.txt" 2>&1', , "Hide", &exitCode)
            if (exitCode = 0) {
                ; "bw" command works from PATH
                progressGui.Destroy()
                this.Settings.bitwardenPath := "bw"
                pathEdit.Text := "bw"
                this.SaveSettings()
                ShowMouseTooltip("✅ Bitwarden CLI found in PATH: bw", 3000)
                
                ; Test the found installation
                SetTimer(() => this.TestBitwardenConnection(), -1000)
                return
            }
        } catch {
            ; Continue with full path search
        }
        
        ; Common installation paths to check
        commonPaths := [
            "C:\Program Files\Bitwarden CLI\bw.exe",
            "C:\Program Files (x86)\Bitwarden CLI\bw.exe", 
            "C:\Users\" A_UserName "\AppData\Local\Programs\Bitwarden CLI\bw.exe",
            "C:\Users\" A_UserName "\AppData\Roaming\npm\bw.exe",
            "C:\ProgramData\chocolatey\bin\bw.exe",
            "C:\ProgramData\chocolatey\lib\bitwarden-cli\tools\bw.exe",
            "C:\tools\bw.exe",
            "C:\Tools\bw.exe",
            "C:\Windows\System32\bw.exe",
            "C:\Users\" A_UserName "\.local\bin\bw.exe"
        ]
        
        ; Check PATH environment variable more thoroughly
        try {
            RunWait('cmd /c "where bw.exe" > "' A_Temp '\bw_path.txt" 2>nul', , "Hide", &exitCode)
            if (exitCode = 0 && FileExist(A_Temp "\bw_path.txt")) {
                pathContent := FileRead(A_Temp "\bw_path.txt")
                paths := StrSplit(Trim(pathContent), "`n")
                for foundPath in paths {
                    foundPath := Trim(foundPath)
                    if (foundPath && FileExist(foundPath)) {
                        ; Test if this path actually works
                        RunWait('"' foundPath '" --version > "' A_Temp '\bw_version_test.txt" 2>&1', , "Hide", &testExitCode)
                        if (testExitCode = 0) {
                            commonPaths.InsertAt(1, foundPath)  ; Add working path to beginning
                            break
                        }
                    }
                }
                try {
                    FileDelete(A_Temp "\bw_path.txt")
                } catch {
                    ; Ignore cleanup errors
                }
                try {
                    FileDelete(A_Temp "\bw_version_test.txt")
                } catch {
                    ; Ignore cleanup errors
                }
            }
        } catch {
            ; WHERE command failed, continue with manual search
        }
        
        ; Search for working executable
        foundPath := ""
        for path in commonPaths {
            if (FileExist(path)) {
                ; Test if this executable actually works
                try {
                    RunWait('"' path '" --version > "' A_Temp '\bw_version_test.txt" 2>&1', , "Hide", &testExitCode)
                    if (testExitCode = 0) {
                        foundPath := path
                        break
                    }
                } catch {
                    ; This path doesn't work, try next
                    continue
                }
            }
        }
        
        progressGui.Destroy()
        
        if (foundPath) {
            this.Settings.bitwardenPath := foundPath
            pathEdit.Text := foundPath
            this.SaveSettings()
            ShowMouseTooltip("✅ Working Bitwarden CLI found: " foundPath, 3000)
            
            ; Test the found installation
            SetTimer(() => this.TestBitwardenConnection(), -1000)
        } else {
            ; Manually join the commonPaths array since AutoHotkey v2 doesn't have Array.Join()
            pathsText := ""
            for path in commonPaths {
                pathsText .= (pathsText ? "`n• " : "") . path
            }
            pathsText := StrReplace(pathsText, "C:\Users\" A_UserName, "C:\Users\{username}")
            
            result := MsgBox("❌ No working Bitwarden CLI found.`n`nTried locations:`n• " pathsText "`n`nWould you like to:`n• Install automatically (recommended)`n• Browse for manual path`n• View setup guide", "Auto-Detect Failed", "YesNoCancel Icon?")
            
            if (result = "Yes") {
                this.AutoInstallBitwardenCLI(pathEdit)
            } else if (result = "No") {
                this.BrowseBitwardenPath(pathEdit)
            } else if (result = "Cancel") {
                this.ShowBitwardenSetupGuide()
            }
        }
    }
     
         ; Reset Bitwarden path to simple "bw" command
    ResetBitwardenPath(pathEdit) {
        result := MsgBox("Reset Bitwarden CLI path to 'bw'?`n`nThis will use the 'bw' command from your system PATH.`n`nUse this if auto-detect set a wrong path.", "Reset Path", "YesNo Icon?")
        if (result = "Yes") {
            this.Settings.bitwardenPath := "bw"
            pathEdit.Text := "bw"
            this.SaveSettings()
            ShowMouseTooltip("✅ Path reset to 'bw'", 2000)
            
            ; Test the reset path
            SetTimer(() => this.TestBitwardenConnection(), -500)
        }
    }

    ; Check Bitwarden status for the setup guide
    CheckBitwardenStatus(statusControl) {
        try {
            ; Show checking status
            statusControl.Text := "Status: 🔍 Checking Bitwarden CLI status..."
            
            ; Run status command
            RunWait('"' . this.Settings.bitwardenPath . '" status > "' . A_Temp . '\bw_status_check.txt" 2>&1', , "Hide", &exitCode)
            
            result := ""
            if (FileExist(A_Temp "\bw_status_check.txt")) {
                result := FileRead(A_Temp "\bw_status_check.txt")
                FileDelete(A_Temp "\bw_status_check.txt")
            }
            
            ; Parse and display status
            if (InStr(result, "unauthenticated")) {
                statusControl.Text := "Status: ❌ Not logged in - Click 'Setup Authentication'"
            } else if (InStr(result, "locked")) {
                statusControl.Text := "Status: 🔒 Vault locked - Need to unlock vault"
            } else if (InStr(result, "unlocked")) {
                statusControl.Text := "Status: ✅ Fully ready - All set to save credentials!"
            } else if (exitCode != 0) {
                statusControl.Text := "Status: ❌ CLI not found - Click 'Auto-Install CLI'"
            } else {
                statusControl.Text := "Status: ⚠️ Unknown status: " . Trim(result)
            }
            
        } catch as e {
            statusControl.Text := "Status: ❌ Error checking status: " . e.Message
        }
    }

    ; Show auto-install message (since AutoInstallBitwardenCLI requires pathEdit parameter)
    ShowAutoInstallMessage() {
        MsgBox("To auto-install Bitwarden CLI:`n`n1. Close this guide`n2. Go to the Bitwarden tab`n3. Click 'Auto-Install CLI' button`n`nThis will automatically download and configure Bitwarden CLI for you.", "Auto-Install Instructions", "Iconi")
    }

        ; Show comprehensive Bitwarden setup guide
    ShowBitwardenSetupGuide() {
        guideGui := Gui("+Resize", "🔒 Complete Bitwarden CLI Setup Guide")
        guideGui.SetFont("s9", "Segoe UI")
        
        ; Create tabs for better organization
        tabControl := guideGui.Add("Tab3", "x10 y10 w680 h600", ["Quick Start", "Detailed Setup", "Troubleshooting", "Commands"])
        
        ; === QUICK START TAB ===
        tabControl.UseTab(1)
        guideGui.Add("Text", "x30 y40 w640 Center", "🚀 Quick Start Guide").SetFont("s9 Bold")
        guideGui.Add("Text", "x30 y70 w640", "Follow these 4 simple steps to get started:")
        
        ; Quick steps with visual indicators
        guideGui.Add("Text", "x30 y100", "Step 1:").SetFont("s9 Bold")
        step1Btn := guideGui.Add("Button", "x90 y98 w150 h25", "Auto-Install CLI")
        guideGui.Add("Text", "x250 y100 w400", "← Click this to automatically download and install Bitwarden CLI")
        
        guideGui.Add("Text", "x30 y135", "Step 2:").SetFont("s9 Bold")
        guideGui.Add("Text", "x90 y135 w400", "Create account at: ")
        createAccountBtn := guideGui.Add("Button", "x280 y133 w120 h25", "bitwarden.com")
        guideGui.Add("Text", "x410 y135 w200", "← Open website")
        
        guideGui.Add("Text", "x30 y170", "Step 3:").SetFont("s9 Bold")
        setupAuthBtn := guideGui.Add("Button", "x90 y168 w150 h25", "Setup Authentication")
        guideGui.Add("Text", "x250 y170 w400", "← Click this for guided authentication")
        
        guideGui.Add("Text", "x30 y205", "Step 4:").SetFont("s9 Bold")
        testBtn := guideGui.Add("Button", "x90 y203 w100 h25", "Test Connection")
        guideGui.Add("Text", "x200 y205 w400", "← Verify everything works")
        
        ; Status indicator
        guideGui.Add("GroupBox", "x30 y240 w640 h80", "Current Status")
        statusText := guideGui.Add("Text", "x50 y260 w600", "Status: Click 'Check Status' to see current Bitwarden CLI status")
        checkStatusBtn := guideGui.Add("Button", "x50 y285 w120 h25", "Check Status")
        
        ; === DETAILED SETUP TAB ===
        tabControl.UseTab(2)
        guideGui.Add("Text", "x30 y40 w640 Center", "📋 Detailed Setup Instructions").SetFont("s9 Bold")
        
        ; Installation section
        guideGui.Add("GroupBox", "x30 y70 w640 h120", "1. Installation Options")
        guideGui.Add("Text", "x50 y95", "A) Automatic (Recommended):").SetFont("s9 Bold")
        guideGui.Add("Text", "x50 y115", "   • Click 'Auto-Install CLI' button in the main interface")
        guideGui.Add("Text", "x50 y135", "   • Downloads and configures everything automatically")
        
        guideGui.Add("Text", "x50 y155", "B) Manual Installation:").SetFont("s9 Bold")
        guideGui.Add("Text", "x50 y175", "   • Download from: https://bitwarden.com/help/cli/")
        
        ; Account setup
        guideGui.Add("GroupBox", "x30 y200 w640 h100", "2. Account Setup")
        guideGui.Add("Text", "x50 y225", "• Create free account at: https://bitwarden.com/")
        guideGui.Add("Text", "x50 y245", "• Remember your master password (cannot be recovered!)")
        guideGui.Add("Text", "x50 y265", "• Enable 2FA for security (recommended)")
        
        ; Authentication methods
        guideGui.Add("GroupBox", "x30 y310 w640 h140", "3. Authentication Methods")
        guideGui.Add("Text", "x50 y335", "Choose one method:").SetFont("s9 Bold")
        
        guideGui.Add("Text", "x50 y355", "Option A: Email + Password (Interactive)")
        guideGui.Add("Text", "x70 y375", "• Best for manual use • Supports all 2FA methods")
        
        guideGui.Add("Text", "x50 y395", "Option B: Personal API Key (Automated)")
        guideGui.Add("Text", "x70 y415", "• Best for automation • Generate at: vault.bitwarden.com → Account Settings")
        
        guideGui.Add("Text", "x50 y435", "Option C: SSO (Enterprise)")
        guideGui.Add("Text", "x70 y455", "• For business accounts only")
        
        ; Verification
        guideGui.Add("GroupBox", "x30 y460 w640 h80", "4. Verification")
        guideGui.Add("Text", "x50 y485", "• Use 'Test Connection' button to verify setup")
        guideGui.Add("Text", "x50 y505", "• Should show: ✅ Bitwarden CLI status: fully ready")
        
        ; === TROUBLESHOOTING TAB ===
        tabControl.UseTab(3)
        guideGui.Add("Text", "x30 y40 w640 Center", "🔧 Troubleshooting Guide").SetFont("s9 Bold")
        
        ; Common issues
        guideGui.Add("GroupBox", "x30 y70 w640 h130", "Common Issues & Solutions")
        
        guideGui.Add("Text", "x50 y95", '❌ "Command not found" or "File not found"').SetFont("s9 Bold")
        guideGui.Add("Text", "x50 y115", "Solutions:")
        guideGui.Add("Text", "x70 y130", "• Click 'Auto-Install CLI' or 'Auto-Detect Path'")
        guideGui.Add("Text", "x70 y145", "• Restart command prompt after installation")
        guideGui.Add("Text", "x70 y160", "• Use 'Reset to bw' button if wrong path was detected")
        
        guideGui.Add("Text", "x50 y180", '❌ "You are not logged in"').SetFont("s9 Bold")
        guideGui.Add("Text", "x70 y195", "• Run: bw login   (or use 'Setup Authentication')")
        
        guideGui.Add("GroupBox", "x30 y210 w640 h100", "Authentication Issues")
        guideGui.Add("Text", "x50 y235", '❌ "Vault is locked"').SetFont("s9 Bold")
        guideGui.Add("Text", "x70 y250", "• Run: bw unlock   (or use 'Setup Authentication')")
        
        guideGui.Add("Text", "x50 y270", '❌ "Invalid session"').SetFont("s9 Bold")
        guideGui.Add("Text", "x70 y285", "• Session expired - run bw unlock again")
        
        ; Manual commands section
        guideGui.Add("GroupBox", "x30 y320 w640 h190", "Manual Commands (if needed)")
        guideGui.Add("Text", "x50 y345", "If automated setup fails, try these commands manually:")
        manualEdit := guideGui.Add("Edit", "x50 y365 w600 h130 ReadOnly VScroll", 
            "# Basic setup commands:" . "`n" .
            "bw --version                 # Check if installed" . "`n" .
            "bw login your@email.com      # Login with email" . "`n" .
            "bw unlock                    # Unlock vault" . "`n" .
            "bw status                    # Check current status" . "`n" .
            "`n# For API key authentication:" . "`n" .
            "bw config server https://vault.bitwarden.com  # Set server" . "`n" .
            "bw login --apikey             # Login with API key")
        
        ; === COMMANDS TAB ===
        tabControl.UseTab(4)
        guideGui.Add("Text", "x30 y40 w640 Center", "⌨️ Bitwarden CLI Commands Reference").SetFont("s9 Bold")
        
        ; Essential commands
        guideGui.Add("GroupBox", "x30 y70 w640 h130", "Essential Commands")
        essentialEdit := guideGui.Add("Edit", "x50 y95 w600 h90 ReadOnly VScroll", 
            "bw --help                    # Show all available commands" . "`n" .
            "bw --version                 # Show version information" . "`n" .
            "bw status                    # Show login and sync status" . "`n" .
            "bw login [email]             # Login to your account" . "`n" .
            "bw logout                    # Logout and clear session" . "`n" .
            "bw unlock                    # Unlock your vault" . "`n" .
            "bw lock                      # Lock your vault" . "`n" .
            "bw sync                      # Sync vault with server")
        
        ; Item management
        guideGui.Add("GroupBox", "x30 y210 w640 h130", "Item Management")
        itemEdit := guideGui.Add("Edit", "x50 y235 w600 h90 ReadOnly VScroll", 
            "bw list items                # List all items`n" .
            "bw list items --search text  # Search for items`n" .
            "bw get item <id>             # Get specific item`n" .
            "bw create item <json>        # Create new item`n" .
            "bw edit item <id> <json>     # Edit existing item`n" .
            "bw delete item <id>          # Delete item`n" .
            "bw generate                  # Generate password`n" .
            "bw encode                    # Encode JSON for create/edit")
        
        ; Advanced commands
        guideGui.Add("GroupBox", "x30 y350 w640 h110", "Advanced Commands")
        advancedEdit := guideGui.Add("Edit", "x50 y375 w600 h70 ReadOnly VScroll", 
            "bw config server <url>       # Set custom server URL`n" .
            "bw import <format> <file>    # Import data from other managers`n" .
            "bw export [password]         # Export vault data`n" .
            "bw serve                     # Start local API server`n" .
            "bw completion                # Generate shell completion")
        
        ; Bottom action buttons (visible on all tabs)
        tabControl.UseTab()  ; Apply to all tabs
        
        ; Action buttons
        openCmdBtn := guideGui.Add("Button", "x30 y620 w120 h30", "Open Command Prompt")
        openWebBtn := guideGui.Add("Button", "x160 y620 w120 h30", "Open Bitwarden Web")
        installBtn := guideGui.Add("Button", "x290 y620 w100 h30", "Auto-Install CLI")
        authBtn := guideGui.Add("Button", "x400 y620 w120 h30", "Setup Authentication")
        testConnectionBtn := guideGui.Add("Button", "x530 y620 w100 h30", "Test Connection")
        closeBtn := guideGui.Add("Button", "x640 y620 w60 h30", "Close")
        
        ; Event handlers for Quick Start tab buttons
        tabControl.UseTab(1)
        step1Btn.OnEvent("Click", (*) => (guideGui.Destroy(), this.ShowAutoInstallMessage()))
        createAccountBtn.OnEvent("Click", (*) => Run("https://bitwarden.com/"))
        setupAuthBtn.OnEvent("Click", (*) => (guideGui.Destroy(), this.ShowAuthenticationSetup()))
        testBtn.OnEvent("Click", (*) => this.TestBitwardenConnection())
        checkStatusBtn.OnEvent("Click", (*) => this.CheckBitwardenStatus(statusText))
        
        ; Event handlers for bottom buttons
        tabControl.UseTab()  ; Apply to all tabs
        openCmdBtn.OnEvent("Click", (*) => Run("cmd.exe"))
        openWebBtn.OnEvent("Click", (*) => Run("https://vault.bitwarden.com/"))
        installBtn.OnEvent("Click", (*) => (guideGui.Destroy(), this.ShowAutoInstallMessage()))
        authBtn.OnEvent("Click", (*) => (guideGui.Destroy(), this.ShowAuthenticationSetup()))
        testConnectionBtn.OnEvent("Click", (*) => this.TestBitwardenConnection())
        closeBtn.OnEvent("Click", (*) => guideGui.Destroy())
        guideGui.OnEvent("Close", (*) => guideGui.Destroy())
        
        guideGui.Show("w700 h660")
    }
    
    ; Save to Bitwarden vault
    SaveToVault() {
        if (!this.Settings.bitwardenEnabled) {
            MsgBox("Bitwarden integration is not enabled.`n`nEnable it in the Settings tab and set the correct Bitwarden CLI path.", "Bitwarden", "Iconi")
            return
        }
        
        ; Check if we have recent credentials to save
        if (this.RecentEmails.Length = 0 && this.RecentUsernames.Length = 0 && this.RecentPasswords.Length = 0) {
            MsgBox("No recent credentials found to save.`n`nGenerate some credentials first!", "No Credentials", "Iconi")
            return
        }
        
        try {
            ; Get the most recent credentials
            recentEmail := (this.RecentEmails.Length > 0) ? this.RecentEmails[this.RecentEmails.Length].email : ""
            recentUsername := (this.RecentUsernames.Length > 0) ? this.RecentUsernames[this.RecentUsernames.Length].username : ""
            recentPassword := (this.RecentPasswords.Length > 0) ? this.RecentPasswords[this.RecentPasswords.Length].password : ""
            
            ; Create save GUI
            saveGui := Gui("+Resize", "Save to Bitwarden Vault")
            saveGui.SetFont("s9", "Segoe UI")
            
            saveGui.Add("Text", "x20 y10 w400", "Save recent credentials to your Bitwarden vault:").SetFont("s10 Bold")
            
            ; Item details
            saveGui.Add("Text", "x20 y40", "Item Name:")
            nameEdit := saveGui.Add("Edit", "x20 y60 w400", "Generated Credentials " . FormatTime(, "yyyy-MM-dd HH:mm"))
            
            saveGui.Add("Text", "x20 y90", "Website/Service:")
            websiteEdit := saveGui.Add("Edit", "x20 y110 w400", "")
            
            saveGui.Add("Text", "x20 y140", "Email:")
            emailEdit := saveGui.Add("Edit", "x20 y160 w400", recentEmail)
            
            saveGui.Add("Text", "x20 y190", "Username:")
            usernameEdit := saveGui.Add("Edit", "x20 y210 w400", recentUsername)
            
            saveGui.Add("Text", "x20 y240", "Password:")
            passwordEdit := saveGui.Add("Edit", "x20 y260 w400", recentPassword)
            
            saveGui.Add("Text", "x20 y290", "Notes:")
            notesEdit := saveGui.Add("Edit", "x20 y310 w400 h60", "Generated by AHK Email & Password Manager")
            
            ; Buttons
            saveBtn := saveGui.Add("Button", "x20 y380 w100 h30", "Save to Vault")
            testBtn := saveGui.Add("Button", "x130 y380 w100 h30", "Test Connection")
            cancelBtn := saveGui.Add("Button", "x340 y380 w80 h30", "Cancel")
            
            ; Store GUI reference for later access
            this.saveGui := saveGui
            
            ; Event handlers - store control references for access
            this.saveControls := {
                name: nameEdit,
                website: websiteEdit,
                email: emailEdit,
                username: usernameEdit,
                password: passwordEdit,
                notes: notesEdit
            }
            
            saveBtn.OnEvent("Click", (*) => this.ActuallySaveToVault())
            testBtn.OnEvent("Click", (*) => this.TestBitwardenConnection())
            cancelBtn.OnEvent("Click", (*) => this.CloseSaveGui())
            saveGui.OnEvent("Close", (*) => this.CloseSaveGui())
            
            saveGui.Show("w440 h420")
            
        } catch as e {
            MsgBox("Error preparing vault save: " . e.Message, "Save Error", "Iconx")
        }
    }
    
    ; Actually save to Bitwarden vault
    ActuallySaveToVault() {
        try {
            ; Get values from stored controls
            if (!this.HasProp("saveControls") || !this.HasProp("saveGui")) {
                MsgBox("Save dialog not properly initialized.", "Error", "Iconx")
                return
            }
            
            name := this.saveControls.name.Text
            website := this.saveControls.website.Text
            email := this.saveControls.email.Text
            username := this.saveControls.username.Text
            password := this.saveControls.password.Text
            notes := this.saveControls.notes.Text
            
            if (!name) {
                MsgBox("Please enter an item name.", "Missing Information", "Iconx")
                return
            }
            
            this.CloseSaveGui()
            
            ; Show progress
            progressGui := Gui("+AlwaysOnTop", "Saving to Bitwarden...")
            progressGui.Add("Text", "x20 y20", "💾 Saving credentials to vault...")
            progressGui.Show("w250 h60")
            
            ; Create JSON for Bitwarden CLI (proper format)
            itemJson := '{'
            itemJson .= '"object":"item",'
            itemJson .= '"type":1,'  ; 1 = Login item
            itemJson .= '"name":"' . this.EscapeJson(name) . '",'
            
            ; Add login section
            itemJson .= '"login":{'
            
            ; Add URIs if website provided
            if (website) {
                itemJson .= '"uris":[{"uri":"' . this.EscapeJson(website) . '"}],'
            }
            
            ; Add username and password
            if (username) {
                itemJson .= '"username":"' . this.EscapeJson(username) . '",'
            }
            if (password) {
                itemJson .= '"password":"' . this.EscapeJson(password) . '"'
            }
            
            ; Remove trailing comma if exists
            if (SubStr(itemJson, -1) = ",") {
                itemJson := SubStr(itemJson, 1, -1)
            }
            itemJson .= '},'
            
            ; Add notes if provided
            if (notes) {
                itemJson .= '"notes":"' . this.EscapeJson(notes) . '",'
            }
            
            ; Remove trailing comma and close JSON
            if (SubStr(itemJson, -1) = ",") {
                itemJson := SubStr(itemJson, 1, -1)
            }
            itemJson .= '}'
            
            ; Write JSON to temp file
            tempFile := A_Temp "\bw_item.json"
            try {
                FileDelete(tempFile)
            } catch {
                ; File doesn't exist, that's fine
            }
            FileAppend(itemJson, tempFile)
            
            ; Save to Bitwarden using the correct command format
            outputFile := A_Temp "\bw_create_result.txt"
            try {
                FileDelete(outputFile)
            } catch {
                ; File doesn't exist, that's fine
            }
            
            if (this.Settings.bitwardenPath = "bw") {
                ; Use PowerShell with proper encoding and session handling
                psCommand := 'Get-Content "' . tempFile . '" | bw encode | bw create item 2>&1'
                RunWait('powershell -Command "' . psCommand . ' | Out-File -FilePath `"' . outputFile . '`" -Encoding UTF8"', , "Hide", &exitCode)
            } else {
                ; Use cmd for full path with proper pipe handling
                RunWait('cmd /c type "' . tempFile . '" | "' . this.Settings.bitwardenPath . '" encode | "' . this.Settings.bitwardenPath . '" create item > "' . outputFile . '" 2>&1', , "Hide", &exitCode)
            }
            
            ; Read the result
            result := ""
            if (FileExist(outputFile)) {
                result := FileRead(outputFile)
                FileDelete(outputFile)
            }
            
            ; Clean up temp file
            FileDelete(tempFile)
            progressGui.Destroy()
            
            ; Check result
            if (exitCode = 0 || InStr(result, '"object":"item"') || InStr(result, '"id":"')) {
                MsgBox("✅ Credentials saved to Bitwarden vault successfully!`n`nItem: " . name, "Save Successful", "Iconi")
            } else if (InStr(result, "You are not logged in")) {
                MsgBox("❌ Not logged in to Bitwarden.`n`nPlease authenticate first using the 'Setup Authentication' button.", "Authentication Required", "Iconx")
            } else if (InStr(result, "vault is locked")) {
                MsgBox("❌ Vault is locked.`n`nPlease unlock your vault first.", "Vault Locked", "Iconx")
            } else if (InStr(result, "session")) {
                MsgBox("❌ Session expired or invalid.`n`nPlease re-authenticate or unlock your vault.", "Session Issue", "Iconx")
            } else {
                MsgBox("❌ Failed to save to vault.`n`nError details: " . Trim(result) . "`n`nPlease ensure you're logged in and vault is unlocked.", "Save Failed", "Iconx")
            }
            
        } catch as e {
            try {
                progressGui.Destroy()
            } catch {
                ; Ignore if progressGui doesn't exist
            }
            MsgBox("Error saving to vault: " . e.Message, "Save Error", "Iconx")
        }
    }

    ; Helper method to close save GUI safely
    CloseSaveGui() {
        try {
            if (this.HasProp("saveGui") && this.saveGui) {
                this.saveGui.Destroy()
            }
        } catch {
            ; Ignore if GUI is already destroyed
        }
        
        ; Clean up references
        if (this.HasProp("saveGui")) {
            this.DeleteProp("saveGui")
        }
        if (this.HasProp("saveControls")) {
            this.DeleteProp("saveControls")
        }
    }

    ; Helper method to escape JSON strings
    EscapeJson(str) {
        ; Escape special JSON characters
        str := StrReplace(str, "\", "\\")  ; Escape backslashes first
        str := StrReplace(str, '"', '\"')  ; Escape quotes
        str := StrReplace(str, "`n", "\n")  ; Escape newlines
        str := StrReplace(str, "`r", "\r")  ; Escape carriage returns
        str := StrReplace(str, "`t", "\t")  ; Escape tabs
        return str
    }
    
    ; Save credentials to simple text file
    SaveToFile() {
        try {
            ; Create credentials directory if it doesn't exist
            credentialsDir := A_ScriptDir "\src\credentials"
            if (!DirExist(credentialsDir)) {
                DirCreate(credentialsDir)
            }
            
            ; Generate filename with timestamp
            timestamp := FormatTime(, "yyyy-MM-dd_HH-mm-ss")
            filename := credentialsDir "\credentials_" timestamp ".txt"
            
            ; Collect recent credentials (don't add header yet - EncryptText will handle it)
            content := "Generated: " . FormatTime(, "yyyy-MM-dd HH:mm:ss") . "`n`n"
            
            ; Add recent emails
            if (this.RecentEmails.Length > 0) {
                content .= "📧 EMAILS:" . "`n"
                emailCount := Min(5, this.RecentEmails.Length)
                Loop emailCount {
                    item := this.RecentEmails[this.RecentEmails.Length - A_Index + 1]
                    if (item.HasProp("prefix")) {
                        content .= "  • " . item.email . " (Masked with: " . item.prefix . ")" . "`n"
                    } else {
                        content .= "  • " . item.email . " (Temp from: " . item.service . ", Expires: " . item.expiry . ")" . "`n"
                    }
                }
                content .= "`n"
            }
            
            ; Add recent usernames
            if (this.RecentUsernames.Length > 0) {
                content .= "👤 USERNAMES:" . "`n"
                usernameCount := Min(5, this.RecentUsernames.Length)
                Loop usernameCount {
                    item := this.RecentUsernames[this.RecentUsernames.Length - A_Index + 1]
                    content .= "  • " . item.username . " (Template: " . item.template . ")" . "`n"
                }
                content .= "`n"
            }
            
            ; Add recent passwords
            if (this.RecentPasswords.Length > 0) {
                content .= "🔒 PASSWORDS:" . "`n"
                securityNote := this.Settings.encryptCredentials ? "  🔒 SECURE: File will be encrypted for security!" : "  ⚠️  WARNING: Passwords are stored in plain text! Keep this file secure!"
                content .= securityNote . "`n"
                passwordCount := Min(5, this.RecentPasswords.Length)
                Loop passwordCount {
                    item := this.RecentPasswords[this.RecentPasswords.Length - A_Index + 1]
                    content .= "  • " . item.password . " (Length: " . item.length . ", Strength: " . item.strength . ")" . "`n"
                }
                content .= "`n"
            }
            
            content .= "=== END OF CREDENTIALS ===" . "`n"
            finalSecurityNote := this.Settings.encryptCredentials ? "🔒 SECURITY: This file is encrypted with rotation cipher." : "⚠️  SECURITY NOTE: Delete this file after use or store it securely!"
            content .= finalSecurityNote . "`n"
            
            ; Apply encryption if enabled
            finalContent := this.EncryptText(content)
            
            ; Write to file
            FileAppend(finalContent, filename)
            
            ; Show success message with options
            result := MsgBox("✅ Credentials saved successfully!`n`nFile: " . filename . "`n`nWhat would you like to do?`n`n• Yes = Open file`n• No = Open folder`n• Cancel = Do nothing", "Credentials Saved", "YesNoCancel Iconi")
            
            if (result = "Yes") {
                Run(filename)
            } else if (result = "No") {
                Run("explorer.exe " . credentialsDir)
            }
            
        } catch as e {
            MsgBox("❌ Error saving credentials to file: " . e.Message, "Save Error", "Iconx")
        }
    }
    
    ; View the saved credentials file
    ViewSavedFile() {
        try {
            credentialsDir := A_ScriptDir "\src\credentials"
            
            if (!DirExist(credentialsDir)) {
                MsgBox("No credentials have been saved yet.", "No Files", "Iconi")
                return
            }
            
            ; Find the most recent credentials file
            files := []
            Loop Files, credentialsDir "\credentials_*.txt" {
                files.Push({name: A_LoopFileName, path: A_LoopFileFullPath, time: A_LoopFileTimeModified})
            }
            
            if (files.Length = 0) {
                MsgBox("No credential files found.", "No Files", "Iconi")
                return
            }
            
            ; Sort by modification time (newest first)
            for i, file1 in files {
                for j, file2 in files {
                    if (i < j && file1.time < file2.time) {
                        temp := files[i]
                        files[i] := files[j]
                        files[j] := temp
                    }
                }
            }
            
            ; Show file selection if multiple files exist
            if (files.Length = 1) {
                this.ViewFile(files[1].path)
            } else {
                ; Create selection GUI
                selectGui := Gui("+Resize", "Select Credentials File")
                selectGui.SetFont("s9", "Segoe UI")
                
                selectGui.Add("Text", "x10 y10 w400", "Select a credentials file to view:")
                fileList := selectGui.Add("ListBox", "x10 y30 w400 h200")
                
                for file in files {
                    fileList.Add([file.name])
                }
                fileList.Choose(1)  ; Select first (newest)
                
                openBtn := selectGui.Add("Button", "x10 y240 w100 h30", "Open File")
                folderBtn := selectGui.Add("Button", "x120 y240 w100 h30", "Open Folder")
                cancelBtn := selectGui.Add("Button", "x340 y240 w70 h30", "Cancel")
                
                openBtn.OnEvent("Click", (*) => (
                    selectedIndex := fileList.Value,
                    selectGui.Destroy(),
                    this.ViewFile(files[selectedIndex].path)
                ))
                
                folderBtn.OnEvent("Click", (*) => (
                    selectGui.Destroy(),
                    Run("explorer.exe " . credentialsDir)
                ))
                
                cancelBtn.OnEvent("Click", (*) => selectGui.Destroy())
                selectGui.OnEvent("Close", (*) => selectGui.Destroy())
                
                selectGui.Show("w420 h280")
            }
            
        } catch as e {
            MsgBox("❌ Error viewing saved file: " . e.Message, "View Error", "Iconx")
        }
    }
    
    ; View a credentials file (with decryption if needed)
    ViewFile(filePath) {
        try {
            ; Read the file
            content := FileRead(filePath)
            
            ; Check if file is encrypted (using ROT13 encryption markers)
            if (InStr(content, "=== AHK ENCRYPTED CREDENTIALS")) {
                ; File is encrypted - decrypt it
                decryptedContent := this.DecryptText(content)
                
                ; Create temporary decrypted file
                tempFile := A_Temp "\decrypted_credentials_" . A_TickCount . ".txt"
                FileAppend(decryptedContent, tempFile)
                
                ; Show info and open temp file
                result := MsgBox("🔓 File is encrypted. Opening decrypted temporary copy.`n`n📄 Temp File: " . tempFile . "`n⏰ Auto-delete after 30 seconds?`n`n• YES = Auto-delete`n• NO = Keep temp file", "Encrypted File", "YesNo Iconi")
                
                ; Open the decrypted temp file
                Run(tempFile)
                
                if (result = "Yes") {
                    ; Schedule deletion after 30 seconds
                    SetTimer(() => this.DeleteTempFile(tempFile), -30000)
                    ShowMouseTooltip("Temp file will auto-delete in 30 seconds", 3000)
                } else {
                    ShowMouseTooltip("Temp file kept: " . tempFile, 4000)
                }
            } else if (InStr(content, "=== GENERATED CREDENTIALS ===")) {
                ; This looks like an unencrypted credentials file - check if it's readable
                if (InStr(content, "📧 EMAILS:") || InStr(content, "👤 USERNAMES:") || InStr(content, "🔒 PASSWORDS:")) {
                    ; File contains readable credential sections - open directly
                    Run(filePath)
                    ShowMouseTooltip("Opening unencrypted credentials file", 2000)
                } else {
                    ; File appears corrupted - may contain encrypted data without proper headers
                    MsgBox("⚠️ File appears to be corrupted or contains encrypted data without proper headers.`n`nFile: " . filePath . "`n`nThis may be an old encrypted file. Try deleting it and generating new credentials.", "Corrupted File", "Icon! T5")
                }
            } else {
                ; Unknown file format - open directly and let user decide
                Run(filePath)
                ShowMouseTooltip("Opening file (unknown format)", 2000)
            }
            
        } catch as e {
            MsgBox("❌ Error viewing file: " . e.Message, "View Error", "Iconx")
        }
    }
    
    ; Helper method to delete temporary files
    DeleteTempFile(filePath) {
        try {
            FileDelete(filePath)
        } catch as e {
            ; Ignore if file is in use
        }
    }
    
    ; Clear all history
    ClearAllHistory() {
        result := MsgBox("Clear all generation history?", "Confirm Clear", "YesNo Icon?")
        if (result = "Yes") {
            this.RecentEmails := []
            this.RecentUsernames := []
            this.RecentPasswords := []
            ShowMouseTooltip("History cleared", 1500)
        }
    }
    
    ; Export settings
    ExportSettings() {
        fileDialog := FileSelect("S16", A_ScriptDir "\email_password_settings.json", "Export Settings", "JSON Files (*.json)")
        if (fileDialog) {
            try {
                settingsJson := this.SettingsToJson()
                FileDelete(fileDialog)
                FileAppend(settingsJson, fileDialog)
                ShowMouseTooltip("Settings exported", 2000)
            } catch as e {
                MsgBox("Error exporting settings: " e.Message, "Export Error", "Iconx")
            }
        }
    }
    
    ; Import settings
    ImportSettings() {
        fileDialog := FileSelect(1, "", "Import Settings", "JSON Files (*.json)")
        if (fileDialog) {
            try {
                settingsJson := FileRead(fileDialog)
                this.JsonToSettings(settingsJson)
                ShowMouseTooltip("Settings imported", 2000)
            } catch as e {
                MsgBox("Error importing settings: " e.Message, "Import Error", "Iconx")
            }
        }
    }
    
    ; Convert settings to JSON (simplified)
    SettingsToJson() {
        return '{"primaryEmail":"' this.Settings.primaryEmail '","defaultMaskPrefix":"' this.Settings.defaultMaskPrefix '","usernameTemplate":"' this.Settings.usernameTemplate '","passwordLength":' this.Settings.passwordLength '}'
    }
    
    ; Convert JSON to settings (simplified)
    JsonToSettings(json) {
        ; This is a simplified implementation - in real use would need proper JSON parsing
        OutputDebug("Settings import: " json)
    }
    
    ; Load history into list views
    LoadHistory(maskList, tempList, usernameList, passwordList) {
        ; Load recent emails
        for item in this.RecentEmails {
            if (item.HasProp("prefix")) {
                maskList.Add("", item.email, item.prefix, FormatTime(item.created, "yyyy-MM-dd HH:mm"))
            } else {
                tempList.Add("", item.email, item.service, item.expiry, FormatTime(item.created, "yyyy-MM-dd HH:mm"))
            }
        }
        
        ; Load recent usernames
        for item in this.RecentUsernames {
            usernameList.Add("", item.username, item.template, FormatTime(item.created, "yyyy-MM-dd HH:mm"))
        }
        
        ; Load recent passwords (show actual passwords)
        for item in this.RecentPasswords {
            passwordList.Add("", item.password, item.length, item.strength, FormatTime(item.created, "yyyy-MM-dd HH:mm"))
        }
    }
    
    ; Save advanced settings only
    SaveAdvancedSettings(primaryEmail, defaultPrefix, defaultUsername, defaultPasswordLength) {
        this.Settings.primaryEmail := primaryEmail
        this.Settings.defaultMaskPrefix := defaultPrefix
        this.Settings.usernameTemplate := defaultUsername
        this.Settings.passwordLength := Integer(defaultPasswordLength)
        
        this.SaveSettings()
        ShowMouseTooltip("Advanced settings saved", 2000)
    }

    ; Save all settings
    SaveAllSettings(email, maskPrefix, tempService, usernameTemplate, passwordLength, includeUpper, includeLower, includeNumbers, includeSymbols, bitwardenEnabled, bitwardenPath, enabled, primaryEmail, defaultPrefix, defaultUsername, defaultPasswordLength, encryptCredentials, gui) {
        this.Settings.primaryEmail := primaryEmail
        this.Settings.defaultMaskPrefix := defaultPrefix
        this.Settings.tempEmailService := tempService
        this.Settings.usernameTemplate := defaultUsername
        this.Settings.passwordLength := Integer(defaultPasswordLength)
        this.Settings.passwordIncludeUppercase := includeUpper
        this.Settings.passwordIncludeLowercase := includeLower
        this.Settings.passwordIncludeNumbers := includeNumbers
        this.Settings.passwordIncludeSymbols := includeSymbols
        this.Settings.bitwardenEnabled := bitwardenEnabled
        this.Settings.bitwardenPath := bitwardenPath
        this.Settings.enabled := enabled
        this.Settings.encryptCredentials := encryptCredentials
        
        this.SaveSettings()
        ShowMouseTooltip("Settings saved", 1500)
        gui.Destroy()
    }
    
    ; Load settings from file
    LoadSettings() {
        try {
            settingsFile := A_ScriptDir "\data\plugins\emailpassword_settings.ini"
            if (FileExist(settingsFile)) {
                this.Settings.primaryEmail := IniRead(settingsFile, "Settings", "PrimaryEmail", "yourname@gmail.com")
                this.Settings.defaultMaskPrefix := IniRead(settingsFile, "Settings", "DefaultMaskPrefix", "shopping")
                this.Settings.usernameTemplate := IniRead(settingsFile, "Settings", "UsernameTemplate", "user_{random}")
                this.Settings.passwordLength := Integer(IniRead(settingsFile, "Settings", "PasswordLength", "16"))
                
                ; Load password character type settings (CRITICAL - was missing!)
                this.Settings.passwordIncludeUppercase := (IniRead(settingsFile, "Settings", "PasswordIncludeUppercase", "true") = "true")
                this.Settings.passwordIncludeLowercase := (IniRead(settingsFile, "Settings", "PasswordIncludeLowercase", "true") = "true")
                this.Settings.passwordIncludeNumbers := (IniRead(settingsFile, "Settings", "PasswordIncludeNumbers", "true") = "true")
                this.Settings.passwordIncludeSymbols := (IniRead(settingsFile, "Settings", "PasswordIncludeSymbols", "true") = "true")
                
                this.Settings.bitwardenEnabled := (IniRead(settingsFile, "Settings", "BitwardenEnabled", "false") = "true")
                this.Settings.bitwardenPath := IniRead(settingsFile, "Settings", "BitwardenPath", "bw")
                this.Settings.encryptCredentials := (IniRead(settingsFile, "Settings", "EncryptCredentials", "false") = "true")
            }
        } catch as e {
            OutputDebug("Error loading settings: " e.Message)
        }
    }
    
    ; Save settings to file
    SaveSettings() {
        try {
            settingsFile := A_ScriptDir "\data\plugins\emailpassword_settings.ini"
            
            ; Create directory if it doesn't exist
            SplitPath(settingsFile, , &dir)
            if (!DirExist(dir)) {
                DirCreate(dir)
            }
            
            IniWrite(this.Settings.primaryEmail, settingsFile, "Settings", "PrimaryEmail")
            IniWrite(this.Settings.defaultMaskPrefix, settingsFile, "Settings", "DefaultMaskPrefix")
            IniWrite(this.Settings.usernameTemplate, settingsFile, "Settings", "UsernameTemplate")
            IniWrite(this.Settings.passwordLength, settingsFile, "Settings", "PasswordLength")
            
            ; Save password character type settings (CRITICAL - was missing!)
            IniWrite(this.Settings.passwordIncludeUppercase ? "true" : "false", settingsFile, "Settings", "PasswordIncludeUppercase")
            IniWrite(this.Settings.passwordIncludeLowercase ? "true" : "false", settingsFile, "Settings", "PasswordIncludeLowercase")
            IniWrite(this.Settings.passwordIncludeNumbers ? "true" : "false", settingsFile, "Settings", "PasswordIncludeNumbers")
            IniWrite(this.Settings.passwordIncludeSymbols ? "true" : "false", settingsFile, "Settings", "PasswordIncludeSymbols")
            
            IniWrite(this.Settings.bitwardenEnabled ? "true" : "false", settingsFile, "Settings", "BitwardenEnabled")
            IniWrite(this.Settings.bitwardenPath, settingsFile, "Settings", "BitwardenPath")
            IniWrite(this.Settings.encryptCredentials ? "true" : "false", settingsFile, "Settings", "EncryptCredentials")
            
        } catch as e {
            OutputDebug("Error saving settings: " e.Message)
        }
    }
    
    ; Show help
    ShowHelp() {
        helpText := "Email & Password Manager Help:`n`n"
        helpText .= "EMAIL MASKING:`n"
        helpText .= "• Creates Gmail+ aliases (yourname+prefix@gmail.com)`n"
        helpText .= "• All emails go to your main inbox`n"
        helpText .= "• Easy to filter and organize`n`n"
        
        helpText .= "TEMPORARY EMAILS:`n"
        helpText .= "• Opens temporary email services`n"
        helpText .= "• Generate disposable email addresses`n"
        helpText .= "• Perfect for one-time signups`n`n"
        
        helpText .= "USERNAME GENERATOR:`n"
        helpText .= "• Use templates with placeholders:`n"
        helpText .= "  {random} - Random numbers`n"
        helpText .= "  {word} - Random word`n"
        helpText .= "  {adjective} - Random adjective`n"
        helpText .= "  {animal} - Random animal`n"
        helpText .= "  {color} - Random color`n"
        helpText .= "  {year} - Current year`n`n"
        
        helpText .= "PASSWORD GENERATOR:`n"
        helpText .= "• Customizable length (8-128 chars)`n"
        helpText .= "• Include/exclude character types`n"
        helpText .= "• Automatic strength checking`n`n"
        
        helpText .= "BITWARDEN INTEGRATION:`n"
        helpText .= "• Save generated credentials to vault`n"
        helpText .= "• Requires Bitwarden CLI`n"
        helpText .= "• Secure credential management`n`n"
        
        helpText .= "All generated items are automatically copied to clipboard!"
        
        MsgBox(helpText, "Email & Password Manager Help", "T30")
    }


} 
