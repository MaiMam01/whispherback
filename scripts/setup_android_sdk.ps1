# Lightweight Android SDK setup (no full Android Studio IDE).
# Installs: OpenJDK 17, Android command-line tools, platform-tools, SDK 35, build-tools.
# Disk: ~1.5 GB. Run once, then: .\scripts\build_apk.ps1

$ErrorActionPreference = 'Continue'
$sdkRoot = Join-Path $env:LOCALAPPDATA 'Android\Sdk'
$cmdlineZip = Join-Path $env:TEMP 'commandlinetools-win.zip'
$cmdlineUrl = 'https://dl.google.com/android/repository/commandlinetools-win-13114758_latest.zip'

function Test-Command($name) {
  return $null -ne (Get-Command $name -ErrorAction SilentlyContinue)
}

Write-Host '=== WhisperBack Android SDK setup ===' -ForegroundColor Cyan

# 1. Java (required by sdkmanager)
if (-not (Test-Command java)) {
  Write-Host 'Installing OpenJDK 17 (winget)...' -ForegroundColor Yellow
  winget install -e --id Microsoft.OpenJDK.17 --accept-package-agreements --accept-source-agreements
  $env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path', 'User')
}

if (-not (Test-Command java)) {
  throw 'Java not found after install. Open a NEW PowerShell window and re-run this script.'
}

Write-Host 'Java installed (OpenJDK 17)' -ForegroundColor Green

# 2. SDK directory
New-Item -ItemType Directory -Force -Path $sdkRoot | Out-Null
$cmdlineLatest = Join-Path $sdkRoot 'cmdline-tools\latest'
$sdkmanager = Join-Path $cmdlineLatest 'bin\sdkmanager.bat'

if (-not (Test-Path $sdkmanager)) {
  Write-Host 'Downloading Android command-line tools...' -ForegroundColor Yellow
  Invoke-WebRequest -Uri $cmdlineUrl -OutFile $cmdlineZip -UseBasicParsing
  $extractTemp = Join-Path $env:TEMP 'android-cmdline-extract'
  if (Test-Path $extractTemp) { Remove-Item $extractTemp -Recurse -Force }
  Expand-Archive -Path $cmdlineZip -DestinationPath $extractTemp -Force
  New-Item -ItemType Directory -Force -Path (Join-Path $sdkRoot 'cmdline-tools') | Out-Null
  if (Test-Path $cmdlineLatest) { Remove-Item $cmdlineLatest -Recurse -Force }
  Move-Item (Join-Path $extractTemp 'cmdline-tools') $cmdlineLatest
  Remove-Item $extractTemp -Recurse -Force -ErrorAction SilentlyContinue
  Remove-Item $cmdlineZip -Force -ErrorAction SilentlyContinue
}

Write-Host 'Installing SDK packages (may take several minutes)...' -ForegroundColor Yellow
$packages = @(
  'platform-tools',
  'platforms;android-35',
  'build-tools;35.0.0'
)

foreach ($pkg in $packages) {
  Write-Host "  -> $pkg"
  echo y | & $sdkmanager --sdk_root=$sdkRoot $pkg 2>&1 | Out-Null
}

Write-Host 'Accepting SDK licenses...' -ForegroundColor Yellow
1..20 | ForEach-Object { echo y } | & $sdkmanager --sdk_root=$sdkRoot --licenses 2>&1 | Out-Null

# 3. Flutter config
flutter config --android-sdk $sdkRoot
[Environment]::SetEnvironmentVariable('ANDROID_HOME', $sdkRoot, 'User')
[Environment]::SetEnvironmentVariable('ANDROID_SDK_ROOT', $sdkRoot, 'User')
$env:ANDROID_HOME = $sdkRoot
$env:ANDROID_SDK_ROOT = $sdkRoot

Write-Host ''
Write-Host 'Running flutter doctor (Android section)...' -ForegroundColor Cyan
flutter doctor -v | Select-String -Pattern 'Android|Flutter|\[X\]|\[√\]' -Context 0,1

Write-Host ''
Write-Host 'Setup complete. Build APK with:' -ForegroundColor Green
Write-Host '  .\scripts\build_apk.ps1'
