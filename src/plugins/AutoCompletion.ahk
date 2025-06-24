#Requires AutoHotkey v2.0-*

; AutoCompletion Plugin for AHK Tools - Simplified Version  
; This plugin provides text expansion functionality

class AutoCompletionPlugin extends Plugin {
    ; Plugin metadata
    static Name := "Auto Completion"
    static Description := "Text expansion with built-in entries"
    static Version := "1.0.1"
    static Author := "AHK Tools"
    
    ; Plugin settings
    Settings := {
        enabled: true,
        caseSensitive: false
    }
    
    ; Dictionary for hotstrings
    Dictionary := Map()
    
        ; Constructor
    __New() {
        ; Call parent constructor
        super.__New()
        
        OutputDebug "AutoCompletion: Constructor called"
        
        try {
                    ; Initialize with basic built-in entries (static only)
        this.LoadBuiltinEntries()
        
            ; Load custom entries from file
            this.LoadCustomEntries()
            
            OutputDebug "AutoCompletion: Loaded " this.Dictionary.Count " entries successfully"
            OutputDebug "FINAL CHECK: btw=" (this.Dictionary.Has("btw") ? this.Dictionary["btw"] : "NOT_FOUND") " todo=" (this.Dictionary.Has("todo") ? this.Dictionary["todo"] : "NOT_FOUND")
        } catch as e {
            OutputDebug "AutoCompletion: Error in constructor: " e.Message
            ; Ensure we have at least an empty dictionary
            if (!this.HasProp("Dictionary") || !this.Dictionary) {
                this.Dictionary := Map()
            }
        }
    }
    
    ; Removed external functions - keeping only static text for simplicity

    
    ; Load built-in entries
    LoadBuiltinEntries() {
        ; Always create a fresh dictionary for built-in entries
        this.Dictionary := Map()
        
        OutputDebug "AutoCompletion: Loading static entries..."
        
        ; Basic email and common expansions
        this.Dictionary["email"] := "your.email@example.com"
        this.Dictionary["name"] := "Your Name"
        this.Dictionary["addr"] := "Your Address"
        this.Dictionary["phone"] := "555-123-4567"
        this.Dictionary["sig"] := "Best regards,`nYour Name"
        
        ; Common abbreviations
        this.Dictionary["btw"] := "by the way"
        this.Dictionary["fyi"] := "for your information" 
        this.Dictionary["asap"] := "as soon as possible"
        this.Dictionary["thx"] := "thank you"
        this.Dictionary["pls"] := "please"
        
        ; Development
        this.Dictionary["lorem"] := "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
        this.Dictionary["todo"] := "TODO: "
        this.Dictionary["fixme"] := "FIXME: "
        this.Dictionary["hack"] := "HACK: "
        
        OutputDebug "AutoCompletion: Static entries loaded. btw=" this.Dictionary["btw"] " todo=" this.Dictionary["todo"]
        
        OutputDebug "Loaded " this.Dictionary.Count " static entries"
        OutputDebug "Final dictionary check - btw=" (this.Dictionary.Has("btw") ? this.Dictionary["btw"] : "NOT_FOUND") " todo=" (this.Dictionary.Has("todo") ? this.Dictionary["todo"] : "NOT_FOUND")
    }
    
    ; Initialize the plugin
    Initialize() {
        try {
            this.Enabled := true
            ; Don't register hotstrings during initialization - do it in Enable()
            OutputDebug "AutoCompletion: Plugin initialized successfully"
            return true
        } catch as e {
            OutputDebug "AutoCompletion: Error during initialization: " e.Message
            return false
        }
    }
    
    ; Enable the plugin
    Enable() {
        try {
            this.RegisterHotstrings()
            this.Enabled := true
            OutputDebug "AutoCompletion: Plugin enabled successfully"
        } catch as e {
            OutputDebug "AutoCompletion: Error enabling plugin: " e.Message
            MsgBox("Error enabling AutoCompletion plugin: " e.Message, "Plugin Error", "Iconx")
            return false
        }
        return true
    }
    
    ; Disable the plugin
    Disable() {
        try {
            this.UnregisterHotstrings()
            this.Enabled := false
        } catch as e {
            MsgBox("Error disabling AutoCompletion plugin: " e.Message, "Plugin Error", "Iconx")
            return false
        }
        return true
    }
    
    ; Register hotstrings for dictionary entries
    RegisterHotstrings() {
        if (this.Dictionary.Count = 0) {
            OutputDebug "No dictionary entries to register"
            return
        }
        
        ; Set ending characters to ONLY Tab
        Hotstring("EndChars", "`t")
        
        registeredCount := 0
        
        for trigger, replacement in this.Dictionary {
            try {
                hotstringOptions := "::" trigger
                

                
                ; Check if replacement is a function (dynamic) or string (static)
                replacementType := Type(replacement)
                OutputDebug "Processing '" trigger "': Type=" replacementType " Value=" (replacementType = "String" ? replacement : "[" replacementType "]")
                

                

                
                if (replacementType = "Func" || HasMethod(replacement, "Call")) {
                    ; Dynamic function - call it when triggered
                    ; Capture both the function and trigger in the closure
                    dynamicFunc := replacement
                    triggerName := trigger
                    Hotstring(hotstringOptions, (*) => this.ExecuteDynamicExpansion(dynamicFunc, triggerName))
                    OutputDebug "Registered FUNC: " trigger
                } else if (replacementType = "String") {
                    ; Static string - use helper method to avoid closure issues
                    this.RegisterStaticHotstring(hotstringOptions, replacement)
                    OutputDebug "Registered STRING: " trigger " = " replacement
                } else {
                    ; Unknown type - skip registration and debug
                    OutputDebug "ERROR: Skipping '" trigger "' - unexpected type: " replacementType
                    continue
                }
                
                registeredCount++
            } catch as e {
                OutputDebug "Failed to register '" trigger "': " e.Message
            }
        }
        
        OutputDebug "Registered " registeredCount " hotstrings"
    }
    
    ; Unregister hotstrings
    UnregisterHotstrings() {
        for trigger, replacement in this.Dictionary {
            try {
                Hotstring("::" trigger, "")
            } catch as e {
                ; Ignore errors when unregistering
            }
        }
        OutputDebug "Unregistered hotstrings"
    }
    
    ; Show plugin settings (required for Plugin Settings button)
    ShowSettings() {
        this.ShowAutoCompletionManager()
    }
    
    ; Show the AutoCompletion Manager
    ShowAutoCompletionManager() {
        ; Create the autocompletion manager GUI
        managerGui := Gui("+Resize +MaximizeBox", "AutoCompletion Manager - " this.Dictionary.Count " entries loaded")
        managerGui.SetFont("s9", "Segoe UI")
        
        ; Instructions
        managerGui.Add("Text", "x10 y10 w680", "AutoCompletion Manager - Add, edit, and manage your text expansions")
        managerGui.Add("Text", "x10 y30 w680", "Type any trigger word and press Tab to expand it. Manage your entries below:")
        
        ; List of dictionary entries
        listView := managerGui.Add("ListView", "x10 y60 w680 h300 Grid", ["Trigger", "Expansion", "Category", "Type"])
        
        ; Populate the list
        this.PopulateManagerList(listView)
        
        ; Auto-size columns
        listView.ModifyCol(1, 120)  ; Trigger
        listView.ModifyCol(2, 350)  ; Expansion  
        listView.ModifyCol(3, 100)  ; Category
        listView.ModifyCol(4, 80)   ; Type
        
        ; Entry management buttons
        managerGui.Add("GroupBox", "x10 y370 w680 h80", "Entry Management")
        addBtn := managerGui.Add("Button", "x20 y390 w100 h25", "Add Entry")
        editBtn := managerGui.Add("Button", "x130 y390 w100 h25", "Edit Selected")
        deleteBtn := managerGui.Add("Button", "x240 y390 w100 h25", "Delete Selected")
        importBtn := managerGui.Add("Button", "x350 y390 w100 h25", "Import File")
        exportBtn := managerGui.Add("Button", "x460 y390 w100 h25", "Export All")
        
        ; Quick actions
        refreshBtn := managerGui.Add("Button", "x570 y390 w100 h25", "Refresh List")
        
        ; Statistics
        statsText := managerGui.Add("Text", "x20 y420 w400", "Total: " this.Dictionary.Count " entries (" this.GetBuiltinCount() " built-in, " this.GetCustomCount() " custom)")
        
        ; Test area
        managerGui.Add("GroupBox", "x10 y460 w680 h80", "Test Area")
        managerGui.Add("Text", "x20 y480", "Test your expansions here (type trigger + Tab):")
        testEdit := managerGui.Add("Edit", "x20 y500 w650 h30")
        
        ; Bottom buttons
        helpBtn := managerGui.Add("Button", "x10 y550 w100 h30", "Help")
        settingsBtn := managerGui.Add("Button", "x120 y550 w100 h30", "Settings")
        closeBtn := managerGui.Add("Button", "x590 y550 w100 h30", "Close")
        
        ; Event handlers
        addBtn.OnEvent("Click", (*) => this.AddDictionaryEntry(listView, managerGui))
        editBtn.OnEvent("Click", (*) => this.EditDictionaryEntry(listView, managerGui))
        deleteBtn.OnEvent("Click", (*) => this.DeleteDictionaryEntry(listView, managerGui))
        importBtn.OnEvent("Click", (*) => this.ImportDictionary(listView, managerGui))
        exportBtn.OnEvent("Click", (*) => this.ExportDictionary(managerGui))
        refreshBtn.OnEvent("Click", (*) => this.RefreshManagerList(listView))
        helpBtn.OnEvent("Click", (*) => this.ShowHelp())
        settingsBtn.OnEvent("Click", (*) => this.ShowPluginSettings(managerGui))
        closeBtn.OnEvent("Click", (*) => managerGui.Destroy())
        managerGui.OnEvent("Close", (*) => managerGui.Destroy())
        
        ; Store references
        this.ManagerGui := managerGui
        this.ManagerListView := listView
        
        ; Show the GUI
        managerGui.Show("w700 h590")
    }
    
    ; Get category for an entry (for organization)
    GetEntryCategory(trigger) {
        ; Email/Contact
        if (InStr("email,name,addr,phone,sig", trigger))
            return "Contact"
        
        ; Common abbreviations  
        if (InStr("btw,fyi,asap,thx,pls", trigger))
            return "Common"
            
        ; Development
        if (InStr("lorem,todo,fixme,hack,guid,uuid,pwd,strongpwd", trigger))
            return "Development"
            
        ; Date/Time
        if (InStr("date,time,now,today,datetime,week,month,year,timestamp,iso,epoch", trigger))
            return "Date/Time"
            
        ; File naming
        if (InStr("logname,filename", trigger))
            return "Files"
            
        ; Schedule
        if (InStr("meeting,deadline", trigger))
            return "Schedule"
            
        ; System
        if (InStr("username,computer,osver,workdir,clipboard", trigger))
            return "System"
            
        ; Fun/Random
        if (InStr("pin,coin,dice", trigger))
            return "Random"
            
        ; Network
        if (InStr("localhost", trigger))
            return "Network"
            
        return "General"
    }
    
    ; Populate manager list with all entries
    PopulateManagerList(listView) {
        listView.Delete()
        for trigger, expansion in this.Dictionary {
            category := this.GetEntryCategory(trigger)
            entryType := this.IsBuiltinEntry(trigger) ? "Built-in" : "Custom"
            
            ; Handle display for different types of expansions
            expansionType := Type(expansion)
            if (expansionType = "Func") {
                displayExpansion := "[Dynamic Function]"
            } else {
                ; Convert to string safely and truncate if needed
                try {
                    expansionStr := String(expansion)
                    displayExpansion := (StrLen(expansionStr) > 50) ? SubStr(expansionStr, 1, 47) "..." : expansionStr
                } catch {
                    ; Fallback for any unexpected types
                    displayExpansion := "[" expansionType "]"
                }
            }
            
            listView.Add("", trigger, displayExpansion, category, entryType)
        }
    }
    
    ; Refresh the manager list
    RefreshManagerList(listView) {
        this.PopulateManagerList(listView)
        ShowMouseTooltip("List refreshed", 1000)
    }
    
    ; Check if entry is built-in
    IsBuiltinEntry(trigger) {
        builtinTriggers := [
            ; Static entries only
            "email", "name", "addr", "phone", "sig", "btw", "fyi", "asap", "thx", "pls", "lorem", "todo", "fixme", "hack"
        ]
        for builtinTrigger in builtinTriggers {
            if (builtinTrigger = trigger)
                return true
        }
        return false
    }
    
    ; Get count of built-in entries
    GetBuiltinCount() {
        count := 0
        for trigger, expansion in this.Dictionary {
            if (this.IsBuiltinEntry(trigger))
                count++
        }
        return count
    }
    
    ; Get count of custom entries
    GetCustomCount() {
        return this.Dictionary.Count - this.GetBuiltinCount()
    }
    
    ; Add new dictionary entry
    AddDictionaryEntry(listView, parentGui) {
        entryGui := Gui("+Owner" parentGui.Hwnd, "Add New Entry")
        entryGui.SetFont("s9", "Segoe UI")
        
        ; Form fields
        entryGui.Add("Text", "x10 y10", "Trigger (abbreviation):")
        triggerEdit := entryGui.Add("Edit", "x10 y30 w300")
        
        entryGui.Add("Text", "x10 y60", "Expansion (text to insert):")
        expansionEdit := entryGui.Add("Edit", "x10 y80 w300 h80 VScroll")
        
        entryGui.Add("Text", "x10 y170", "Category (optional):")
        categoryCombo := entryGui.Add("ComboBox", "x10 y190 w150", ["Custom", "Contact", "Common", "Development", "Date/Time", "Files", "Schedule", "System", "Random", "Network", "General"])
        categoryCombo.Text := "Custom"
        
        ; Buttons
        saveBtn := entryGui.Add("Button", "x10 y220 w80 h30", "Save")
        cancelBtn := entryGui.Add("Button", "x100 y220 w80 h30", "Cancel")
        
        ; Event handlers
        saveBtn.OnEvent("Click", (*) => this.SaveNewEntry(listView, triggerEdit.Text, expansionEdit.Text, categoryCombo.Text, entryGui))
        cancelBtn.OnEvent("Click", (*) => entryGui.Destroy())
        entryGui.OnEvent("Close", (*) => entryGui.Destroy())
        
        entryGui.Show("w320 h260")
        triggerEdit.Focus()
    }
    
    ; Save new entry
    SaveNewEntry(listView, trigger, expansion, category, gui) {
        trigger := Trim(trigger)
        expansion := Trim(expansion)
        
        if (!trigger) {
            MsgBox("Please enter a trigger word.", "Missing Trigger", "Iconx")
            return
        }
        
        if (!expansion) {
            MsgBox("Please enter the expansion text.", "Missing Expansion", "Iconx")
            return
        }
        
        ; Check if trigger already exists
        if (this.Dictionary.Has(trigger)) {
            result := MsgBox("Trigger '" trigger "' already exists. Replace it?", "Duplicate Trigger", "YesNo Icon?")
            if (result != "Yes")
                return
        }
        
        ; Add to dictionary
        this.Dictionary[trigger] := expansion
        
        ; Register the hotstring
        try {
            hotstringOptions := "::" trigger
            Hotstring(hotstringOptions, ((text) => (*) => SendText(text))(expansion))
        } catch as e {
            MsgBox("Error registering hotstring: " e.Message, "Error", "Iconx")
        }
        
        ; Refresh list
        this.PopulateManagerList(listView)
        
        ; Save to file
        this.SaveCustomEntries()
        
        gui.Destroy()
        ShowMouseTooltip("Entry '" trigger "' added successfully", 2000)
    }
    
    ; Edit existing dictionary entry
    EditDictionaryEntry(listView, parentGui) {
        selectedRow := listView.GetNext()
        if (!selectedRow) {
            MsgBox("Please select an entry to edit.", "No Selection", "Iconx")
            return
        }
        
        trigger := listView.GetText(selectedRow, 1)
        expansion := this.Dictionary[trigger]
        category := listView.GetText(selectedRow, 3)
        entryType := listView.GetText(selectedRow, 4)
        
        ; Don't allow editing built-in entries
        if (entryType = "Built-in") {
            MsgBox("Built-in entries cannot be edited. Create a new custom entry instead.", "Cannot Edit", "Iconx")
            return
        }
        
        ; Don't allow editing dynamic function entries
        if (Type(expansion) = "Func") {
            MsgBox("Dynamic function entries cannot be edited. Only custom text entries can be modified.", "Cannot Edit Function", "Iconx")
            return
        }
        
        entryGui := Gui("+Owner" parentGui.Hwnd, "Edit Entry: " trigger)
        entryGui.SetFont("s9", "Segoe UI")
        
        ; Form fields
        entryGui.Add("Text", "x10 y10", "Trigger (abbreviation):")
        triggerEdit := entryGui.Add("Edit", "x10 y30 w300")
        triggerEdit.Text := trigger
        
        entryGui.Add("Text", "x10 y60", "Expansion (text to insert):")
        expansionEdit := entryGui.Add("Edit", "x10 y80 w300 h80 VScroll")
        expansionEdit.Text := expansion
        
        entryGui.Add("Text", "x10 y170", "Category:")
        categoryCombo := entryGui.Add("ComboBox", "x10 y190 w150", ["Custom", "Contact", "Common", "Development", "Date/Time", "Files", "Schedule", "System", "Random", "Network", "General"])
        categoryCombo.Text := category
        
        ; Buttons
        saveBtn := entryGui.Add("Button", "x10 y220 w80 h30", "Save")
        cancelBtn := entryGui.Add("Button", "x100 y220 w80 h30", "Cancel")
        
        ; Event handlers
        saveBtn.OnEvent("Click", (*) => this.UpdateEntry(listView, selectedRow, trigger, triggerEdit.Text, expansionEdit.Text, categoryCombo.Text, entryGui))
        cancelBtn.OnEvent("Click", (*) => entryGui.Destroy())
        entryGui.OnEvent("Close", (*) => entryGui.Destroy())
        
        entryGui.Show("w320 h260")
        triggerEdit.Focus()
    }
    
    ; Update existing entry
    UpdateEntry(listView, row, oldTrigger, newTrigger, expansion, category, gui) {
        newTrigger := Trim(newTrigger)
        expansion := Trim(expansion)
        
        if (!newTrigger || !expansion) {
            MsgBox("Please fill in all required fields.", "Missing Information", "Iconx")
            return
        }
        
        ; Remove old entry if trigger changed
        if (oldTrigger != newTrigger) {
            this.Dictionary.Delete(oldTrigger)
            ; Unregister old hotstring
            try {
                Hotstring("::" oldTrigger, "")
            } catch {
                ; Ignore errors
            }
        }
        
        ; Add updated entry
        this.Dictionary[newTrigger] := expansion
        
        ; Register new hotstring
        try {
            hotstringOptions := "::" newTrigger
            Hotstring(hotstringOptions, ((text) => (*) => SendText(text))(expansion))
        } catch as e {
            MsgBox("Error registering hotstring: " e.Message, "Error", "Iconx")
        }
        
        ; Refresh list
        this.PopulateManagerList(listView)
        
        ; Save to file
        this.SaveCustomEntries()
        
        gui.Destroy()
        ShowMouseTooltip("Entry updated successfully", 2000)
    }
    
    ; Delete dictionary entry
    DeleteDictionaryEntry(listView, parentGui) {
        selectedRow := listView.GetNext()
        if (!selectedRow) {
            MsgBox("Please select an entry to delete.", "No Selection", "Iconx")
            return
        }
        
        trigger := listView.GetText(selectedRow, 1)
        entryType := listView.GetText(selectedRow, 4)
        
        ; Don't allow deleting built-in entries
        if (entryType = "Built-in") {
            MsgBox("Built-in entries cannot be deleted.", "Cannot Delete", "Iconx")
            return
        }
        
        ; Don't allow deleting dynamic function entries
        expansion := this.Dictionary[trigger]
        if (Type(expansion) = "Func") {
            MsgBox("Dynamic function entries cannot be deleted. Only custom text entries can be removed.", "Cannot Delete Function", "Iconx")
            return
        }
        
        result := MsgBox("Delete entry '" trigger "'?", "Confirm Delete", "YesNo Icon?")
        if (result = "Yes") {
            ; Remove from dictionary
            this.Dictionary.Delete(trigger)
            
            ; Unregister hotstring
            try {
                Hotstring("::" trigger, "")
            } catch {
                ; Ignore errors
            }
            
            ; Refresh list
            this.PopulateManagerList(listView)
            
            ; Save to file
            this.SaveCustomEntries()
            
            ShowMouseTooltip("Entry '" trigger "' deleted", 1500)
        }
    }
    
    ; Save custom entries to file
    SaveCustomEntries() {
        try {
            customFile := A_ScriptDir "\data\plugins\autocompletion_custom.ini"
            
            ; Create directory if it doesn't exist
            SplitPath(customFile, , &dir)
            if (!DirExist(dir)) {
                DirCreate(dir)
                OutputDebug("Created directory: " dir)
            }
            
            ; Write custom entries
            content := "[Custom Entries]`n"
            customCount := 0
            for trigger, expansion in this.Dictionary {
                if (!this.IsBuiltinEntry(trigger)) {
                    ; Escape special characters for INI format
                    escapedExpansion := StrReplace(expansion, "`n", "\\n")
                    escapedExpansion := StrReplace(escapedExpansion, "`r", "\\r")
                    escapedExpansion := StrReplace(escapedExpansion, "`t", "\\t")
                    content .= trigger "=" escapedExpansion "`n"
                    customCount++
                    OutputDebug("Saving custom entry: " trigger " = " expansion)
                }
            }
            
            ; Delete old file and write new content
            if (FileExist(customFile))
                FileDelete(customFile)
            FileAppend(content, customFile)
            
            OutputDebug("Saved " customCount " custom entries to " customFile)
            
        } catch as e {
            OutputDebug("Error saving custom entries: " e.Message)
            MsgBox("Error saving custom entries: " e.Message, "Save Error", "Iconx")
        }
    }
    
    ; Load custom entries from file
    LoadCustomEntries() {
        try {
            customFile := A_ScriptDir "\data\plugins\autocompletion_custom.ini"
            
            if (FileExist(customFile)) {
                customCount := 0
                Loop Read, customFile {
                    line := Trim(A_LoopReadLine)
                    if (line && !InStr(line, "[") && InStr(line, "=")) {
                        pos := InStr(line, "=")
                        trigger := Trim(SubStr(line, 1, pos - 1))
                        expansion := Trim(SubStr(line, pos + 1))
                        
                        ; Unescape special characters
                        expansion := StrReplace(expansion, "\\n", "`n")
                        expansion := StrReplace(expansion, "\\r", "`r")
                        expansion := StrReplace(expansion, "\\t", "`t")
                        
                        if (trigger && expansion) {
                            ; Check if this overwrites a built-in entry
                            if (this.Dictionary.Has(trigger)) {
                                OutputDebug("WARNING: Custom entry '" trigger "' overwrites built-in entry: '" this.Dictionary[trigger] "' -> '" expansion "'")
                            }
                            this.Dictionary[trigger] := expansion
                            customCount++
                            OutputDebug("Loaded custom entry: " trigger " = " expansion)
                        }
                    }
                }
                OutputDebug("Loaded " customCount " custom entries from " customFile)
            } else {
                OutputDebug("No custom entries file found at: " customFile)
            }
        } catch as e {
            OutputDebug("Error loading custom entries: " e.Message)
        }
    }
    
    ; Import dictionary from file
    ImportDictionary(listView, parentGui) {
        fileDialog := FileSelect(1, A_ScriptDir, "Import Dictionary", "Text Files (*.txt; *.ini)")
        if (!fileDialog)
            return
        
        try {
            importCount := 0
            Loop Read, fileDialog {
                line := Trim(A_LoopReadLine)
                if (line && !InStr(line, "[") && InStr(line, "=")) {
                    pos := InStr(line, "=")
                    trigger := Trim(SubStr(line, 1, pos - 1))
                    expansion := Trim(SubStr(line, pos + 1))
                    
                    if (trigger && expansion && !this.Dictionary.Has(trigger)) {
                        this.Dictionary[trigger] := expansion
                        importCount++
                        
                        ; Register hotstring
                        try {
                            hotstringOptions := "::" trigger
                            Hotstring(hotstringOptions, ((text) => (*) => SendText(text))(expansion))
                        } catch {
                            ; Ignore registration errors
                        }
                    }
                }
            }
            
            if (importCount > 0) {
                this.PopulateManagerList(listView)
                this.SaveCustomEntries()
                ShowMouseTooltip("Imported " importCount " entries", 2000)
            } else {
                MsgBox("No new entries found to import.", "Import Complete", "Iconi")
            }
            
        } catch as e {
            MsgBox("Error importing file: " e.Message, "Import Error", "Iconx")
        }
    }
    
    ; Export dictionary to file
    ExportDictionary(parentGui) {
        fileDialog := FileSelect("S16", A_ScriptDir "\autocompletion_export.txt", "Export Dictionary", "Text Files (*.txt)")
        if (!fileDialog)
            return
        
        try {
            content := "; AutoCompletion Dictionary Export`n"
            content .= "; Format: trigger=expansion`n"
            content .= "; Generated: " A_Now "`n`n"
            
            content .= "[Built-in Entries]`n"
            for trigger, expansion in this.Dictionary {
                if (this.IsBuiltinEntry(trigger)) {
                    escapedExpansion := StrReplace(expansion, "`n", "\\n")
                    content .= trigger "=" escapedExpansion "`n"
                }
            }
            
            content .= "`n[Custom Entries]`n"
            for trigger, expansion in this.Dictionary {
                if (!this.IsBuiltinEntry(trigger)) {
                    escapedExpansion := StrReplace(expansion, "`n", "\\n")
                    content .= trigger "=" escapedExpansion "`n"
                }
            }
            
            FileDelete(fileDialog)
            FileAppend(content, fileDialog)
            
            ShowMouseTooltip("Dictionary exported to " fileDialog, 3000)
            
        } catch as e {
            MsgBox("Error exporting dictionary: " e.Message, "Export Error", "Iconx")
        }
    }
    
    ; Show plugin settings
    ShowPluginSettings(parentGui) {
        settingsGui := Gui("+Owner" parentGui.Hwnd, "AutoCompletion Settings")
        settingsGui.SetFont("s9", "Segoe UI")
        
        ; Settings
        settingsGui.Add("GroupBox", "x10 y10 w300 h90", "General Settings")
        
        enabledCheck := settingsGui.Add("Checkbox", "x20 y30", "Enable AutoCompletion")
        enabledCheck.Value := this.Settings.enabled
        
        caseCheck := settingsGui.Add("Checkbox", "x20 y55", "Case sensitive matching")
        caseCheck.Value := this.Settings.caseSensitive
        
        settingsGui.Add("Text", "x20 y80", "Trigger key: Tab (currently not configurable)")
        
        ; Statistics
        settingsGui.Add("GroupBox", "x10 y130 w300 h80", "Statistics")
        settingsGui.Add("Text", "x20 y150", "Total entries: " this.Dictionary.Count)
        settingsGui.Add("Text", "x20 y170", "Built-in: " this.GetBuiltinCount())
        settingsGui.Add("Text", "x20 y190", "Custom: " this.GetCustomCount())
        
        ; Buttons
        saveBtn := settingsGui.Add("Button", "x20 y230 w80 h30", "Save")
        cancelBtn := settingsGui.Add("Button", "x110 y230 w80 h30", "Cancel")
        resetBtn := settingsGui.Add("Button", "x200 y230 w80 h30", "Reset All")
        
        ; Event handlers
        saveBtn.OnEvent("Click", (*) => this.SavePluginSettings(enabledCheck.Value, caseCheck.Value, settingsGui))
        cancelBtn.OnEvent("Click", (*) => settingsGui.Destroy())
        resetBtn.OnEvent("Click", (*) => this.ResetAllSettings(settingsGui))
        settingsGui.OnEvent("Close", (*) => settingsGui.Destroy())
        
        settingsGui.Show("w320 h270")
    }
    
    ; Save plugin settings
    SavePluginSettings(enabled, caseSensitive, gui) {
        this.Settings.enabled := enabled
        this.Settings.caseSensitive := caseSensitive
        
        if (enabled) {
            this.Enable()
        } else {
            this.Disable()
        }
        
        ShowMouseTooltip("Settings saved", 1500)
        gui.Destroy()
    }
    
    ; Reset all settings
    ResetAllSettings(gui) {
        result := MsgBox("This will delete all custom entries and reset settings. Continue?", "Reset Confirmation", "YesNo Icon!")
        if (result = "Yes") {
            ; Clear custom entries
            for trigger, expansion in this.Dictionary.Clone() {
                if (!this.IsBuiltinEntry(trigger)) {
                    this.Dictionary.Delete(trigger)
                    try {
                        Hotstring("::" trigger, "")
                    } catch {
                        ; Ignore errors
                    }
                }
            }
            
            ; Reset settings
            this.Settings.enabled := true
            this.Settings.caseSensitive := false
            
            ; Delete custom file
            try {
                customFile := A_ScriptDir "\data\plugins\autocompletion_custom.ini"
                FileDelete(customFile)
            } catch {
                ; Ignore errors
            }
            
            ShowMouseTooltip("All settings and custom entries reset", 2000)
            gui.Destroy()
        }
    }
    
    ; Show help
    ShowHelp() {
        helpText := "AutoCompletion Help:`n`n"
        helpText .= "• Type any trigger word and press Tab to expand`n`n"
        
        helpText .= "Available Triggers:`n"
        helpText .= "• Contact: email, name, addr, phone, sig`n"
        helpText .= "• Common: btw, fyi, asap, thx, pls`n"
        helpText .= "• Development: lorem, todo, fixme, hack`n`n"
        
        helpText .= "Examples:`n"
        helpText .= "• btw + Tab → 'by the way'`n"
        helpText .= "• todo + Tab → 'TODO: '`n"
        helpText .= "• email + Tab → 'your.email@example.com'`n"
        helpText .= "• sig + Tab → 'Best regards,\\nYour Name'`n`n"
        
        helpText .= "Features:`n"
        helpText .= "• Custom Entries: Add your own via Plugin Settings`n`n"
        helpText .= "Note: Only Tab triggers expansion (not Space or Enter)"
        
        MsgBox(helpText, "AutoCompletion Help", "T15")
    }
    


    
    ; Removed all dynamic function methods - keeping only static text functionality


    

    

    

    

    

    

    


    ; Helper method to register static hotstrings properly
    RegisterStaticHotstring(hotstringOptions, text) {
        ; Create a closure that captures the text value immediately
        textToSend := text
        Hotstring(hotstringOptions, (*) => SendText(textToSend))
    }
    

} 
