# AHK-V2-Tools Development Guide

## 🔧 Development Environment Setup

### Prerequisites
- **AutoHotkey v2.0+** - [Download here](https://www.autohotkey.com/v2/)
- **Code Editor** - VS Code, Notepad++, or any text editor with AHK syntax support
- **Git** - For version control
- **Windows 10/11** - Development and testing platform

### Recommended VS Code Extensions
- **AutoHotkey Plus Plus** - Syntax highlighting and IntelliSense
- **AutoHotkey v2 Language Support** - Enhanced language features
- **GitLens** - Git integration and history

## 🏗️ Architecture Overview

### Core System Components

```
AHK-Tools-Plugins.ahk (Main Entry Point)
├── Global configuration and startup
├── Hotkey system management
├── Tray menu and UI coordination
└── Plugin system initialization

PluginSystem.ahk (Plugin Management)
├── Plugin discovery and loading
├── Plugin lifecycle management
├── Inter-plugin communication
└── Dependency resolution

SettingsManager.ahk (Configuration)
├── Settings GUI and forms
├── INI file management
├── Hotkey configuration
└── Theme and UI management
```

### Plugin Architecture

Each plugin is a self-contained class that implements:

```autohotkey
class YourPlugin {
    static Name := "Your Plugin Name"
    static Version := "1.0.0"
    static Description := "What your plugin does"
    static Author := "Your Name"
    static Dependencies := []  ; Array of required plugins
    
    __New() {
        ; Initialize plugin settings and data
        this.Settings := Map()
        this.LoadSettings()
    }
    
    Execute() {
        ; Main plugin functionality
        ; This method is called when plugin is activated
    }
    
    ShowSettings() {
        ; Display plugin configuration GUI
        ; Called from Settings > Plugins > Configure
    }
    
    LoadSettings() {
        ; Load plugin settings from INI file
    }
    
    SaveSettings() {
        ; Save plugin settings to INI file
    }
}
```

## 🔌 Creating New Plugins

### Step-by-Step Plugin Development

#### 1. Create Plugin File
```bash
# Create new plugin file
touch src/plugins/YourPlugin.ahk
```

#### 2. Basic Plugin Template
```autohotkey
; YourPlugin.ahk - Template for new plugins
#Requires AutoHotkey v2.0

class YourPlugin {
    static Name := "Your Plugin"
    static Version := "1.0.0"
    static Description := "Description of what your plugin does"
    static Author := "Your Name"
    static Dependencies := []
    
    __New() {
        ; Initialize settings with defaults
        this.Settings := Map(
            "enabled", true,
            "setting1", "default_value",
            "setting2", 100
        )
        
        ; Load saved settings
        this.LoadSettings()
    }
    
    Execute() {
        ; Main functionality goes here
        MsgBox("Hello from " . this.Name . "!", "Plugin Demo")
    }
    
    ShowSettings() {
        ; Create settings GUI
        settingsGui := Gui("+Resize", this.Name . " Settings")
        settingsGui.SetFont("s9", "Segoe UI")
        
        ; Add controls
        settingsGui.Add("Text", "x10 y10", "Plugin Configuration:")
        enabledCheck := settingsGui.Add("Checkbox", "x10 y30", "Enable Plugin")
        enabledCheck.Value := this.Settings["enabled"]
        
        ; Add save button
        saveBtn := settingsGui.Add("Button", "x10 y60 w100 h30", "Save")
        saveBtn.OnEvent("Click", (*) => this.SaveSettingsFromGui(enabledCheck, settingsGui))
        
        settingsGui.Show()
    }
    
    SaveSettingsFromGui(enabledCheck, gui) {
        this.Settings["enabled"] := enabledCheck.Value
        this.SaveSettings()
        gui.Destroy()
        MsgBox("Settings saved!", this.Name)
    }
    
    LoadSettings() {
        ; Load from INI file in data/plugins/
        iniFile := A_ScriptDir . "\src\data\plugins\" . StrLower(this.Name) . "_settings.ini"
        
        if (FileExist(iniFile)) {
            for key, defaultValue in this.Settings {
                value := IniRead(iniFile, "Settings", key, defaultValue)
                ; Convert string values back to appropriate types
                if (Type(defaultValue) = "Integer") {
                    this.Settings[key] := Integer(value)
                } else {
                    this.Settings[key] := value
                }
            }
        }
    }
    
    SaveSettings() {
        ; Save to INI file
        iniFile := A_ScriptDir . "\src\data\plugins\" . StrLower(this.Name) . "_settings.ini"
        
        ; Ensure directory exists
        dataDir := A_ScriptDir . "\src\data\plugins"
        if (!DirExist(dataDir)) {
            DirCreate(dataDir)
        }
        
        ; Write settings
        for key, value in this.Settings {
            IniWrite(value, iniFile, "Settings", key)
        }
    }
}
```

#### 3. Register Plugin
The plugin system automatically discovers `.ahk` files in the `src/plugins/` directory. No manual registration required.

#### 4. Test Plugin
1. **Reload** the main application
2. **Open Settings** > **Plugins**
3. **Find your plugin** in the list
4. **Enable and test** functionality

### Advanced Plugin Features

#### Inter-Plugin Communication
```autohotkey
; Access other plugins through the global plugin manager
global g_pluginManager

Execute() {
    ; Check if another plugin is available
    if (g_pluginManager.Plugins.Has("Currency Converter")) {
        otherPlugin := g_pluginManager.Plugins["Currency Converter"]
        ; Use other plugin's functionality
    }
}
```

#### Plugin Dependencies
```autohotkey
class AdvancedPlugin {
    static Dependencies := ["Currency Converter", "Auto Completion"]
    
    __New() {
        ; Plugin system ensures dependencies are loaded first
    }
}
```

#### Custom Hotkeys
```autohotkey
ShowSettings() {
    ; Add hotkey configuration
    hotkeyEdit := settingsGui.Add("Edit", "x10 y100 w200")
    hotkeyEdit.Text := this.Settings["hotkey"]
    
    ; Save hotkey and register it
    saveBtn.OnEvent("Click", (*) => this.RegisterHotkey(hotkeyEdit.Text))
}

RegisterHotkey(hotkeyString) {
    if (hotkeyString) {
        try {
            Hotkey(hotkeyString, (*) => this.Execute())
        } catch as e {
            MsgBox("Invalid hotkey: " . e.Message)
        }
    }
}
```

## 🧪 Testing and Debugging

### Debug Mode
Enable debug mode in Settings > General for detailed logging:
```autohotkey
; Check if debug mode is enabled
global g_settingsManager
if (g_settingsManager.GetSetting("General_DebugMode", false)) {
    OutputDebug("Debug message from " . this.Name)
}
```

### Error Handling
Always wrap potentially failing operations:
```autohotkey
Execute() {
    try {
        ; Your code here
        result := SomeRiskyOperation()
    } catch as e {
        ; Log error and show user-friendly message
        OutputDebug("Plugin error: " . e.Message)
        MsgBox("An error occurred. Check debug log for details.", this.Name, "Iconx")
    }
}
```

### Common Issues
1. **Plugin not loading**: Check class name matches filename
2. **Settings not saving**: Ensure data/plugins directory exists
3. **Hotkeys not working**: Verify hotkey string format
4. **GUI issues**: Test with different screen resolutions

## 📝 Code Style Guidelines

### Naming Conventions
- **Classes**: PascalCase (`EmailPasswordManager`)
- **Methods**: PascalCase (`ShowSettings`)
- **Variables**: camelCase (`settingsGui`)
- **Constants**: UPPER_CASE (`MAX_RETRIES`)

### Error Messages
- Use descriptive, user-friendly messages
- Include the plugin name in message titles
- Provide actionable information when possible

### Documentation
- Add comments for complex logic
- Document all public methods
- Include usage examples for complicated features

## 🚀 Contributing

### Pull Request Process
1. **Fork** the repository
2. **Create feature branch**: `git checkout -b feature/your-plugin`
3. **Develop and test** your changes
4. **Update documentation** if needed
5. **Submit pull request** with detailed description

### Code Review Checklist
- [ ] Plugin follows naming conventions
- [ ] Error handling implemented
- [ ] Settings persistence works
- [ ] No hardcoded paths or values
- [ ] Documentation updated
- [ ] Tested on Windows 10/11

### Release Process
1. **Update version numbers** in plugin metadata
2. **Update CHANGELOG.md** with new features
3. **Tag release**: `git tag v2.1.0`
4. **Create GitHub release** with binaries (if applicable)

## 🔧 Maintenance

### Regular Tasks
- **Update dependencies** (AutoHotkey versions)
- **Review and merge** community contributions
- **Monitor issues** and bug reports
- **Performance optimization** for large plugin sets

### Breaking Changes
When making breaking changes:
1. **Increment major version**
2. **Update migration guide**
3. **Provide backward compatibility** when possible
4. **Announce changes** in release notes 