# AHK-Tools (AutoHotkey v2)

A productivity script for Windows power users, providing custom hotkeys for quick access, automation, and workflow enhancements.

## Features
- Calculator, terminal, and system utilities shortcuts
- Force quit apps, system power options, Wi-Fi/DNS tools
- Numpad mode toggle (Win+F2)
- Quick search: DuckDuckGo, Perplexity, WolframAlpha, game DBs
- Open selected text in Notepad or editor
- File integrity check, hourly chime, and more

## Requirements
- **AutoHotkey v2.0+** (https://www.autohotkey.com/v2/)

## Installation
1. Install AutoHotkey v2
2. Clone/download this repo
3. Run `src/AHK-Tools-Unified.ahk`

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
| Alt+E        | Open selected text in editor           |
| Alt+A        | WolframAlpha search                    |
| Alt+S        | Perplexity search                      |
| Alt+D        | DuckDuckGo search                      |
| Alt+G        | Game database search                   |
| Alt+T        | Open selected text in Notepad          |
| Alt+W        | Open selected URL in browser           |

---
MIT License

