# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Please run this script as Administrator!"
    Write-Host "`nPress any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit
}

# Check if AutoHotkey v2 is installed
$ahkPath = "C:\Program Files\AutoHotkey\v2\AutoHotkey.exe"
if (-not (Test-Path $ahkPath)) {
    Write-Error "AutoHotkey v2 is not installed. Please install it from https://www.autohotkey.com/v2/"
    Write-Host "`nPress any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit
}

# Check if Cursor is installed (required for Alt+E feature)
$cursorPath = "${env:LOCALAPPDATA}\Programs\Cursor\Cursor.exe"
if (-not (Test-Path $cursorPath)) {
    Write-Warning "Cursor is not installed. Alt+E feature will not work. Install from https://www.cursor.com/"
}

# Create a scheduled task to run the AHK script on startup with admin privileges
$taskName = "AHK-Tools"
$taskDescription = "Runs AHK-Tools script on startup with admin privileges"
$scriptPath = Join-Path $PSScriptRoot "AHK-Tools.ahk"
$workingDir = $PSScriptRoot

# Check if the script exists
if (-not (Test-Path $scriptPath)) {
    Write-Error "AHK-Tools.ahk not found in $workingDir"
    Write-Host "`nPress any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit
}

# Create the action to run the script with AutoHotkey
$action = New-ScheduledTaskAction -Execute $ahkPath -Argument "`"$scriptPath`"" -WorkingDirectory $workingDir

# Create the trigger for startup
$trigger = New-ScheduledTaskTrigger -AtStartup

# Set the principal to run with highest privileges for the current user
$principal = New-ScheduledTaskPrincipal -UserId ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name) -LogonType ServiceAccount -RunLevel Highest

# Set the settings to run the task even if the user is not logged on
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable -Hidden -ExecutionTimeLimit 0

# Register the scheduled task
try {
    # Remove existing task if it exists
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
    
    # Register the new task
    Register-ScheduledTask -TaskName $taskName -Description $taskDescription -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force
    Write-Host "`n[✓] AHK-Tools has been successfully set up to run on startup with admin privileges." -ForegroundColor Green
    Write-Host "`n[!] The script will start automatically when you restart your computer." -ForegroundColor Yellow
} catch {
    Write-Error "Failed to create scheduled task: $_"
    Write-Host "`nPress any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit
}

# Create a shortcut in the startup folder for backup
$startupFolder = [System.Environment]::GetFolderPath('Startup')
$shortcutPath = Join-Path $startupFolder "AHK-Tools.lnk"
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = $ahkPath
$Shortcut.Arguments = "`"$scriptPath`""
$Shortcut.WorkingDirectory = $workingDir
$Shortcut.WindowStyle = 7  # Minimized
$Shortcut.Save()

Write-Host "`n[✓] A backup shortcut has been created in your startup folder." -ForegroundColor Green
Write-Host "`n[✓] Setup completed successfully!" -ForegroundColor Green
Write-Host "`nPress any key to close this window..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") 