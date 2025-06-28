# AHK-V2-Tools Project Structure

## 📁 Directory Organization

```
AHK-V2-Tools/
├── 📄 README.md                    # Main project documentation
├── 📄 STRUCTURE.md                 # This file - project structure guide
├── 📄 .gitignore                   # Git exclusion rules
└── 📁 src/                         # Source code directory
    ├── 📄 AHK-Tools-Plugins.ahk    # Main application entry point
    ├── 📄 PluginSystem.ahk         # Plugin management system
    ├── 📄 SettingsManager.ahk      # Settings and configuration management
    ├── 📄 settings.ini             # User settings (auto-generated)
    ├── 📁 plugins/                 # Plugin implementations
    │   ├── 📄 AutoCompletion.ahk   # Text auto-completion plugin
    │   ├── 📄 CurrencyConverter.ahk # Currency conversion plugin
    │   ├── 📄 EmailPasswordManager.ahk # Email/password management plugin
    │   ├── 📄 QRReader.ahk         # QR code reading plugin
    │   ├── 📄 WiFiReconnect.ahk    # Wi-Fi reconnection plugin
    
    ├── 📁 data/                    # User data storage
    │   └── 📁 plugins/             # Plugin-specific data files
    │       ├── 📄 autocompletion_custom.ini    # Custom autocompletion entries
    │       └── 📄 emailpassword_settings.ini   # Email/password plugin settings
    ├── 📁 cache/                   # Temporary cache files
    │   └── 📄 currency_rates.json  # Cached currency conversion rates
    └── 📁 credentials/             # Generated credentials (user-created)
```

## 🚀 Getting Started

### Prerequisites
- **AutoHotkey v2.0** or later
- **Windows 10/11** (tested platforms)
- **Administrator privileges** (for some plugins)

### Installation
1. **Download/Clone** the repository
2. **Run** `src/AHK-Tools-Plugins.ahk`
3. **Configure** settings through the tray menu
4. **Enable plugins** as needed

## 🔧 Core Components

### Main Application
- **`AHK-Tools-Plugins.ahk`** - Entry point, hotkey management, system integration
- **`PluginSystem.ahk`** - Plugin discovery, loading, and lifecycle management  
- **`SettingsManager.ahk`** - Configuration GUI, settings persistence, hotkey management

### Plugin Architecture
Each plugin is a self-contained `.ahk` file in the `plugins/` directory that implements:
- **`Execute()`** method - Main plugin functionality
- **`ShowSettings()`** method - Plugin configuration interface
- **Plugin metadata** - Name, version, description, dependencies

## 📦 Plugin Descriptions

| Plugin | Purpose | Admin Required |
|--------|---------|----------------|
| **AutoCompletion** | Text expansion and auto-completion | No |
| **CurrencyConverter** | Real-time currency conversion | No |
| **EmailPasswordManager** | Generate emails, usernames, passwords | No |
| **QRReader** | Read QR codes from screen/clipboard | No |
| **WiFiReconnect** | Wi-Fi troubleshooting and DNS flush | Yes |


## 📁 File Types & Purposes

### Configuration Files
- **`settings.ini`** - Main application settings
- **`data/plugins/*.ini`** - Individual plugin configurations

### Cache & Temporary Files
- **`cache/*.json`** - API response caching (currency rates, etc.)
- **`credentials/*`** - User-generated credentials (optional encryption)

### Data Files
- **`data/plugins/autocompletion_custom.ini`** - User-defined text expansions
- **`data/plugins/emailpassword_settings.ini`** - Email/password plugin configuration

## 🔒 Security Considerations

### Credentials Storage
- **Plain Text Mode**: Files stored in readable format
- **Encrypted Mode**: ROT13 encryption for basic obfuscation
- **Location**: `src/credentials/` directory (excluded from git)

### Admin Privileges
Some plugins require administrator privileges:
- **Wi-Fi Reconnect**: Network interface control


## 🛠️ Development

### Adding New Plugins
1. **Create** `src/plugins/YourPlugin.ahk`
2. **Implement** required methods (`Execute()`, `ShowSettings()`)
3. **Add metadata** (name, version, description)
4. **Test** functionality and settings persistence

### Modifying Core System
- **Main hotkeys**: Edit `AHK-Tools-Plugins.ahk`
- **Plugin management**: Modify `PluginSystem.ahk`
- **Settings system**: Update `SettingsManager.ahk`

## 📝 Notes

### Version Control
- **Included**: Source code, documentation, base configurations
- **Excluded**: User data, logs, credentials, cache files, personal shortcuts

### Backup Recommendations
- **Export settings** before major updates
- **Backup** `data/plugins/` for custom configurations
- **Save** important credentials before cleanup

### Troubleshooting
- **Enable debug mode** in settings for detailed logging
- **Check permissions** for admin-required plugins
- **Restart as admin** if needed (available in tray menu) 