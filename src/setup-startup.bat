@echo off
echo [*] Setting up AHK-Tools to run on startup...
powershell -Command "Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass -File ""%~dp0startup.ps1""' -Verb RunAs -Wait"
if %ERRORLEVEL% EQU 0 (
    echo [OK] Setup completed successfully!
) else (
    echo [FAILED] Setup failed. Please check the error messages above.
)
echo.
echo Press any key to close this window...
pause > nul 