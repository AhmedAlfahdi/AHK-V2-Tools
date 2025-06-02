# AHK-Tools (AutoHotkey v2)

A productivity script for Windows power users, providing custom hotkeys for quick access, automation, and workflow enhancements.

## Features
- Calculator, terminal, and system utilities shortcuts
- Force quit apps, system power options, Wi-Fi/DNS tools
- Numpad mode toggle (Win+F2)
- Quick search: DuckDuckGo, Perplexity, WolframAlpha, game DBs
- Currency converter with auto-detection of amounts and symbols
- Open selected text in Notepad or editor
- File integrity check, hourly chime, and more

## Requirements
- **AutoHotkey v2.0+** (https://www.autohotkey.com/v2/)
- **Python 3.x** (required for currency converter live exchange rates)

## Installation
1. Install AutoHotkey v2
2. Install Python 3.x (for currency converter functionality)
3. Clone/download this repo
4. Run `src/AHK-Tools-Unified.ahk`

## Add to Startup
To run the script automatically on Windows startup:
1. Press Win+R, type `shell:startup`, and press Enter.
2. Copy a shortcut to `src/AHK-Tools-Unified.ahk` into the opened folder.
3. To always run as administrator: Right-click the shortcut, choose Properties → Compatibility, and check 'Run this program as an administrator'.

**Tip:** You can also reload the script as administrator anytime from the tray icon menu (right-click the tray icon → 'Reload as Admin').

## Category Recognition Legend

<span style="color: #FF6B6B">**🔧 System Operations (Win Key)**</span> - System-level commands, some requiring elevated privileges  
<span style="color: #45B7D1">**📝 Text & Search Operations (Alt Key)**</span> - Text processing and search functions

## Main Shortcuts
| Shortcut      | Action                                 |
|--------------|----------------------------------------|
| <span style="color: #FF6B6B">**Win+Del**</span>      | <span style="color: #4ECDC4">Suspend/Resume script</span>                  |
| <span style="color: #FF6B6B">**Win+Enter** 🔐</span>    | <span style="color: #4ECDC4">Open Terminal as Administrator</span>         |
| <span style="color: #FF6B6B">**Win+F1**</span>       | <span style="color: #4ECDC4">Show shortcuts help</span>                    |
| <span style="color: #FF6B6B">**Win+F2**</span>       | <span style="color: #4ECDC4">Toggle Numpad Mode</span>                     |
| <span style="color: #FF6B6B">**Win+F3** 🔐</span>       | <span style="color: #4ECDC4">Wi-Fi reconnect & flush DNS</span>            |
| <span style="color: #FF6B6B">**Win+F4**</span>       | <span style="color: #4ECDC4">Toggle hourly chime</span>                    |
| <span style="color: #FF6B6B">**Win+F12** 🔐</span>      | <span style="color: #4ECDC4">Check Windows File Integrity</span>           |
| <span style="color: #FF6B6B">**Win+C**</span>        | <span style="color: #4ECDC4">Open Calculator</span>                        |
| <span style="color: #FF6B6B">**Win+Q**</span>        | <span style="color: #4ECDC4">Force quit active app</span>                  |
| <span style="color: #FF6B6B">**Win+X**</span>        | <span style="color: #4ECDC4">System Power Options</span>                   |
| <span style="color: #45B7D1">**Alt+A**</span>        | <span style="color: #96CEB4">WolframAlpha Search</span>                    |
| <span style="color: #45B7D1">**Alt+C**</span>        | <span style="color: #96CEB4">Currency Converter (Auto-detects amounts)</span> |
| <span style="color: #45B7D1">**Alt+D**</span>        | <span style="color: #96CEB4">DuckDuckGo Search</span>                      |
| <span style="color: #45B7D1">**Alt+E**</span>        | <span style="color: #96CEB4">Open Selected Text in Editor</span>           |
| <span style="color: #45B7D1">**Alt+G**</span>        | <span style="color: #96CEB4">Search in Game Databases</span>               |
| <span style="color: #45B7D1">**Alt+S**</span>        | <span style="color: #96CEB4">Perplexity Search</span>                      |
| <span style="color: #45B7D1">**Alt+T**</span>        | <span style="color: #96CEB4">Open Selected Text in Notepad</span>          |
| <span style="color: #45B7D1">**Alt+W**</span>        | <span style="color: #96CEB4">Open Selected URL in Browser</span>           |

**🔐 = Requires Administrator Privileges**

## Currency Converter (Alt+C)

The built-in currency converter provides real-time exchange rates with automatic text detection:

### Features:
- **Auto-detection**: Select any text with currency amounts (e.g., "$100", "€50", "₹500") and press Alt+C
- **Symbol recognition**: Supports 50+ currency symbols including $, €, £, ¥, ₹, ₩, ₽, etc.
- **Live rates**: Fetches current exchange rates from exchangerate-api.com (requires Python)
- **190+ currencies**: Supports all major world currencies (USD, EUR, GBP, JPY, etc.)
- **Smart parsing**: Recognizes formats like "$100", "100$", "USD 100", "100 USD"
- **Fallback rates**: Works offline with hardcoded rates for major currency pairs (no Python needed)

### Requirements:
- **Python 3.x** installed and accessible via command line (`python`, `python3`, or `py` commands)
- Internet connection for live exchange rates
- Falls back to offline rates if Python is not available

### Usage:
1. **With selected text**: Select any amount with currency symbol → Press Alt+C → Automatic conversion
2. **Manual entry**: Press Alt+C → Enter amount and select currencies → Real-time conversion
3. **Currency swap**: Use the "Swap" button to quickly reverse the conversion direction

### Supported formats:
- Symbol before: `$100`, `€50`, `£25`, `¥1000`, `₹500`
- Symbol after: `100$`, `50€`, `25£`, `1000¥`, `500₹`  
- With currency codes: `USD 100`, `100 USD`, `EUR 50`, `50 EUR`
- Plain numbers: `100` (defaults to USD)

---
MIT License

