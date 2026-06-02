# One-time install of Android NDK required by Flutter 3.38+ (~714 MB download).
# Run from repo root: .\scripts\install_ndk.ps1
# Then: .\scripts\build_apk.ps1

$ErrorActionPreference = 'Stop'
$sdk = "$env:LOCALAPPDATA\Android\Sdk"
$ndkDir = "$sdk\ndk\28.2.13676358"
$zip = "$env:TEMP\android-ndk-r28c-windows.zip"
$uri = 'https://dl.google.com/android/repository/android-ndk-r28c-windows.zip'
$expectedSha1 = '086bba43ff2f5eb0e387b15c8278bb4e0d89ba1d'

if (Test-Path "$ndkDir\source.properties") {
  Write-Host "NDK already installed at $ndkDir" -ForegroundColor Green
  exit 0
}

Remove-Item $ndkDir -Recurse -Force -ErrorAction SilentlyContinue

if (-not (Test-Path $zip) -or ((Get-Item $zip).Length -lt 700000000)) {
  Write-Host "Downloading NDK (~714 MB). Use stable Wi-Fi; can take 10-30 min." -ForegroundColor Yellow
  if (Test-Path $zip) { Remove-Item $zip -Force }
  curl.exe -L $uri -o $zip --retry 10 --retry-delay 10 --continue-at -
  if ($LASTEXITCODE -ne 0) { throw "NDK download failed. Retry: .\scripts\install_ndk.ps1" }
}

$size = (Get-Item $zip).Length
Write-Host "Downloaded $([math]::Round($size/1MB)) MB"

Write-Host "Extracting..."
$extract = "$env:TEMP\android-ndk-extract"
if (Test-Path $extract) { Remove-Item $extract -Recurse -Force }
Expand-Archive -Path $zip -DestinationPath $extract -Force

$inner = Get-ChildItem $extract -Directory | Select-Object -First 1
New-Item -ItemType Directory -Force -Path "$sdk\ndk" | Out-Null
Move-Item $inner.FullName $ndkDir -Force
Remove-Item $extract -Recurse -Force -ErrorAction SilentlyContinue

if (-not (Test-Path "$ndkDir\source.properties")) {
  throw "NDK install incomplete. Delete $ndkDir and retry."
}

Write-Host "NDK installed." -ForegroundColor Green
Write-Host "Next: .\scripts\build_apk.ps1"
