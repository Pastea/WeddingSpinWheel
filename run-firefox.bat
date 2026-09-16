@echo off
setlocal enabledelayedexpansion

echo Checking for build folder...
if not exist "%~dp0dist\index.html" (
    echo Build folder (dist/) or index.html missing. Building project...
    call npm run build
)

set "TARGET_FILE=%~dp0dist\index.html"
set "PROFILE_DIR=%~dp0node_modules\.cache\firefox-profile"

if not exist "%PROFILE_DIR%" (
    mkdir "%PROFILE_DIR%"
)

echo Configuring Firefox custom profile with bypassed CORS...
(
    echo user_pref^("security.fileuri.strict_origin_policy", false^)^;
    echo user_pref^("browser.shell.checkDefaultBrowser", false^)^;
    echo user_pref^("browser.startup.homepage_override.mstone", "ignore"^)^;
    echo user_pref^("startup.homepage_welcome_url", ""^)^;
    echo user_pref^("startup.homepage_welcome_url.additional", ""^)^;
) > "%PROFILE_DIR%\prefs.js"

echo Detecting Mozilla Firefox installation...
set "FIREFOX_PATH="

:: Check default 64-bit installation
if exist "%ProgramFiles%\Mozilla Firefox\firefox.exe" (
    set "FIREFOX_PATH=%ProgramFiles%\Mozilla Firefox\firefox.exe"
)

:: Check default 32-bit installation
if not defined FIREFOX_PATH (
    if exist "%ProgramFiles(x86)%\Mozilla Firefox\firefox.exe" (
        set "FIREFOX_PATH=%ProgramFiles(x86)%\Mozilla Firefox\firefox.exe"
    )
)

if not defined FIREFOX_PATH (
    echo [ERROR] Mozilla Firefox could not be found in standard locations.
    echo Please make sure Mozilla Firefox is installed.
    pause
    exit /b 1
)

echo Launching Mozilla Firefox with CORS disabled...
echo Target File: %TARGET_FILE%
echo Profile Directory: %PROFILE_DIR%

start "" "%FIREFOX_PATH%" -profile "%PROFILE_DIR%" "%TARGET_FILE%"
