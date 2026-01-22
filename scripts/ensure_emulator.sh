#!/bin/bash

# scripts/ensure_emulator.sh
# Detects running Android devices and starts an emulator if none are found.

set -e

echo "🔍 Checking for running Android devices..."

# Get connected devices, filter for android/mobile emulators
# We look for lines containing "•" and "mobile" or "android" but exclude "desktop" and "web"
DEVICES=$(flutter devices | grep "•" | grep -E "mobile|android" | grep -vE "desktop|web|offline" || true)

if [ -n "$DEVICES" ]; then
    echo "✅ Found running Android/mobile device(s):"
    echo "$DEVICES"
    exit 0
fi

echo "⚠️ No running Android devices found. Looking for emulators..."

# Get available emulators
EMULATORS=$(flutter emulators | grep "android" || true)

if [ -z "$EMULATORS" ]; then
    echo "❌ No Android emulators found. Please create one using 'flutter emulators --create'."
    exit 1
fi

# Get the first emulator ID
EMULATOR_ID=$(echo "$EMULATORS" | head -n 1 | awk '{print $1}')

echo "🚀 Launching emulator: $EMULATOR_ID..."
flutter emulators --launch "$EMULATOR_ID"

# Wait for emulator to be ready
echo "⏳ Waiting for emulator to boot..."
MAX_ATTEMPTS=30
ATTEMPT=1

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    # check if "flutter devices" shows it as online and extract the ID
    DEVICE_ID=$(flutter devices | grep "•" | grep -E "mobile|android" | grep -vE "desktop|web|offline" | head -n 1 | awk -F'•' '{print $2}' | xargs || true)
    
    if [ -n "$DEVICE_ID" ]; then
        echo "✅ Emulator is ready with ID: $DEVICE_ID"
        # We can pass the ID back if needed, but for now we just want to ensure it's there
        exit 0
    fi
    echo "   ($ATTEMPT/$MAX_ATTEMPTS) Still waiting..."
    sleep 5
    ATTEMPT=$((ATTEMPT + 1))
done

echo "❌ Timeout waiting for emulator to boot."
exit 1
