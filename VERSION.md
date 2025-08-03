# AHK Tools Version Control

## Current Version
**v2.1.0** - Latest stable release

## Version History

### v2.1.0 (Current)
- **Release Date**: December 2024
- **Status**: Stable
- **Key Features**:
  - LibGen Book Download feature (Alt+B)
  - Enhanced suspend/resume functionality
  - Improved tray menu with dynamic suspend/resume options
  - Fixed GUI error handling in command type choice dialog
  - Currency Converter plugin (v3.0.0)
  - Unit Converter plugin (v1.0.0)
  - AutoCompletion plugin

### v2.0.1
- **Release Date**: November 2024
- **Status**: Stable
- **Key Features**:
  - Enhanced README with category recognition legend
  - Improved GUI success message on startup
  - Refined shortcut descriptions for clarity

### v2.0.0
- **Release Date**: November 2024
- **Status**: Stable
- **Key Features**:
  - Complete rewrite for AutoHotkey v2
  - Plugin system architecture
  - Modular design
  - Enhanced error handling

## Versioning Strategy

### Semantic Versioning (SemVer)
We follow [Semantic Versioning 2.0.0](https://semver.org/):

- **MAJOR.MINOR.PATCH**
  - **MAJOR**: Incompatible API changes
  - **MINOR**: New functionality in a backwards compatible manner
  - **PATCH**: Backwards compatible bug fixes

### Version Components
- **Script Version**: `2.1.0` (in CONFIG.version)
- **Plugin Versions**: Individual plugin versions (e.g., CurrencyConverter v3.0.0)
- **Git Tags**: `AHK-2.1.0`, `AHK-2.0.1`, etc.

## Version Update Process

### For Minor Updates (2.1.0 → 2.1.1)
1. Update `CONFIG.version` in `src/AHK-Tools-Plugins.ahk`
2. Update this file
3. Create git tag: `git tag AHK-2.1.1`
4. Push tag: `git push origin AHK-2.1.1`

### For Major Updates (2.1.0 → 2.2.0)
1. Update `CONFIG.version` in `src/AHK-Tools-Plugins.ahk`
2. Update this file
3. Update `README.md` with new features
4. Create git tag: `git tag AHK-2.2.0`
5. Push tag: `git push origin AHK-2.2.0`

## Plugin Version Management

### Current Plugin Versions
- **CurrencyConverter**: v3.0.0
- **UnitConverter**: v1.0.0
- **AutoCompletion**: v1.0.0
- **PluginSystem**: v1.0.0

### Plugin Version Update Process
1. Update plugin's `static Version` property
2. Update this file
3. Test plugin functionality
4. Commit changes with descriptive message

## Release Checklist

### Before Release
- [ ] Update version numbers in all relevant files
- [ ] Test all functionality
- [ ] Update documentation
- [ ] Create git tag
- [ ] Push to remote repository
- [ ] Update this file

### Release Notes Template
```
## AHK Tools vX.X.X

### New Features
- Feature 1
- Feature 2

### Bug Fixes
- Fix 1
- Fix 2

### Improvements
- Improvement 1
- Improvement 2

### Breaking Changes
- None (or list if any)

### Dependencies
- AutoHotkey v2.0+
- No additional dependencies required
```

## Version Control Commands

### Create New Version
```bash
# Update version in script
# Create tag
git tag AHK-2.1.1

# Push tag
git push origin AHK-2.1.1

# Create release on GitHub (manual)
```

### View Version History
```bash
# View all tags
git tag -l

# View commit history
git log --oneline

# View specific version
git show AHK-2.1.0
```

### Rollback to Previous Version
```bash
# Checkout specific version
git checkout AHK-2.1.0

# Or reset to specific commit
git reset --hard <commit-hash>
```

## Future Version Roadmap

### v2.2.0 (Planned)
- Enhanced plugin management
- Additional unit conversion categories
- Improved error handling
- Performance optimizations

### v2.3.0 (Planned)
- Advanced automation features
- Custom hotkey profiles
- Plugin marketplace integration
- Enhanced UI/UX

## Version Compatibility

### AutoHotkey Version Requirements
- **Minimum**: AutoHotkey v2.0
- **Recommended**: AutoHotkey v2.1+
- **Tested**: AutoHotkey v2.0.10

### Windows Version Requirements
- **Minimum**: Windows 10
- **Recommended**: Windows 11
- **Tested**: Windows 10/11

## Support and Maintenance

### Version Support Policy
- **Current Version**: Full support
- **Previous Major Version**: Bug fixes only
- **Older Versions**: No support

### Update Frequency
- **Major Releases**: Every 6-12 months
- **Minor Releases**: Every 2-3 months
- **Patch Releases**: As needed for critical fixes

---

*Last Updated: December 2024*
*Maintained by: Ahmed N. Alfahdi* 