# Build APK, bump versions.txt, push to GitHub, and create a GitHub Release.
param(
    [int]$VersionBuild,
    [string]$Tag,
    [string]$ReleaseNotes = "Van Dwellers update."
)

$ErrorActionPreference = "Stop"
$cfg = . "$PSScriptRoot\..\scripts\Load-Config.ps1" -ConfigPath "$PSScriptRoot\..\azure\config.json"

$repoRoot = Resolve-Path "$PSScriptRoot\..\.."
Push-Location $repoRoot

if (-not $VersionBuild) {
    $versionsFile = Join-Path $repoRoot "versions.txt"
    $current = if (Test-Path $versionsFile) {
        [int](Get-Content $versionsFile -TotalCount 1)
    } else { 0 }
    $VersionBuild = $current + 1
}

if (-not $Tag) { $Tag = "v$VersionBuild" }

Write-Host "Building APK for release $Tag (build $VersionBuild)..." -ForegroundColor Cyan
& "$PSScriptRoot\..\azure\build-apk.ps1"

$apkPath = Join-Path $repoRoot "VanDwellers-release.apk"
if (-not (Test-Path $apkPath)) {
    throw "APK not found at $apkPath"
}

$downloadUrl = "https://github.com/mukeshjedai/vandwellers/releases/download/$Tag/VanDwellers-release.apk"
$versionsContent = @(
    "$VersionBuild"
    $downloadUrl
) -join "`n"
Set-Content -Path (Join-Path $repoRoot "versions.txt") -Value $versionsContent -NoNewline
Add-Content -Path (Join-Path $repoRoot "versions.txt") -Value ""

# Update pubspec build number if present
$pubspec = Join-Path $repoRoot "pubspec.yaml"
if (Test-Path $pubspec) {
    $text = Get-Content $pubspec -Raw
    if ($text -match 'version:\s*(\d+\.\d+\.\d+)\+\d+') {
        $versionName = $Matches[1]
        $newLine = "version: ${versionName}+$VersionBuild"
        $text = $text -replace 'version:\s*\d+\.\d+\.\d+\+\d+', $newLine
        Set-Content -Path $pubspec -Value $text -NoNewline
    }
}

& "$PSScriptRoot\push.ps1" -Message "Release $Tag (build $VersionBuild)"

Write-Host "Creating GitHub release $Tag..." -ForegroundColor Cyan

$gh = Get-Command gh -ErrorAction SilentlyContinue
if ($gh) {
    gh release create $Tag $apkPath `
        --repo "mukeshjedai/vandwellers" `
        --title "Van Dwellers $Tag" `
        --notes $ReleaseNotes
    Write-Host "Release published via GitHub CLI." -ForegroundColor Green
    Pop-Location
    exit 0
}

# Fallback: GitHub REST API with git credential token
$credInput = @"
protocol=https
host=github.com

"@
$cred = $credInput | git credential fill
$token = ($cred | Select-String '^password=(.+)$').Matches.Groups[1].Value
if (-not $token) { throw "GitHub CLI not found and no git credential token available." }

$releaseBody = @{
    tag_name   = $Tag
    name       = "Van Dwellers $Tag"
    body       = $ReleaseNotes
    draft      = $false
    prerelease = $false
} | ConvertTo-Json

$release = Invoke-RestMethod `
    -Uri "https://api.github.com/repos/mukeshjedai/vandwellers/releases" `
    -Method POST `
    -Headers @{
        Authorization = "Bearer $token"
        Accept        = "application/vnd.github+json"
    } `
    -Body $releaseBody `
    -ContentType "application/json"

$uploadUri = "https://uploads.github.com/repos/mukeshjedai/vandwellers/releases/$($release.id)/assets?name=VanDwellers-release.apk"
Invoke-RestMethod `
    -Uri $uploadUri `
    -Method POST `
    -Headers @{
        Authorization = "Bearer $token"
        Accept        = "application/vnd.github+json"
        "Content-Type" = "application/vnd.android.package-archive"
    } `
    -InFile $apkPath | Out-Null

Write-Host "Release published: $($release.html_url)" -ForegroundColor Green
Pop-Location
