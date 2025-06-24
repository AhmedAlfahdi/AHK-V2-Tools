#Requires AutoHotkey v2.0-*

; =================== PLUGIN SYSTEM ===================
; Plugin System for AHK Tools

; Base Plugin Class - All plugins must extend this
class Plugin {
    ; Plugin metadata
    static Name := "Base Plugin"
    static Description := "Base plugin class that all plugins should extend"
    static Version := "1.0.0"
    static Author := "AHK Tools"
    
    ; Plugin state
    Enabled := false
    
    ; Constructor
    __New() {
        ; Initialize plugin
    }
    
    ; Required methods that all plugins must implement
    Initialize() {
        ; Initialize the plugin
        return true
    }
    
    Enable() {
        this.Enabled := true
        return true
    }
    
    Disable() {
        this.Enabled := false
        return true
    }
    
    ; Optional methods
    OnHotkey(hotkeyName) {
        ; Called when a registered hotkey is triggered
        return true
    }
    
    ShowSettings() {
        ; Show settings dialog for this plugin
        return true
    }
}

; Plugin Manager - Handles loading, enabling, and disabling plugins
class PluginManager {
    ; Stores all loaded plugins
    Plugins := Map()
    
    ; Path to plugins directory
    PluginsPath := A_ScriptDir "\plugins"
    
    ; Constructor
    __New() {
        ; Ensure plugins directory exists
        if !DirExist(this.PluginsPath)
            DirCreate(this.PluginsPath)
    }
    
    ; Load all plugins from the plugins directory
    LoadPlugins() {
        ; Since plugin classes are included via #Include, directly instantiate known plugins
        pluginCount := 0
        
        ; Load CurrencyConverter plugin
        try {
            plugin := CurrencyConverterPlugin()
            this.RegisterPlugin(plugin)
            pluginCount++
        } catch as e {
            ; Plugin not available or error loading
        }
        
        ; Load AutoCompletion plugin
        try {
            plugin := AutoCompletionPlugin()
            this.RegisterPlugin(plugin)
            pluginCount++
        } catch as e {
            ; Plugin not available or error loading
        }
        
        ; Load Windows File Integrity plugin
        try {
            plugin := WindowsFileIntegrityPlugin()
            this.RegisterPlugin(plugin)
            pluginCount++
        } catch as e {
            ; Plugin not available or error loading
        }
        
        ; Load Wi-Fi Reconnect plugin
        try {
            plugin := WiFiReconnectPlugin()
            this.RegisterPlugin(plugin)
            pluginCount++
        } catch as e {
            ; Plugin not available or error loading
        }
        
        ; Load QR Reader plugin
        try {
            plugin := QRReaderPlugin()
            this.RegisterPlugin(plugin)
            pluginCount++
        } catch as e {
            ; Plugin not available or error loading
        }
        
        ; Load Email & Password Manager plugin
        try {
            plugin := EmailPasswordManagerPlugin()
            this.RegisterPlugin(plugin)
            pluginCount++
        } catch as e {
            ; Plugin not available or error loading
        }
        
        ; Load saved plugin states after all plugins are loaded
        this.LoadPluginStates()
        
        return pluginCount
    }
    
    ; Load a single plugin from file (kept for future dynamic loading)
    LoadPlugin(pluginFile) {
        try {
            ; Extract plugin name from filename
            SplitPath pluginFile, &fileName, , , &pluginName
            
            ; Assume plugin class name is [PluginName]Plugin
            pluginClassName := pluginName "Plugin"
            
            ; Try to instantiate the plugin (class should be available via #Include in main script)
            try {
                ; For now, we handle known plugins in LoadPlugins() method
                ; This method is kept for future dynamic plugin loading
                return false
            } catch as e {
                TopMsgBox("Error instantiating plugin: " pluginClassName "`n" e.Message, "Plugin Error", "Iconx")
                return false
            }
        } catch as e {
            TopMsgBox("Error loading plugin: " pluginFile "`n" e.Message, "Plugin Error", "Iconx")
            return false
        }
    }
    
    ; Register a plugin instance
    RegisterPlugin(plugin) {
        ; Store plugin by name (access static property correctly)
        try {
            ; Access static property through the class type
            pluginClass := Type(plugin)
            pluginName := %pluginClass%.Name
            this.Plugins[pluginName] := plugin
            
            ; Initialize the plugin
            plugin.Initialize()
            
            return true
        } catch as e {
            ; Fallback: use class name if static Name property fails
            className := Type(plugin)
            this.Plugins[className] := plugin
            plugin.Initialize()
            return true
        }
    }
    
    ; Enable a specific plugin
    EnablePlugin(pluginName) {
        if this.Plugins.Has(pluginName) {
            this.Plugins[pluginName].Enable()
            TopMsgBox("Plugin '" pluginName "' has been enabled.", "Plugin Manager")
            
            ; Save state
            this.SavePluginStates()
        }
    }
    
    ; Disable a specific plugin
    DisablePlugin(pluginName) {
        if this.Plugins.Has(pluginName) {
            this.Plugins[pluginName].Disable()
            TopMsgBox("Plugin '" pluginName "' has been disabled.", "Plugin Manager")
            
            ; Save state
            this.SavePluginStates()
        }
    }
    
    ; Enable all plugins
    EnableAllPlugins() {
        for pluginName, plugin in this.Plugins {
            plugin.Enable()
        }
    }
    
    ; Disable all plugins
    DisableAllPlugins() {
        for pluginName, plugin in this.Plugins {
            plugin.Disable()
        }
    }
    
    ; Show plugin management dialog
    ShowPluginManager() {
        pluginGui := Gui("+AlwaysOnTop", "Plugin Manager")
        pluginGui.SetFont("s10", "Segoe UI")
        
        ; Create listview to display plugins
        pluginListView := pluginGui.Add("ListView", "w600 h300", ["Plugin", "Version", "Author", "Status", "Description"])
        
        ; Add plugins to listview
        for pluginName, plugin in this.Plugins {
            status := plugin.Enabled ? "Enabled" : "Disabled"
            ; Access static properties correctly
            pluginClass := Type(plugin)
            try {
                version := %pluginClass%.Version
                author := %pluginClass%.Author
                description := %pluginClass%.Description
            } catch {
                version := "Unknown"
                author := "Unknown"
                description := "No description available"
            }
            pluginListView.Add(, pluginName, version, author, status, description)
        }
        
        ; Auto-size columns
        pluginListView.ModifyCol(1, 150)  ; Plugin name
        pluginListView.ModifyCol(2, 80)   ; Version
        pluginListView.ModifyCol(3, 100)  ; Author
        pluginListView.ModifyCol(4, 80)   ; Status
        pluginListView.ModifyCol(5, 190)  ; Description
        
        ; Buttons
        btnEnable := pluginGui.Add("Button", "x10 y320 w100", "Enable")
        btnEnable.OnEvent("Click", (*) => this.EnableSelectedPlugin(pluginListView))
        
        btnDisable := pluginGui.Add("Button", "x120 y320 w100", "Disable")
        btnDisable.OnEvent("Click", (*) => this.DisableSelectedPlugin(pluginListView))
        
        btnSettings := pluginGui.Add("Button", "x230 y320 w100", "Settings")
        btnSettings.OnEvent("Click", (*) => this.ShowSelectedPluginSettings(pluginListView))
        
        btnClose := pluginGui.Add("Button", "x490 y320 w100", "Close")
        btnClose.OnEvent("Click", (*) => pluginGui.Destroy())
        
        ; Set close on escape
        pluginGui.OnEvent("Escape", (*) => pluginGui.Destroy())
        
        ; Show the GUI
        pluginGui.Show()
    }
    
    ; Enable the selected plugin in the listview
    EnableSelectedPlugin(listView) {
        if listView.GetNext() {
            selectedRow := listView.GetNext()
            pluginName := listView.GetText(selectedRow, 1)
            
            if this.EnablePlugin(pluginName) {
                listView.Modify(selectedRow, , , , , "Enabled")
            }
        }
    }
    
    ; Disable the selected plugin in the listview
    DisableSelectedPlugin(listView) {
        if listView.GetNext() {
            selectedRow := listView.GetNext()
            pluginName := listView.GetText(selectedRow, 1)
            
            if this.DisablePlugin(pluginName) {
                listView.Modify(selectedRow, , , , , "Disabled")
            }
        }
    }
    
    ; Show settings for the selected plugin
    ShowSelectedPluginSettings(listView) {
        if listView.GetNext() {
            selectedRow := listView.GetNext()
            pluginName := listView.GetText(selectedRow, 1)
            
            if this.Plugins.Has(pluginName) {
                this.Plugins[pluginName].ShowSettings()
            }
        }
    }
    
    ; Save plugin states to file
    SavePluginStates() {
        statesFile := A_ScriptDir "\plugin_states.txt"
        try {
            content := "; Plugin States Configuration`n"
            content .= "; Generated on " FormatTime() "`n`n"
            
            for pluginName, plugin in this.Plugins {
                enabled := plugin.Enabled ? "true" : "false"
                content .= pluginName "=" enabled "`n"
            }
            
            FileDelete statesFile
            FileAppend content, statesFile
        } catch as e {
            ; Ignore errors saving plugin states
        }
    }
    
    ; Load plugin states from file
    LoadPluginStates() {
        statesFile := A_ScriptDir "\plugin_states.txt"
        if (!FileExist(statesFile)) {
            return ; Use default states
        }
        
        try {
            Loop Read, statesFile {
                line := Trim(A_LoopReadLine)
                if (line = "" || SubStr(line, 1, 1) = ";")
                    continue
                    
                if (InStr(line, "=")) {
                    parts := StrSplit(line, "=", , 2)
                    if (parts.Length = 2) {
                        pluginName := Trim(parts[1])
                        enabled := (Trim(parts[2]) = "true")
                        
                        if (this.Plugins.Has(pluginName)) {
                            if (enabled) {
                                this.Plugins[pluginName].Enable()
                            } else {
                                this.Plugins[pluginName].Disable()
                            }
                        }
                    }
                }
            }
        } catch as e {
            ; Ignore errors loading plugin states
        }
    }
}

; TopMsgBox and ShowMouseTooltip functions are defined in main file 