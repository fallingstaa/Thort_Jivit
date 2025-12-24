#!/bin/bash
# iOS Build and Distribute Script for macOS
# Usage: ./distribute-ios.sh "1.0.1" "Bug fixes" "ios-testers"

VERSION=${1:-"1.0.0"}
NOTES=${2:-"New release"}
GROUP=${3:-"ios-testers"}

echo "🚀 Starting iOS build and distribution process..."
echo "Version: $VERSION"
echo "Notes: $NOTES"
echo "Group: $GROUP"
echo ""

# Step 1: Build IPA
echo "📦 Building iOS release IPA..."
flutter build ipa --release

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "✅ Build successful!"
echo ""

# Step 2: Verify IPA exists
IPA_PATH="build/ios/ipa/thort_jivit.ipa"
if [ ! -f "$IPA_PATH" ]; then
    echo "❌ IPA not found at: $IPA_PATH"
    echo "💡 Checking alternative locations..."
    # Try to find IPA
    IPA_PATH=$(find build/ios -name "*.ipa" | head -1)
    if [ -z "$IPA_PATH" ]; then
        echo "❌ No IPA file found in build directory"
        exit 1
    fi
    echo "✅ Found IPA at: $IPA_PATH"
fi

IPA_SIZE=$(du -h "$IPA_PATH" | cut -f1)
echo "📱 IPA Size: $IPA_SIZE"
echo ""

# Step 3: Distribute
echo "📤 Distributing to Firebase App Distribution..."
APP_ID="1:262571734333:ios:425349e073cfdc84274154"
RELEASE_NOTES="Version $VERSION - $NOTES"

firebase appdistribution:distribute "$IPA_PATH" \
  --app "$APP_ID" \
  --groups "$GROUP" \
  --release-notes "$RELEASE_NOTES"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Distribution successful!"
    echo "📧 iOS testers in group '$GROUP' will receive an email with download link"
    echo ""
    echo "📱 Important for iOS testers:"
    echo "   - They must open the link in Safari (not Chrome)"
    echo "   - For Ad Hoc builds, device UDID must be registered"
    echo "   - They need to trust the developer certificate in Settings"
    echo "   - Settings → General → VPN & Device Management → Trust"
    echo ""
    echo "🔗 View in Firebase Console:"
    echo "   https://console.firebase.google.com/project/thort-jivit/appdistribution"
else
    echo ""
    echo "❌ Distribution failed!"
    exit 1
fi








