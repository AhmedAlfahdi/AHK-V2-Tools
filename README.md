# AutoHotkey Project

This is an AutoHotkey v2 project that provides various automation features including keyboard shortcuts, system power options, and more.


**Contributions are welcome! Please feel free to submit a pull request or open an issue.**

## Requirements

- **AutoHotkey v2.0 or later is strictly required**
- This script will not work with AutoHotkey v1.x
- Download v2 from: https://www.autohotkey.com/v2/

## Installation

1. Ensure you have AutoHotkey v2 installed (v1.x will not work)
2. Clone this repository or download zip file
3. Run `src/main.ahk` as Administrator 

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
    - Alt + A: WolframAlpha Search
    - Alt + S: Perplexity Search
    - Alt + D: DuckDuckGo Search
    - Alt + F: Phind AI Search

## Project Structure

- `src/AHK-Tools.ahk`: Main script file
- `src/config.ahk`: Configuration settings
- `src/lib/`: Library files
  - `Txt-Replacment.ahk`: Add your text replacement rules
  - `functions.ahk`: Utility functions

## Usage

Run `src/AHK-Tools.ahk` or precompiled `AHK-Tools.exe` and press `win + F1` to see the help dialog.

## License

MIT License

Copyright (c) 2025

Permission is hereby granted, free of charge, to any person obtaining a copy

