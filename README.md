# AHK-V2-Tools

A collection of productivity tools and utilities built with AutoHotkey v2.

## ⚠️ Important Notice

**AHK-Tools-Unified.ahk is DEPRECATED** and will be removed in a future version.

**Please use `AHK-Tools-Plugins.ahk` instead** for the latest features and support.

## Features

- **Plugin System**: Modular architecture allows for easy extension with plugins
- **Settings Manager**: Comprehensive GUI for configuring all aspects of the application
- **Currency Converter**: Convert between currencies with real-time exchange rates
- **AutoCompletion**: Text expansion and autocompletion with customizable dictionary
- **Email & Password Manager**: Generate secure credentials, masked emails, and usernames
- **QR Code Reader**: Scan and decode QR codes from screen captures
- **WiFi Reconnect**: Automated WiFi connection management

- **Customizable Hotkeys**: Global shortcuts for common tasks
- **Modern UI**: Clean, consistent interface across all tools

## Requirements

- AutoHotkey v2.0 or newer
- Windows 10/11

## File Structure

```
AHK-V2-Tools/
├── src/
│   ├── AHK-Tools-Plugins.ahk    # Main application entry point
│   ├── PluginSystem.ahk         # Core plugin system
│   ├── SettingsManager.ahk      # Settings management GUI
│   ├── settings.ini             # Main application settings
│   ├── plugins/                 # Plugin .ahk files
│   │   ├── AutoCompletion.ahk
│   │   ├── CurrencyConverter.ahk
│   │   ├── EmailPasswordManager.ahk
│   │   ├── QRReader.ahk
│   │   ├── WiFiReconnect.ahk

│   ├── data/                    # Plugin data and configuration
│   │   └── plugins/
│   │       ├── autocompletion_custom.ini    # Custom autocompletion entries
│   │       └── emailpassword_settings.ini   # Email/password plugin settings
│   ├── cache/                   # Temporary cache files
│   │   └── currency_rates.json
│   └── credentials/             # Saved credential files
│       └── [timestamped files]
├── README.md
└── .gitignore
```

## Installation

1. Download the latest release from the GitHub repository
2. Extract the files to a location of your choice
3. **Run `src/AHK-Tools-Plugins.ahk`** to start the application (NOT the unified version)

## Migration from Unified Version

If you were using `AHK-Tools-Unified.ahk`:

1. **Stop the unified script** if it's running
2. **Run `src/AHK-Tools-Plugins.ahk` instead**
3. Your settings will be automatically imported
4. The unified script will show a deprecation notice and offer to switch automatically

## Plugin System

AHK-V2-Tools comes with a flexible plugin system that allows you to add new functionality:

### Using Plugins

1. Plugins are automatically loaded from the `src/plugins/` directory
2. Access the Plugin Manager from the tray menu
3. Enable or disable plugins as needed
4. Configure plugin settings through the settings button

### Plugin Data Storage

- Plugin configuration files are stored in `src/data/plugins/`
- Each plugin can have its own settings file (e.g., `emailpassword_settings.ini`)
- Custom user data files are automatically created and managed
- Cache files are stored in `src/cache/` for temporary data
- AutoCompletion uses built-in entries plus custom entries from `autocompletion_custom.ini`

### Creating Plugins

To create a custom plugin:

1. Create a new .ahk file in the `src/plugins/` directory
2. Extend the base `Plugin` class
3. Implement the required methods (Initialize, Enable, Disable)
4. Store plugin data in `A_ScriptDir "\data\plugins\yourplugin_settings.ini"`
5. Add your custom functionality

## Settings Manager

The Settings Manager provides a comprehensive GUI for configuring all aspects of AHK-V2-Tools:

### Features

- **General Settings**: Startup options, appearance, language, and theme
- **Plugin Management**: Enable/disable plugins, configure plugin settings
- **Hotkey Configuration**: Customize global hotkeys and tooltips
- **AutoCompletion**: Configure text expansion and dictionary management
- **Text Replacement**: Manage text replacement rules and patterns
- **Performance**: Optimize memory usage, CPU usage, and caching
- **Security**: Configure admin requirements, logging, and encryption

### Access Methods

1. **Hotkey**: Press `Win + F5` to open the Settings Manager
2. **Tray Menu**: Right-click the tray icon and select "Settings"
3. **Plugin Manager**: Access individual plugin settings from the Plugin Manager

### Configuration Tabs

- **General**: Basic application settings and appearance
- **Plugins**: Enable/disable plugins and access plugin-specific settings
- **Hotkeys**: Configure global hotkeys and their behavior
- **Autocompletion**: Manage text expansion dictionary and settings
- **Text Replace**: Configure text replacement rules and patterns
- **Performance**: Optimize application performance and resource usage
- **Security**: Configure security settings and access controls

Example plugin template:

```autohotkey
#Requires AutoHotkey v2.0-*

class YourPluginNamePlugin extends Plugin {
    ; Plugin metadata
    static Name := "Your Plugin Name"
    static Description := "Description of your plugin"
    static Version := "1.0.0"
    static Author := "Your Name"
    
    ; Initialize the plugin
    Initialize() {
        ; Register hotkeys, create GUIs, etc.
        ; Use A_ScriptDir "\data\plugins\yourplugin_settings.ini" for data storage
        return true
    }
    
    ; Enable the plugin
    Enable() {
        ; Enable functionality
        this.Enabled := true
        return true
    }
    
    ; Disable the plugin
    Disable() {
        ; Disable functionality
        this.Enabled := false
        return true
    }
    
    ; Load plugin settings
    LoadSettings() {
        settingsFile := A_ScriptDir "\data\plugins\yourplugin_settings.ini"
        ; Load your settings from the unified data location
    }
    
    ; Save plugin settings
    SaveSettings() {
        settingsFile := A_ScriptDir "\data\plugins\yourplugin_settings.ini"
        ; Save your settings to the unified data location
    }
    
    ; Add your custom methods here
}
```

## Default Hotkeys

| Hotkey | Function |
|--------|----------|
| Win + F1 | Show help dialog |
| Win + F5 | Open Settings Manager |
| Win + Del | Suspend/Resume script |
| Win + Enter | Open Terminal as Administrator |
| Alt + C | Currency Converter (from Currency Converter plugin) |
| Ctrl + Alt + A | AutoCompletion Manager (from AutoCompletion plugin) |

## Plugin Features

### AutoCompletion Plugin
- Text expansion with customizable triggers
- Built-in static entries for common abbreviations
- Custom user-defined entries via settings interface
- Simple and efficient text replacement system

### Currency Converter Plugin
- Real-time exchange rates
- Multiple currency support
- Configurable update intervals
- Cached rates for offline use

### Email & Password Manager Plugin
- Gmail+ email masking
- Temporary email integration
- Username generation with templates
- Secure password generation
- Bitwarden CLI integration
- Credential history tracking

### QR Reader Plugin
- Screen capture QR code scanning
- Multiple QR detection engines
- Automatic clipboard copy
- Real-time scanning mode

### WiFi Reconnect Plugin
- Automatic WiFi connection monitoring
- Connection recovery on failures
- Configurable retry intervals
- Network status notifications



## License

MIT License - See LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

