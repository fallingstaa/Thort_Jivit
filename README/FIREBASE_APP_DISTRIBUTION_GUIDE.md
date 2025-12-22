# Firebase App Distribution - Step-by-Step Guide

This guide will walk you through setting up Firebase App Distribution to distribute your Flutter app for testing.

## Prerequisites

- ✅ Firebase project already set up (`thort-jivit`)
- ✅ Flutter app configured with Firebase
- ✅ Android app configured (applicationId: `com.example.life_record`)
- ✅ iOS app configured (Bundle ID: `com.example.thortJivit`)

---

# Android Distribution Guide

## Android Prerequisites

- ✅ Android app configured (applicationId: `com.example.life_record`)

## Step 1: Enable Firebase App Distribution in Firebase Console

1. **Go to Firebase Console**
   - Visit: https://console.firebase.google.com/
   - Select your project: **thort-jivit**

2. **Enable App Distribution**
   - In the left sidebar, click on **"App Distribution"** (under "Release & Monitor")
   - If you see "Get started", click it to enable the service
   - This is a one-time setup

3. **Verify App Registration**
   - Your Android app should already be registered: `1:262571734333:android:91a037240c1b38c3274154`
   - If not visible, it will be automatically registered when you upload your first build

## Step 2: Install Firebase CLI (if not already installed)

### For Windows (PowerShell):

```powershell
# Check if Node.js is installed
node --version

# If Node.js is not installed, download from: https://nodejs.org/

# Install Firebase CLI globally
npm install -g firebase-tools

# Login to Firebase
firebase login

# Verify installation
firebase --version
```

### Alternative: Using Chocolatey (Windows)

```powershell
choco install firebase-cli
firebase login
```

## Step 3: Install Firebase App Distribution CLI Plugin

```powershell
firebase install-tools
```

Or install the plugin directly:

```powershell
npm install -g firebase-tools
firebase login:ci  # For CI/CD (optional)
```

## Step 4: Build Your Flutter App (Release APK)

### Option A: Build APK (Recommended for Testing)

```powershell
# Navigate to your project root
cd D:\life_record

# Build release APK
flutter build apk --release

# The APK will be at: build\app\outputs\flutter-apk\app-release.apk
```

### Option B: Build App Bundle (AAB) - For Play Store

```powershell
# Build app bundle
flutter build appbundle --release

# The AAB will be at: build\app\outputs\bundle\release\app-release.aab
```

**Note:** For App Distribution, APK is recommended as it's easier to install directly.

## Step 5: Distribute Your App Using Firebase CLI

### Basic Distribution Command

```powershell
# Navigate to project root
cd D:\life_record

# Distribute APK to testers
firebase appdistribution:distribute build\app\outputs\flutter-apk\app-release.apk `
  --app 1:262571734333:android:91a037240c1b38c3274154 `
  --groups "testers" `
  --release-notes "Version 1.0.0 - Initial release for testing"
```

### Parameters Explained:
- `--app`: Your Android app ID (from firebase_options.dart)
- `--groups`: Tester group name (create groups in Firebase Console)
- `--release-notes`: Notes about this release

## Step 6: Set Up Tester Groups in Firebase Console

1. **Go to App Distribution in Firebase Console**
   - Navigate to: https://console.firebase.google.com/project/thort-jivit/appdistribution

2. **Create Tester Groups**
   - Click on **"Testers & Groups"** tab
   - Click **"Create group"**
   - Name: `testers` (or any name you prefer)
   - Add tester emails:
     - Enter email addresses of your testers
     - Click **"Add testers"**
   - Click **"Create"**

3. **Individual Testers (Alternative)**
   - You can also add individual testers without groups
   - Use `--testers "email1@example.com,email2@example.com"` instead of `--groups`

## Step 7: Complete Distribution Command Examples

### Distribute to a Group

```powershell
firebase appdistribution:distribute build\app\outputs\flutter-apk\app-release.apk `
  --app 1:262571734333:android:91a037240c1b38c3274154 `
  --groups "testers" `
  --release-notes "Version 1.0.0 - Initial testing release"
```

### Distribute to Individual Testers

```powershell
firebase appdistribution:distribute build\app\outputs\flutter-apk\app-release.apk `
  --app 1:262571734333:android:91a037240c1b38c3274154 `
  --testers "tester1@example.com,tester2@example.com" `
  --release-notes "Version 1.0.0 - Initial testing release"
```

### Distribute with Custom Release Notes File

```powershell
# Create release-notes.txt file
echo "Version 1.0.0`n`n- Initial release`n- Fixed login issues`n- Added new features" > release-notes.txt

# Distribute with file
firebase appdistribution:distribute build\app\outputs\flutter-apk\app-release.apk `
  --app 1:262571734333:android:91a037240c1b38c3274154 `
  --groups "testers" `
  --release-notes-file release-notes.txt
```

## Step 8: Testers Receive the App

1. **Testers get an email** with a download link
2. **They click the link** and are redirected to Firebase App Distribution
3. **They download the app** directly to their Android device
4. **First-time testers** need to:
   - Sign in with their Google account (the email you added)
   - Accept the invitation
   - Download the Firebase App Tester app (optional, for easier management)
   - Or download the APK directly

## Step 9: Create Automation Script (Optional but Recommended)

Create a PowerShell script to automate the build and distribution process.

### Create `distribute.ps1`:

```powershell
# Build and Distribute Script
# Usage: .\distribute.ps1 -Version "1.0.1" -Notes "Bug fixes"

param(
    [string]$Version = "1.0.0",
    [string]$Notes = "New release",
    [string]$Group = "testers"
)

Write-Host "🚀 Starting build and distribution process..." -ForegroundColor Green

# Step 1: Build APK
Write-Host "📦 Building release APK..." -ForegroundColor Yellow
flutter build apk --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    exit 1
}

# Step 2: Distribute
Write-Host "📤 Distributing to Firebase App Distribution..." -ForegroundColor Yellow
$apkPath = "build\app\outputs\flutter-apk\app-release.apk"
$appId = "1:262571734333:android:91a037240c1b38c3274154"
$releaseNotes = "Version $Version - $Notes"

firebase appdistribution:distribute $apkPath `
  --app $appId `
  --groups $Group `
  --release-notes $releaseNotes

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Distribution successful!" -ForegroundColor Green
    Write-Host "📧 Testers will receive an email with download link" -ForegroundColor Cyan
} else {
    Write-Host "❌ Distribution failed!" -ForegroundColor Red
    exit 1
}
```

### Usage:

```powershell
# Basic usage
.\distribute.ps1

# With version and notes
.\distribute.ps1 -Version "1.0.1" -Notes "Fixed login bug"

# With custom group
.\distribute.ps1 -Version "1.0.2" -Notes "New features" -Group "beta-testers"
```

## Step 10: View Distribution History

1. **Go to Firebase Console**
   - Navigate to: https://console.firebase.google.com/project/thort-jivit/appdistribution
2. **View Releases**
   - See all distributed versions
   - View tester feedback
   - Check crash reports (if enabled)

## Troubleshooting

### Issue: "App not found" error

**Solution:**
- Verify your app ID: `1:262571734333:android:91a037240c1b38c3274154`
- Make sure App Distribution is enabled in Firebase Console
- Check that you're logged in: `firebase login`

### Issue: "Group not found" error

**Solution:**
- Create the group in Firebase Console first
- Use exact group name (case-sensitive)
- Or use individual testers with `--testers` flag

### Issue: Build fails

**Solution:**
```powershell
# Clean and rebuild
flutter clean
flutter pub get
flutter build apk --release
```

### Issue: Firebase CLI not found

**Solution:**
```powershell
# Reinstall Firebase CLI
npm install -g firebase-tools
# Or add to PATH if installed via other method
```

### Issue: Permission denied

**Solution:**
- Make sure you're logged in: `firebase login`
- Verify you have access to the Firebase project
- Check your Firebase project permissions in console

## Quick Reference Commands

```powershell
# Login to Firebase
firebase login

# Check current project
firebase projects:list

# Set default project (if needed)
firebase use thort-jivit

# Build APK
flutter build apk --release

# Distribute (basic)
firebase appdistribution:distribute build\app\outputs\flutter-apk\app-release.apk `
  --app 1:262571734333:android:91a037240c1b38c3274154 `
  --groups "testers" `
  --release-notes "Your release notes here"
```

## Next Steps

1. ✅ **Set up tester groups** in Firebase Console
2. ✅ **Build your first release APK**
3. ✅ **Distribute to testers**
4. ✅ **Collect feedback** from testers
5. ✅ **Iterate and improve** based on feedback

## Additional Resources

- [Firebase App Distribution Documentation](https://firebase.google.com/docs/app-distribution)
- [Firebase CLI Reference](https://firebase.google.com/docs/cli)
- [Flutter Build Documentation](https://docs.flutter.dev/deployment/android)

---

**Your Android App Details:**
- **Project ID:** `thort-jivit`
- **Android App ID:** `1:262571734333:android:91a037240c1b38c3274154`
- **Package Name:** `com.example.life_record`
- **Current Version:** `1.0.0+1`

---

# iOS Distribution Guide

## iOS Prerequisites

- ✅ **macOS** (required for building iOS apps)
- ✅ **Xcode** installed (latest version recommended)
- ✅ **Apple Developer Account** (free account works for testing)
- ✅ **Code Signing Certificate** and **Provisioning Profile**
- ✅ iOS app configured (Bundle ID: `com.example.thortJivit`)

## iOS Step 1: Set Up Apple Developer Account

1. **Create/Login to Apple Developer Account**
   - Visit: https://developer.apple.com/
   - Sign in with your Apple ID (free account works for testing)
   - Accept the Apple Developer Agreement

2. **Register Your App Bundle ID**
   - Go to: https://developer.apple.com/account/resources/identifiers/list
   - Click **"+"** to create a new App ID
   - Select **"App IDs"** → **"App"**
   - Description: `Thort Jivit`
   - Bundle ID: `com.example.thortJivit` (must match your app)
   - Enable capabilities you need (Push Notifications, etc.)
   - Click **"Continue"** → **"Register"**

## iOS Step 2: Create Provisioning Profile

### Option A: Automatic Signing (Recommended for Testing)

1. **Open Xcode**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Configure Signing**
   - Select **Runner** project in left sidebar
   - Select **Runner** target
   - Go to **"Signing & Capabilities"** tab
   - Check **"Automatically manage signing"**
   - Select your **Team** (your Apple Developer account)
   - Xcode will automatically create provisioning profile

### Option B: Manual Provisioning Profile

1. **Create Provisioning Profile**
   - Go to: https://developer.apple.com/account/resources/profiles/list
   - Click **"+"** to create new profile
   - Select **"App Store"** or **"Ad Hoc"** (for testing)
   - Select your App ID: `com.example.thortJivit`
   - Select your certificate
   - Select devices (for Ad Hoc) or leave empty (for App Store)
   - Name: `Thort Jivit Distribution`
   - Click **"Generate"** and download

2. **Install Provisioning Profile**
   - Double-click the downloaded `.mobileprovision` file
   - Or drag it into Xcode

## iOS Step 3: Configure Code Signing in Xcode

1. **Open Project in Xcode**
   ```bash
   cd D:\life_record
   open ios/Runner.xcworkspace
   ```

2. **Set Up Signing**
   - Select **Runner** project
   - Select **Runner** target
   - Go to **"Signing & Capabilities"**
   - **Team:** Select your Apple Developer team
   - **Bundle Identifier:** `com.example.thortJivit`
   - **Provisioning Profile:** Automatic (or select manual profile)

3. **Set Build Configuration**
   - Select **"Any iOS Device"** or your connected device
   - Product → Scheme → **"Runner"**
   - Product → Destination → **"Any iOS Device"**

## iOS Step 4: Build iOS App (IPA)

### Option A: Build Using Flutter (Recommended)

```bash
# Navigate to project root
cd D:\life_record

# Build iOS release (creates IPA)
flutter build ipa --release

# The IPA will be at: build/ios/ipa/thort_jivit.ipa
```

### Option B: Build Using Xcode

1. **Open Xcode**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Archive the App**
   - Select **"Any iOS Device"** as destination
   - Product → **"Archive"**
   - Wait for archive to complete

3. **Export IPA**
   - In Organizer window, select your archive
   - Click **"Distribute App"**
   - Select **"Ad Hoc"** (for testing) or **"App Store Connect"**
   - Follow the wizard to export IPA
   - Save the IPA file

### Option C: Build Using Command Line (macOS only)

```bash
# Navigate to iOS directory
cd ios

# Build archive
xcodebuild -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath build/Runner.xcarchive \
  archive

# Export IPA
xcodebuild -exportArchive \
  -archivePath build/Runner.xcarchive \
  -exportPath build \
  -exportOptionsPlist ExportOptions.plist
```

## iOS Step 5: Distribute iOS App Using Firebase CLI

### Basic Distribution Command

```bash
# Navigate to project root
cd D:\life_record

# Distribute IPA to testers
firebase appdistribution:distribute build/ios/ipa/thort_jivit.ipa \
  --app 1:262571734333:ios:425349e073cfdc84274154 \
  --groups "ios-testers" \
  --release-notes "Version 1.0.0 - Initial iOS release for testing"
```

### Parameters Explained:
- `--app`: Your iOS app ID (from firebase_options.dart)
- `--groups`: Tester group name (create groups in Firebase Console)
- `--release-notes`: Notes about this release

## iOS Step 6: Set Up iOS Tester Groups

1. **Go to App Distribution in Firebase Console**
   - Navigate to: https://console.firebase.google.com/project/thort-jivit/appdistribution

2. **Create iOS Tester Groups**
   - Click on **"Testers & Groups"** tab
   - Click **"Create group"**
   - Name: `ios-testers` (or any name you prefer)
   - Add tester emails:
     - Enter email addresses of your iOS testers
     - Click **"Add testers"**
   - Click **"Create"**

3. **Important for iOS Testers:**
   - Testers must have their device UDID registered (for Ad Hoc builds)
   - Or use App Store distribution (no UDID needed, but requires App Store Connect)

## iOS Step 7: Register Test Devices (For Ad Hoc Distribution)

### Get Device UDID

**On iPhone/iPad:**
1. Connect device to Mac
2. Open **Finder** (or iTunes on older macOS)
3. Select device
4. Click on device name/identifier to reveal UDID
5. Copy the UDID

**Alternative Method:**
- Settings → General → About → Copy Identifier (UDID)

### Register Device in Apple Developer Portal

1. **Go to Devices**
   - Visit: https://developer.apple.com/account/resources/devices/list
   - Click **"+"** to add device
   - Name: `Tester iPhone` (or any name)
   - UDID: Paste the device UDID
   - Click **"Continue"** → **"Register"**

2. **Update Provisioning Profile**
   - Go to: https://developer.apple.com/account/resources/profiles/list
   - Edit your Ad Hoc provisioning profile
   - Add the new device
   - Download and install updated profile

## iOS Step 8: Testers Receive and Install iOS App

### For Ad Hoc Distribution:

1. **Testers get an email** with download link
2. **They click the link** on their iOS device
3. **Download the app** via Safari (not Chrome)
4. **Install the app:**
   - Go to Settings → General → VPN & Device Management
   - Trust the developer certificate
   - Open the app

### For App Store Distribution:

1. **Testers get an email** with TestFlight link
2. **They install TestFlight** from App Store (if not already installed)
3. **Accept the invitation** in TestFlight
4. **Install the app** from TestFlight

## iOS Step 9: Create iOS Distribution Script

Create a script to automate iOS build and distribution.

### Create `distribute-ios.ps1` (for Windows with macOS access):

```powershell
# iOS Build and Distribute Script
# Note: This requires macOS and Xcode
# Usage: .\distribute-ios.ps1 -Version "1.0.1" -Notes "Bug fixes"

param(
    [string]$Version = "1.0.0",
    [string]$Notes = "New release",
    [string]$Group = "ios-testers"
)

Write-Host "🚀 Starting iOS build and distribution process..." -ForegroundColor Green
Write-Host "⚠️  Note: This requires macOS and Xcode" -ForegroundColor Yellow
Write-Host ""

# Step 1: Build IPA
Write-Host "📦 Building iOS release IPA..." -ForegroundColor Yellow
flutter build ipa --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    Write-Host "💡 Make sure you're on macOS with Xcode installed" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Build successful!" -ForegroundColor Green
Write-Host ""

# Step 2: Verify IPA exists
$ipaPath = "build/ios/ipa/thort_jivit.ipa"
if (-not (Test-Path $ipaPath)) {
    Write-Host "❌ IPA not found at: $ipaPath" -ForegroundColor Red
    exit 1
}

$ipaSize = (Get-Item $ipaPath).Length / 1MB
Write-Host "📱 IPA Size: $([math]::Round($ipaSize, 2)) MB" -ForegroundColor Cyan
Write-Host ""

# Step 3: Distribute
Write-Host "📤 Distributing to Firebase App Distribution..." -ForegroundColor Yellow
$appId = "1:262571734333:ios:425349e073cfdc84274154"
$releaseNotes = "Version $Version - $Notes"

firebase appdistribution:distribute $ipaPath `
  --app $appId `
  --groups $Group `
  --release-notes $releaseNotes

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Distribution successful!" -ForegroundColor Green
    Write-Host "📧 iOS testers in group '$Group' will receive an email with download link" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📱 Important for iOS testers:" -ForegroundColor Yellow
    Write-Host "   - They must open the link in Safari (not Chrome)" -ForegroundColor White
    Write-Host "   - For Ad Hoc builds, device UDID must be registered" -ForegroundColor White
    Write-Host "   - They need to trust the developer certificate in Settings" -ForegroundColor White
    Write-Host ""
    Write-Host "🔗 View in Firebase Console:" -ForegroundColor Yellow
    Write-Host "   https://console.firebase.google.com/project/thort-jivit/appdistribution" -ForegroundColor Blue
} else {
    Write-Host ""
    Write-Host "❌ Distribution failed!" -ForegroundColor Red
    Write-Host "💡 Troubleshooting:" -ForegroundColor Yellow
    Write-Host "   1. Make sure you're logged in: firebase login" -ForegroundColor White
    Write-Host "   2. Verify the group '$Group' exists in Firebase Console" -ForegroundColor White
    Write-Host "   3. Check that App Distribution is enabled" -ForegroundColor White
    exit 1
}
```

### Create `distribute-ios.sh` (for macOS):

```bash
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
    exit 1
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
else
    echo ""
    echo "❌ Distribution failed!"
    exit 1
fi
```

## iOS Troubleshooting

### Issue: "Code signing failed" error

**Solution:**
- Make sure you have a valid Apple Developer account
- Check that your provisioning profile is valid
- Verify code signing settings in Xcode
- Ensure your certificate hasn't expired

### Issue: "Device not registered" error

**Solution:**
- Register the device UDID in Apple Developer Portal
- Update your provisioning profile to include the device
- Rebuild and redistribute the IPA

### Issue: "IPA not found" error

**Solution:**
```bash
# Check if IPA was created
ls -la build/ios/ipa/

# Rebuild if needed
flutter clean
flutter build ipa --release
```

### Issue: Build fails on Windows

**Solution:**
- iOS builds **require macOS and Xcode**
- You cannot build iOS apps on Windows
- Options:
  1. Use a Mac or macOS virtual machine
  2. Use a CI/CD service (GitHub Actions, Codemagic, etc.)
  3. Build on a remote Mac server

### Issue: Testers can't install the app

**Solution:**
- For Ad Hoc: Device UDID must be registered
- Testers must open download link in **Safari** (not Chrome)
- Testers need to trust the developer certificate:
  - Settings → General → VPN & Device Management
  - Tap on the developer certificate
  - Tap "Trust"

### Issue: "Provisioning profile expired"

**Solution:**
- Go to Apple Developer Portal
- Create a new provisioning profile
- Download and install it
- Rebuild the app

## iOS Quick Reference Commands

```bash
# Build iOS IPA
flutter build ipa --release

# Distribute iOS (basic)
firebase appdistribution:distribute build/ios/ipa/thort_jivit.ipa \
  --app 1:262571734333:ios:425349e073cfdc84274154 \
  --groups "ios-testers" \
  --release-notes "Version 1.0.0 - Initial iOS release"

# Open Xcode project
open ios/Runner.xcworkspace

# List connected iOS devices
flutter devices

# Build for specific device
flutter build ios --release --device-id <device-id>
```

## iOS vs Android Distribution Comparison

| Feature | Android | iOS |
|---------|---------|-----|
| **Build File** | APK | IPA |
| **Build Command** | `flutter build apk` | `flutter build ipa` |
| **Platform Required** | Windows/Mac/Linux | macOS only |
| **Code Signing** | Optional (for release) | Required |
| **Device Registration** | Not needed | Required (Ad Hoc) |
| **Installation** | Direct APK install | Safari download + trust certificate |
| **App ID** | `1:262571734333:android:91a037240c1b38c3274154` | `1:262571734333:ios:425349e073cfdc84274154` |

## Combined Distribution Script

If you want to distribute both Android and iOS in one go:

```powershell
# distribute-both.ps1
param(
    [string]$Version = "1.0.0",
    [string]$Notes = "New release"
)

Write-Host "🚀 Distributing to both Android and iOS..." -ForegroundColor Green

# Android
Write-Host "`n📱 Building Android..." -ForegroundColor Cyan
.\distribute.ps1 -Version $Version -Notes $Notes

# iOS (requires macOS)
Write-Host "`n🍎 Building iOS..." -ForegroundColor Cyan
Write-Host "⚠️  Note: iOS build requires macOS" -ForegroundColor Yellow
# Uncomment if on macOS:
# .\distribute-ios.ps1 -Version $Version -Notes $Notes
```

---

**Your iOS App Details:**
- **Project ID:** `thort-jivit`
- **iOS App ID:** `1:262571734333:ios:425349e073cfdc84274154`
- **Bundle ID:** `com.example.thortJivit`
- **Current Version:** `1.0.0+1`

---

**Complete App Details:**
- **Project ID:** `thort-jivit`
- **Android App ID:** `1:262571734333:android:91a037240c1b38c3274154`
- **iOS App ID:** `1:262571734333:ios:425349e073cfdc84274154`
- **Android Package:** `com.example.life_record`
- **iOS Bundle ID:** `com.example.thortJivit`
- **Current Version:** `1.0.0+1`

Happy Testing! 🚀

