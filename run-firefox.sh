#!/bin/bash

# Navigate to script's directory to resolve relative paths correctly
cd "$(dirname "$0")" || exit 1

echo "Checking for build folder..."
if [ ! -f "index.html" ]; then
    echo "index.html missing"
    exit 1
fi

TARGET_FILE="$(pwd)/index.html"
PROFILE_DIR="$(pwd)/.cache/firefox-profile"

mkdir -p "$PROFILE_DIR"

echo "Configuring Firefox custom profile with bypassed CORS..."
cat > "$PROFILE_DIR/prefs.js" << EOF
user_pref("security.fileuri.strict_origin_policy", false);
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("browser.startup.homepage_override.mstone", "ignore");
user_pref("startup.homepage_welcome_url", "");
user_pref("startup.homepage_welcome_url.additional", "");
EOF

OS="$(uname -s)"
echo "Target File: $TARGET_FILE"
echo "Profile Directory: $PROFILE_DIR"

if [ "$OS" = "Darwin" ]; then
    echo "Launching Mozilla Firefox with CORS disabled on macOS..."
    open -na "Firefox" --args -profile "$PROFILE_DIR" "$TARGET_FILE"
elif [ "$OS" = "Linux" ]; then
    echo "Detecting Mozilla Firefox installation..."
    if command -v firefox >/dev/null 2>&1; then
        echo "Launching firefox with CORS disabled on Linux..."
        firefox -profile "$PROFILE_DIR" "$TARGET_FILE" &
    else
        echo "[ERROR] Mozilla Firefox could not be found on your system."
        echo "Please install firefox."
        exit 1
    fi
else
    echo "[ERROR] Unsupported Operating System: $OS"
    exit 1
fi
