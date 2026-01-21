#!/bin/bash

# setup_android.sh
# Checks for and installs Android development prerequisites.

set -e

echo "🤖 Setting up Android development environment..."

# Check for Homebrew
if ! command -v brew >/dev/null 2>&1; then
    echo "❌ Homebrew not found. Please install Homebrew first: https://brew.sh/"
    exit 1
fi

# 1. Check for Java (JDK 17 recommended for modern Android/Flutter)
echo "☕ Checking Java..."
if ! command -v java >/dev/null 2>&1; then
    echo "   Java not found."
    read -p "   Do you want to install openjdk@17 via brew? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        brew install openjdk@17
        # Symlink for system Java wrappers
        sudo ln -sfn /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-17.jdk
        echo "   ✅ Java installed."
    else
        echo "   ⚠️  Skipping Java installation. You may need to install it manually."
    fi
else
    JAVA_VER=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
    echo "   Found Java version: $JAVA_VER"
    
    # Check if this is Java 1.8
    if [[ "$JAVA_VER" == "1.8."* ]]; then 
         echo "   ⚠️  Java 1.8 detected. Android builds often require Java 11 or 17."
         
         # Check if openjdk@17 is installed via brew
         if brew list openjdk@17 &>/dev/null; then
            JAVA_17_HOME="$(brew --prefix openjdk@17)/libexec/openjdk.jdk/Contents/Home"
            echo "   ✅ openjdk@17 is installed at $JAVA_17_HOME"
            echo "      but it is not currently active."
            echo ""
            echo "   👉 To use it for this session, run:"
            echo "      export JAVA_HOME=\"$JAVA_17_HOME\""
            echo "      export PATH=\"\$JAVA_HOME/bin:\$PATH\""
            echo ""
            read -p "   Do you want to check for SDK assuming you will set this later? (y/N) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
            # Determine if we should set it for the rest of this script execution
            export JAVA_HOME="$JAVA_17_HOME"
            export PATH="$JAVA_HOME/bin:$PATH"
         else
             read -p "   Do you want to install openjdk@17 via brew? (y/N) " -n 1 -r
             echo
             if [[ $REPLY =~ ^[Yy]$ ]]; then
                brew install openjdk@17
                 sudo ln -sfn /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-17.jdk
                echo "   ✅ Java 17 installed."
             fi
         fi
    fi
fi

# 2. Check for Android SDK
echo "📱 Checking Android SDK..."
# Try to find SDK location
SDK_LOC=$(flutter config --machine | grep android-sdk | awk -F': ' '{print $2}' | tr -d '",')

if [ -z "$SDK_LOC" ] || [ ! -d "$SDK_LOC" ]; then
    # Helper to check standard locations
    if [ -d "$HOME/Library/Android/sdk" ]; then
        SDK_LOC="$HOME/Library/Android/sdk"
        echo "   Found SDK at standard location: $SDK_LOC"
        flutter config --android-sdk "$SDK_LOC"
    else 
        echo "   Android SDK not found configured in Flutter."
        read -p "   Do you want to install Android Studio via brew? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            brew install --cask android-studio
            echo "   ✅ Android Studio installed."
            echo "   ⚠️  Please open Android Studio once to complete the SDK installation wizard!"
            echo "   After that, run this script again or run: flutter config --android-sdk \$HOME/Library/Android/sdk"
            exit 0
        else
            echo "   ⚠️  Skipping Android Studio installation."
        fi
    fi
else
    echo "   Flutter is configured to use SDK at: $SDK_LOC"
    
    # Check for cmdline-tools
    if [ ! -d "$SDK_LOC/cmdline-tools" ]; then
        echo "   ❌ 'cmdline-tools' not found in Android SDK."
        echo "   This is required for Flutter to accept licenses."
        echo ""
        echo "   👉 ACTION REQUIRED:"
        echo "   1. Open Android Studio."
        echo "   2. Go to Preferences (or Settings) > Languages & Frameworks > Android SDK > SDK Tools."
        echo "   3. Check 'Android SDK Command-line Tools (latest)'."
        echo "   4. Click Apply/OK to install."
        echo ""
        read -p "   Press Enter once you have installed cmdline-tools..."
    fi
fi

# 3. Flutter Doctor Licenses
echo "📝 Checking Android Licenses..."
echo "   Running 'flutter doctor --android-licenses'. Accept licenses if prompted."
flutter doctor --android-licenses

echo "✅ Android setup check complete."
echo "   Run 'flutter doctor' to verify everything is green."
