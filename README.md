# AHK-V2-Tools

A collection of productivity tools and utilities built with AutoHotkey v2.

## Requirements

- AutoHotkey v2.0 or newer
- Windows 10/11

## Installation

1. Download and extract the files
2. Run `src/AHK-Tools-Plugins.ahk`


## File Structure

```
AHK-V2-Tools/
├── src/
│   ├── AHK-Tools-Plugins.ahk    # Main application
│   ├── PluginSystem.ahk         # Plugin system
│   ├── SettingsManager.ahk      # Settings management
│   ├── settings.ini             # Application settings
│   ├── plugins/                 # Plugin files
│   │   ├── AutoCompletion.ahk
│   │   ├── CurrencyConverter.ahk
│   │   └── UnitConverter.ahk
│   ├── data/plugins/            # Plugin data
│   └── cache/                   # Temporary files
├── README.md
└── UNIT_REFERENCE.md           # Unit converter reference
```

## Default Hotkeys

| Hotkey | Function |
|--------|----------|
| Win + F1 | Help dialog |
| Win + F5 | Settings Manager |
| Win + Del | Suspend/Resume script |
| Win + Enter | Terminal as Administrator |
| Alt + C | Currency Converter |
| Ctrl + Alt + A | AutoCompletion Manager |
| Alt + U | Unit Converter |
| Alt + T | Run Selected Command (CMD/PowerShell) |

## Plugins

### AutoCompletion
- Text expansion with customizable triggers
- Built-in abbreviations + custom entries
- Settings interface for management

### Currency Converter
- Real-time exchange rates with caching
- Multiple currency support
- Configurable update intervals

### Unit Converter
- 25 categories, 300+ units
- SI, Imperial, CGS, and specialized units
- Text recognition: Select "100 kg" and press Alt+U
- Categories: Length, Weight, Volume, Area, Speed, Energy, Power, Pressure, Temperature, Data Storage, Time, Frequency, Force, Torque, Electrical, Magnetic, Angular, Acceleration, Density, Viscosity, Optical
- See [UNIT_REFERENCE.md](UNIT_REFERENCE.md) for complete list

## Settings Manager

Access via Win + F5 or tray menu. Tabs:
- General: Startup, appearance, language
- Plugins: Enable/disable, plugin settings
- Hotkeys: Customize global shortcuts
- Autocompletion: Text expansion settings
- Performance: Memory and CPU optimization
- Security: Admin requirements, logging

## Creating Plugins

1. Create `.ahk` file in `src/plugins/`
2. Extend base `Plugin` class
3. Implement required methods: `Initialize()`, `Enable()`, `Disable()`
4. Store data in `A_ScriptDir "\data\plugins\yourplugin_settings.ini"`

Basic template:

```autohotkey
#Requires AutoHotkey v2.0-*

class YourPluginNamePlugin extends Plugin {
    static Name := "Your Plugin Name"
    static Description := "Plugin description"
    static Version := "1.0.0"
    static Author := "Your Name"
    
    Initialize() {
        ; Setup code
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
}
```

## License

MIT License - See LICENSE file for details.

## Contributing

1. Fork the repository
2. Create feature branch
3. Commit changes
4. Push and create Pull Request