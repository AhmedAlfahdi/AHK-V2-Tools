# AutoHotkey Project

AutoHotkey (AHK) is a powerful automation scripting language for Windows that allows you to automate repetitive tasks, create custom keyboard shortcuts, and enhance your workflow productivity. This project leverages AHK v2 to provide a collection of useful hotkeys and automation tools.


## Why This Script?

This AHK-Tools script provides a comprehensive set of productivity enhancements:

1. **Quick Access Tools**
   - Launch calculator, terminal, and system utilities with custom shortcuts
   - Force quit applications and manage system power options easily
   - Toggle useful features like numpad mode and hourly time tracking

2. **Search Enhancement**
   - Quickly search selected text across multiple platforms:
     - AI assistants (Perplexity, Phind)
     - Knowledge bases (WolframAlpha)
     - Search engines (DuckDuckGo)
     - Game databases
     - Torrent search

3. **System Management**
   - Windows file integrity checking
   - Wi-Fi management and DNS flushing
   - Administrative task automation

4. **Text Manipulation**
   - Custom text replacement rules
   - Quick text editing and manipulation
   - Integration with Cursor AI editor

This script is perfect for power users, developers, and anyone looking to streamline their Windows workflow with automated shortcuts and tools.



**Contributions are welcome! Please feel free to submit a pull request or open an issue.**

## Requirements

- **AutoHotkey v2.0 or later is strictly required**
- This script will not work with AutoHotkey v1.x
- You have to install Cursor AI to use the Alt + E shortcut (https://www.cursor.com/)
- Download v2 from: https://www.autohotkey.com/v2/

## Installation

1. Ensure you have AutoHotkey v2 installed (v1.x will not work)
2. Clone this repository or download zip file
3. Run `src/main.ahk` as Administrator 
4. Run `src/setup-startup.bat` as Administrator to setup the script to run on startup

## Features

- Calculator shortcut (Win + C)
- Keyboard shortcuts help (Win + F1)
    - Win + Del: Suspend/Resume Script
    - Win + Enter: Open Terminal as Administrator
    - Win + F1: Keyboard shortcuts help (This help dialog)
    - Win + F2: Toggle Numpad Mode (Row numbers 1-9,0)
    - Win + F3: Wi-Fi Reconnect and Flush DNS
    - Win + F4: Toggle Hourly Chime
    - Win + Q: Force Quit Active Application
    - Win + X: System Power Options (Sleep/Shutdown/Logout)
    - Alt + E: Open selected text in Cursor AI Editor (you have to install Cursor AI) 
    - Alt + A: WolframAlpha Search
    - Alt + S: Perplexity Search
    - Alt + D: DuckDuckGo Search
    - Alt + F: Phind AI Search
    - Alt + G: Search selected text in SteamDB and other game databases

## Project Structure

- `src/AHK-Tools.ahk`: Main script file
- `src/config.ahk`: Configuration settings
- `src/lib/`: Library files
  - `Txt-Replacment.ahk`: Add your text replacement rules
  - `functions.ahk`: Utility functions


## License

MIT License

Copyright (c) 2025

Permission is hereby granted, free of charge, to any person obtaining a copy

