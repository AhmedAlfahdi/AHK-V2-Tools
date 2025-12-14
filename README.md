# AHK-V2-Tools

A collection of productivity tools and utilities built with AutoHotkey v2.

<img width="880" height="658" alt="{D13D8608-F08F-4A30-8D4D-FFCD825F1299}" src="https://github.com/user-attachments/assets/988325c8-1824-43bb-bd22-ca4d436aa367" />
---
<img width="880" height="658" alt="{57EE4958-FD47-4B1B-A6EE-9F35D8672AA2}" src="https://github.com/user-attachments/assets/e1367496-a843-42c7-8428-a4e986adaac6" />


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
├── scripts/                     # Version control scripts
│   ├── update_version.ahk       # AutoHotkey version updater
│   ├── version_control.ps1      # PowerShell version control
│   └── version.bat              # Batch version control
├── README.md
├── VERSION.md                   # Version management
├── CHANGELOG.md                 # Change history
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
| Alt + B | LibGen Book Download |
| Alt + Y | YouTube Search |

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

### LibGen Book Download
- Quick access to Library Genesis for book downloads
- Select book title or author text and press Alt+B
- Opens LibGen search page with selected text
- Also works with manual input if no text is selected

### YouTube Search
- Quick YouTube search functionality
- Select search term text and press Alt+Y
- Opens YouTube search results page with selected text
- Also works with manual input if no text is selected

## Settings Manager

Access via Win + F5 or tray menu. Tabs:
- General: Startup, appearance, language
- Plugins: Enable/disable, plugin settings
- Hotkeys: Customize global shortcuts
- Autocompletion: Text expansion settings
- Performance: Memory and CPU optimization
- Security: Admin requirements, logging

## Version Control

The project uses a comprehensive version control system with multiple tools:

### Version Management Files
- **VERSION.md**: Complete version history and strategy
- **CHANGELOG.md**: Detailed change tracking
- **scripts/update_version.ahk**: AutoHotkey GUI for version updates
- **scripts/version_control.ps1**: PowerShell version control automation
- **scripts/version.bat**: Batch file for easy version operations

### Quick Version Commands
```bash
# Show current version info
version.bat info

# Suggest next version
version.bat suggest patch

# Update version using GUI
version.bat update

# Create git tag
version.bat tag 2.1.1

# Show release checklist
version.bat checklist 2.1.1
```

### Version Update Process
1. **Update version**: `version.bat update` or edit `src/AHK-Tools-Plugins.ahk`
2. **Test functionality**: Ensure all features work correctly
3. **Update documentation**: Modify README.md, VERSION.md, CHANGELOG.md
4. **Create git tag**: `version.bat tag 2.1.1`
5. **Push to remote**: `git push origin AHK-2.1.1`

### Semantic Versioning
- **MAJOR.MINOR.PATCH** format (e.g., 2.1.0)
- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes

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
