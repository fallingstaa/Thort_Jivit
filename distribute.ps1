# Build and Distribute Script for Firebase App Distribution
# Usage: .\distribute.ps1 -Version "1.0.1" -Notes "Bug fixes" -Group "testers"

param(
    [string]$Version = "1.0.0",
    [string]$Notes = "New release",
    [string]$Group = "testers"
)

Write-Host "🚀 Starting build and distribution process..." -ForegroundColor Green
Write-Host "Version: $Version" -ForegroundColor Cyan
Write-Host "Notes: $Notes" -ForegroundColor Cyan
Write-Host "Group: $Group" -ForegroundColor Cyan
Write-Host ""

# Step 1: Build APK
Write-Host "📦 Building release APK..." -ForegroundColor Yellow
flutter build apk --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Build successful!" -ForegroundColor Green
Write-Host ""

# Step 2: Verify APK exists
$apkPath = "build\app\outputs\flutter-apk\app-release.apk"
if (-not (Test-Path $apkPath)) {
    Write-Host "❌ APK not found at: $apkPath" -ForegroundColor Red
    exit 1
}

$apkSize = (Get-Item $apkPath).Length / 1MB
Write-Host "📱 APK Size: $([math]::Round($apkSize, 2)) MB" -ForegroundColor Cyan
Write-Host ""

# Step 3: Distribute
Write-Host "📤 Distributing to Firebase App Distribution..." -ForegroundColor Yellow
$appId = "1:262571734333:android:91a037240c1b38c3274154"
$releaseNotes = "Version $Version - $Notes"

firebase appdistribution:distribute $apkPath `
  --app $appId `
  --groups $Group `
  --release-notes $releaseNotes

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Distribution successful!" -ForegroundColor Green
    Write-Host "📧 Testers in group '$Group' will receive an email with download link" -ForegroundColor Cyan
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


