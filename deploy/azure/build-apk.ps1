# Build Van Dwellers release APK pointing at production API.
param(
    [string]$OutputName = "VanDwellers-release.apk"
)

$ErrorActionPreference = "Stop"
$cfg = . "$PSScriptRoot\..\scripts\Load-Config.ps1" -ConfigPath "$PSScriptRoot\config.json"

$repoRoot = Resolve-Path "$PSScriptRoot\..\.."
Push-Location $repoRoot

Write-Host "Building release APK (API: $($cfg.ApiUrl))..." -ForegroundColor Cyan
flutter pub get
flutter build apk --release --dart-define=API_BASE_URL=$($cfg.ApiUrl)

$builtApk = Join-Path $repoRoot "build\app\outputs\flutter-apk\app-release.apk"
$outApk = Join-Path $repoRoot $OutputName

Copy-Item $builtApk $outApk -Force
Write-Host "APK ready: $outApk" -ForegroundColor Green

Pop-Location
