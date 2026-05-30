# Initializes Flutter platform folders and fetches dependencies.
param(
  [string]$FlutterPath = "$env:LOCALAPPDATA\flutter-sdk\bin\flutter.bat"
)

$ErrorActionPreference = "Stop"
$mobile = Join-Path $PSScriptRoot ".." "mobile" | Resolve-Path

if (-not (Test-Path $FlutterPath)) {
  Write-Host "Flutter not found at $FlutterPath"
  Write-Host "Install from https://docs.flutter.dev/get-started/install or run:"
  Write-Host "  git clone -b stable --depth 1 https://github.com/flutter/flutter.git `$env:LOCALAPPDATA\flutter-sdk"
  exit 1
}

Push-Location $mobile
if (-not (Test-Path "android")) {
  & $FlutterPath create . --project-name whisperback --org com.whisperback
}
& $FlutterPath pub get
& $FlutterPath analyze
& $FlutterPath test
Pop-Location

Write-Host "Mobile setup complete."
