; Configuration variables
global CONFIG := {
    appName: "AHK Tools for power users",
    version: "1.0.1",
    author: "Ahmed N. Alfahdi",
    GitHub: "https://github.com/ahmedalfahdi",
    ; Existing configurations
    tooltipDuration: 3000,    ; Duration in milliseconds for tooltips
    defaultSound: true,       ; Play sound on notifications
    logFilePath: "C:\\Logs\\ahk_tools.log",  ; Path to the log file
    maxRetries: 5,            ; Maximum number of retries for operations

    ; Additional configurations
    debugMode: false,         ; Enable detailed logging for debugging
    autoSaveInterval: 60000,  ; Auto-save interval in milliseconds (e.g., for state or settings)
    runAtStartup: true,       ; Whether the script should launch on system startup
    defaultLanguage: "en",    ; Default language code for messages
    opacity: 230              ; Window opacity (0 = fully transparent, 255 = fully opaque)
}

LoadConfiguration() {
    ; Add any dynamic configuration loading or initialization logic here.
    ; For example, you might override defaults based on external files or user preferences.
    return
} 