# iOS Build and Distribute Script
# Note: This requires macOS and Xcode
# Usage: .\distribute-ios.ps1 -Version "1.0.1" -Notes "Bug fixes" -Group "ios-testers"

param(
    [string]$Version = "1.0.0",
    [string]$Notes = "New release",
    [string]$Group = "ios-testers"
)

Write-Host "🚀 Starting iOS build and distribution process..." -ForegroundColor Green
Write-Host "⚠️  Note: This requires macOS and Xcode" -ForegroundColor Yellow
Write-Host "Version: $Version" -ForegroundColor Cyan
Write-Host "Notes: $Notes" -ForegroundColor Cyan
Write-Host "Group: $Group" -ForegroundColor Cyan
Write-Host ""

# Step 1: Build IPA
Write-Host "📦 Building iOS release IPA..." -ForegroundColor Yellow
flutter build ipa --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    Write-Host "💡 Make sure you're on macOS with Xcode installed" -ForegroundColor Yellow
    Write-Host "💡 iOS builds cannot be done on Windows - you need macOS" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Build successful!" -ForegroundColor Green
Write-Host ""

# Step 2: Verify IPA exists
$ipaPath = "build/ios/ipa/thort_jivit.ipa"
if (-not (Test-Path $ipaPath)) {
    Write-Host "❌ IPA not found at: $ipaPath" -ForegroundColor Red
    Write-Host "💡 Check the build output for the actual IPA location" -ForegroundColor Yellow
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
    Write-Host "   - Settings → General → VPN & Device Management → Trust" -ForegroundColor White
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
    Write-Host "   4. Verify the IPA path is correct" -ForegroundColor White
    exit 1
}








