# Changelog

All notable changes to AHK Tools will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Version control system implementation
- Comprehensive version management documentation
- CHANGELOG.md for tracking all changes

## [2.1.0] - 2024-12-XX

### Added
- **LibGen Book Download feature** - New hotkey `Alt+B` to search and download books from LibGen
- **Enhanced suspend/resume functionality** - Improved script suspension with visual feedback
- **Dynamic tray menu** - Tray menu now shows current suspend/resume state
- **Tray notifications** - Visual feedback when script is suspended or resumed
- **Currency Converter plugin** (v3.0.0) - Comprehensive currency conversion with 90+ currencies
- **Unit Converter plugin** (v1.0.0) - Advanced unit conversion with 20+ categories
- **AutoCompletion plugin** - Smart text completion and suggestions

### Changed
- **Improved error handling** - Fixed "Gui has no window" error in command type choice dialog
- **Enhanced suspend system** - Replaced built-in `Suspend` command with custom state management
- **Better user feedback** - Added tooltips and notifications for user actions
- **Refined hotkey management** - Wrapped hotkey functions with conditional execution

### Fixed
- **GUI error handling** - Fixed race condition in `ShowCommandTypeChoiceDialog()` function
- **Suspend/resume hotkey** - Fixed issue where Win+Del couldn't resume script after suspension
- **Tray icon feedback** - Restored visual feedback for suspended state
- **LibGen URL format** - Corrected search URL to use proper LibGen format

### Technical Improvements
- **Global state management** - Added `g_scriptSuspended` variable for better state tracking
- **Hotkey wrapper function** - Created `ExecuteHotkeyFunction()` for conditional execution
- **Error handling** - Added try-catch blocks for robust error handling
- **Code organization** - Improved code structure and documentation

## [2.0.1] - 2024-11-XX

### Added
- **Category recognition legend** - Enhanced README with shortcut category descriptions
- **Improved startup feedback** - Better GUI success message on script startup

### Changed
- **Shortcut descriptions** - Refined and clarified all hotkey descriptions
- **Documentation** - Updated README with better structure and clarity

## [2.0.0] - 2024-11-XX

### Added
- **Complete AutoHotkey v2 rewrite** - Full migration from v1 to v2
- **Plugin system architecture** - Modular plugin-based design
- **Settings management system** - Centralized settings with INI file support
- **Enhanced error handling** - Comprehensive error catching and user feedback
- **Global message box functions** - Standardized message box handling
- **Mouse tooltip system** - Advanced tooltip with mouse following
- **URL encoding utilities** - Built-in URL encoding for web requests
- **Command execution system** - PowerShell and CMD execution with choice dialog
- **Hotkey management** - Dynamic hotkey setup and clearing
- **Tray menu system** - Comprehensive system tray integration
- **About dialog** - Retro-style about window with version information
- **Plugin manager** - GUI for enabling/disabling plugins
- **Settings GUI** - User-friendly settings configuration
- **Backup system** - Automatic settings backup functionality

### Changed
- **Architecture** - Complete redesign from monolithic to modular
- **Code organization** - Separated concerns into multiple files
- **Error handling** - Implemented robust error handling throughout
- **User interface** - Modern GUI design with better UX

### Removed
- **Legacy v1 code** - Removed all AutoHotkey v1 compatibility code
- **Deprecated plugins** - Removed Email & Password Manager, QR Reader, WiFi Reconnect
- **Unified script** - Removed AHK-Tools-Unified.ahk in favor of modular approach

## [1.x.x] - 2024-XX-XX

### Legacy Versions
- **v1.x.x** - Original AutoHotkey v1 implementation
- **Features**: Basic hotkeys, simple GUI, limited functionality
- **Status**: Deprecated, no longer supported

---

## Version Compatibility

### AutoHotkey Requirements
- **v2.0.0+**: Requires AutoHotkey v2.0 or higher
- **v1.x.x**: Required AutoHotkey v1.1 (deprecated)

### Windows Requirements
- **v2.0.0+**: Windows 10/11
- **v1.x.x**: Windows 7/8/10 (deprecated)

## Migration Notes

### From v1.x.x to v2.0.0
- **Breaking Changes**: Complete rewrite, no backward compatibility
- **New Requirements**: AutoHotkey v2.0+
- **Plugin System**: New plugin architecture
- **Settings**: New settings format, manual migration required

### From v2.0.0 to v2.1.0
- **Backward Compatible**: All existing functionality preserved
- **New Features**: Additional plugins and features
- **Enhanced UX**: Better user feedback and error handling

## Contributing

When contributing to this project, please:

1. **Update this changelog** for any user-facing changes
2. **Follow semantic versioning** for version numbers
3. **Test thoroughly** before submitting changes
4. **Document new features** in README.md
5. **Update version numbers** in all relevant files

## Release Process

### For Patch Releases (2.1.0 → 2.1.1)
1. Fix bugs or minor issues
2. Update version in `src/AHK-Tools-Plugins.ahk`
3. Update this changelog
4. Create git tag: `git tag AHK-2.1.1`
5. Push tag: `git push origin AHK-2.1.1`

### For Minor Releases (2.1.0 → 2.2.0)
1. Add new features (backward compatible)
2. Update version in `src/AHK-Tools-Plugins.ahk`
3. Update this changelog
4. Update `README.md` with new features
5. Create git tag: `git tag AHK-2.2.0`
6. Push tag: `git push origin AHK-2.2.0`

### For Major Releases (2.1.0 → 3.0.0)
1. Make breaking changes
2. Update version in `src/AHK-Tools-Plugins.ahk`
3. Update this changelog
4. Update all documentation
5. Create git tag: `git tag AHK-3.0.0`
6. Push tag: `git push origin AHK-3.0.0`

---

*This changelog is maintained by Ahmed N. Alfahdi*
*For more information, see [VERSION.md](VERSION.md)* 