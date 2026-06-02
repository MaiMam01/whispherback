# Builds a debug APK for sideloading on Android phones (testing).
# Requires Android SDK — run setup_android_sdk.ps1 first if flutter doctor shows no SDK.
param(
  [ValidateSet('debug', 'release')]
  [string]$Mode = 'debug'
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
$mobile = Join-Path $repoRoot 'mobile'

# JDK required by Android Gradle (winget: Microsoft.OpenJDK.17)
if (-not $env:JAVA_HOME) {
  $jdkCandidates = @(
    'C:\Program Files\Microsoft\jdk-17*',
    'C:\Program Files\Eclipse Adoptium\jdk-17*',
    'C:\Program Files\Java\jdk-17*'
  )
  foreach ($pattern in $jdkCandidates) {
    $found = Get-ChildItem $pattern -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
    if ($found) {
      $env:JAVA_HOME = $found.FullName
      $env:PATH = "$($found.FullName)\bin;$env:PATH"
      break
    }
  }
}
if (-not $env:JAVA_HOME) {
  Write-Error 'JAVA_HOME not set. Install JDK 17: winget install Microsoft.OpenJDK.17'
}

$sdkRoot = $env:ANDROID_HOME
if (-not $sdkRoot) { $sdkRoot = $env:ANDROID_SDK_ROOT }
if (-not $sdkRoot) { $sdkRoot = Join-Path $env:LOCALAPPDATA 'Android\Sdk' }

Push-Location $mobile

Write-Host 'Checking Flutter...' -ForegroundColor Cyan
flutter pub get

$doctor = flutter doctor -v 2>&1 | Out-String
if ($doctor -match 'Android toolchain.*\[X\]') {
  Write-Host ''
  Write-Error @"
Android SDK not found. Install it first (one-time, ~1-2 GB):

  .\scripts\setup_android_sdk.ps1

Or install Android Studio from https://developer.android.com/studio
Then run: flutter doctor --android-licenses
"@
}

Write-Host "Building APK ($Mode)..." -ForegroundColor Cyan
if ($Mode -eq 'debug') {
  flutter build apk --debug --dart-define=FLAVOR=dev
  $apk = Join-Path $mobile 'build\app\outputs\flutter-apk\app-debug.apk'
} else {
  flutter build apk --release --dart-define=FLAVOR=dev
  $apk = Join-Path $mobile 'build\app\outputs\flutter-apk\app-release.apk'
}

Pop-Location

if (-not (Test-Path $apk)) {
  throw "APK not found at $apk"
}

$destDir = Join-Path $repoRoot 'dist'
New-Item -ItemType Directory -Force -Path $destDir | Out-Null
$dest = Join-Path $destDir 'whisperback-test.apk'
Copy-Item $apk $dest -Force

Write-Host ''
Write-Host 'APK ready!' -ForegroundColor Green
Write-Host "  $dest"
Write-Host ''
Write-Host 'Install on your phone:' -ForegroundColor Cyan
Write-Host '  1. Copy whisperback-test.apk to your phone (USB, email, or cloud)'
Write-Host '  2. Enable Install from unknown sources for your file app'
Write-Host '  3. Tap the APK to install'
Write-Host ''
Write-Host 'Or with USB debugging:' -ForegroundColor Cyan
Write-Host "  adb install -r `"$dest`""
