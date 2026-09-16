#!/bin/bash

# Navigate to script's directory to resolve relative paths correctly
cd "$(dirname "$0")" || exit 1

echo "Checking for build folder..."
if [ ! -f "index.html" ]; then
    echo "index.html missing"
    exit 1
fi

TARGET_FILE="$(pwd)/index.html"
PROFILE_DIR="$(pwd)/.cache/chrome-profile"

mkdir -p "$PROFILE_DIR"

OS="$(uname -s)"
echo "Target File: $TARGET_FILE"
echo "Profile Directory: $PROFILE_DIR"

if [ "$OS" = "Darwin" ]; then
    echo "Launching Google Chrome with CORS disabled on macOS..."
    open -na "Google Chrome" --args --disable-web-security --allow-file-access-from-files --no-first-run --no-default-browser-check --user-data-dir="$PROFILE_DIR" "$TARGET_FILE"
elif [ "$OS" = "Linux" ]; then
    echo "Detecting Google Chrome installation..."
    if command -v google-chrome >/dev/null 2>&1; then
        CHROME_CMD="google-chrome"
    elif command -v google-chrome-stable >/dev/null 2>&1; then
        CHROME_CMD="google-chrome-stable"
    elif command -v chromium >/dev/null 2>&1; then
        CHROME_CMD="chromium"
    elif command -v chromium-browser >/dev/null 2>&1; then
        CHROME_CMD="chromium-browser"
    else
        echo "[ERROR] Google Chrome or Chromium could not be found on your system."
        echo "Please install google-chrome or chromium."
        exit 1
    fi
    echo "Launching $CHROME_CMD with CORS disabled on Linux..."
    "$CHROME_CMD" --disable-web-security --allow-file-access-from-files --no-first-run --no-default-browser-check --user-data-dir="$PROFILE_DIR" "$TARGET_FILE" &
else
    echo "[ERROR] Unsupported Operating System: $OS"
    exit 1
fi
