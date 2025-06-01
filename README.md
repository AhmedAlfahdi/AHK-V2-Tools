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

## Main Shortcuts
| Shortcut      | Action                                 |
|--------------|----------------------------------------|
| Win+F1       | Show shortcuts help                    |
| Win+F2       | Toggle Numpad Mode                     |
| Win+F3       | Wi-Fi reconnect & flush DNS            |
| Win+F4       | Toggle hourly chime                    |
| Win+Del      | Suspend/Resume script                  |
| Win+Enter    | Open Terminal as Admin                 |
| Win+C        | Open Calculator                        |
| Win+Q        | Force quit active app                  |
| Win+X        | Power options (Sleep/Shutdown/Logout)  |
| Alt+A        | WolframAlpha search                    |
| Alt+C        | Currency Converter (Auto-detects amounts) |
| Alt+D        | DuckDuckGo search                      |
| Alt+E        | Open selected text in editor           |
| Alt+G        | Game database search                   |
| Alt+S        | Perplexity search                      |
| Alt+T        | Open selected text in Notepad          |
| Alt+W        | Open selected URL in browser           |

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

