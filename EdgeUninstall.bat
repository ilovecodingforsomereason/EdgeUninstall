@echo off
:: 1. Self-Elevation Logic (VBScript Method)
set "Params=%*"
cd /d "%~dp0"
fsutil dirty query %SystemDrive% >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting Administrator privileges...
    echo set UAC = CreateObject^("Shell.Application"^) > "%Temp%\getadmin.vbs"
    echo UAC.ShellExecute "cmd.exe", "/c cd /d ""%~dp0"" && ""%~f0"" %Params%", "", "runas", 1 >> "%Temp%\getadmin.vbs"
    "%Temp%\getadmin.vbs"
    del "%Temp%\getadmin.vbs"
    exit /b
)

:: 2. Debug Mode Flag Evaluator
set "DEBUG_MODE=0"
if "%1"=="--debug" set "DEBUG_MODE=1"
if "%1"=="-d" set "DEBUG_MODE=1"

:: 3. Clear Screen and Show Only the Requested Message
cls
echo Deleting Edge...

:: 4. Define Target Installation Directories
set "EdgeDir1=%ProgramFiles(x86)%\Microsoft\Edge"
set "EdgeDir2=%ProgramFiles(x86)%\Microsoft\EdgeUpdate"
set "EdgeDir3=%ProgramFiles(x86)%\Microsoft\EdgeCore"

:: 5. Kill Active Microsoft Edge Processes
if "%DEBUG_MODE%"=="1" echo [DEBUG] Force killing active Microsoft Edge processes...
taskkill /F /IM msedge.exe /T >nul 2>&1
taskkill /F /IM MicrosoftEdgeUpdate.exe /T >nul 2>&1

:: 6. Wipe Binary Folders (Overriding TrustedInstaller Permissions)
for %%D in ("%EdgeDir1%" "%EdgeDir2%" "%EdgeDir3%") do (
    if exist "%%~D" (
        if "%DEBUG_MODE%"=="1" echo [DEBUG] Taking folder ownership of "%%~D"...
        takeown /F "%%~D" /R /A /D Y >nul 2>&1
        
        if "%DEBUG_MODE%"=="1" echo [DEBUG] Overwriting access control lists for Administrators...
        icacls "%%~D" /grant Administrators:F /T /C /Q >nul 2>&1
        
        if "%DEBUG_MODE%"=="1" echo [DEBUG] Recursively shredding directory...
        rmdir /S /Q "%%~D" >nul 2>&1
    ) else (
        if "%DEBUG_MODE%"=="1" echo [DEBUG] Path not found, skipping: %%~D
    )
)

:: 7. Purge Edge Background Scheduled Tasks
if "%DEBUG_MODE%"=="1" echo [DEBUG] Deleting Edge update scheduler tasks...
schtasks /delete /tn "MicrosoftEdgeUpdateTaskMachineCore" /f >nul 2>&1
schtasks /delete /tn "MicrosoftEdgeUpdateTaskMachineUA" /f >nul 2>&1
schtasks /delete /tn "MicrosoftEdgeUpdateBrowserReplacementService" /f >nul 2>&1

:: 8. Disable and Nuke System Services
if "%DEBUG_MODE%"=="1" echo [DEBUG] Disabling Edge services...
sc config edgeupdate start= disabled >nul 2>&1
sc config edgeupdatem start= disabled >nul 2>&1
sc config MicrosoftEdgeElevationService start= disabled >nul 2>&1

sc delete edgeupdate >nul 2>&1
sc delete edgeupdatem >nul 2>&1
sc delete MicrosoftEdgeElevationService >nul 2>&1

:: 9. Wipe Residual Pinned Shortcuts and Files
if "%DEBUG_MODE%"=="1" echo [DEBUG] Purging shortcut icons...
del /F /Q "%PUBLIC%\Desktop\Microsoft Edge.lnk" >nul 2>&1
del /F /Q "%USERPROFILE%\Desktop\Microsoft Edge.lnk" >nul 2>&1
del /F /Q "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk" >nul 2>&1
del /F /Q "%APPDATA%\Microsoft\Windows\Start Menu\Programs\System Tools\Microsoft Edge.lnk" >nul 2>&1
del /F /Q "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk" >nul 2>&1
del /F /Q "%APPDATA%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Microsoft Edge.lnk" >nul 2>&1

:: 10. Force Block Future Windows Update Injections
if "%DEBUG_MODE%"=="1" echo [DEBUG] Setting HKLM EdgeUpdate block in Registry...
reg add "HKLM\SOFTWARE\Microsoft\EdgeUpdate" /v "DoNotUpdateToEdgeWithChromium" /t REG_DWORD /d 1 /f >nul 2>&1

if "%DEBUG_MODE%"=="1" echo [DEBUG] Operation complete.
