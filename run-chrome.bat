@echo off
setlocal enabledelayedexpansion

echo Checking for build folder...
if not exist "%~dp0dist\index.html" (
    echo Build folder (dist/) or index.html missing. Building project...
    call npm run build
)

set "TARGET_FILE=%~dp0dist\index.html"
set "PROFILE_DIR=%~dp0node_modules\.cache\chrome-profile"

if not exist "%PROFILE_DIR%" (
    mkdir "%PROFILE_DIR%"
)

echo Detecting Google Chrome installation...
set "CHROME_PATH="

:: Check default 64-bit installation
if exist "%ProgramFiles%\Google\Chrome\Application\chrome.exe" (
    set "CHROME_PATH=%ProgramFiles%\Google\Chrome\Application\chrome.exe"
)

:: Check default 32-bit installation
if not defined CHROME_PATH (
    if exist "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe" (
        set "CHROME_PATH=%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
    )
)

:: Check local app data installation (user-only install)
if not defined CHROME_PATH (
    if exist "%LocalAppData%\Google\Chrome\Application\chrome.exe" (
        set "CHROME_PATH=%LocalAppData%\Google\Chrome\Application\chrome.exe"
    )
)

if not defined CHROME_PATH (
    echo [ERROR] Google Chrome could not be found in standard locations.
    echo Please make sure Google Chrome is installed.
    pause
    exit /b 1
)

echo Launching Google Chrome with CORS disabled...
echo Target File: %TARGET_FILE%
echo Profile Directory: %PROFILE_DIR%

start "" "%CHROME_PATH%" --disable-web-security --allow-file-access-from-files --no-first-run --no-default-browser-check --user-data-dir="%PROFILE_DIR%" "%TARGET_FILE%"
