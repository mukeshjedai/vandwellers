# Push Van Dwellers source code to GitHub.
param(
    [Parameter(Mandatory = $true)]
    [string]$Message,
    [switch]$AllowEmpty
)

$ErrorActionPreference = "Stop"
$cfg = . "$PSScriptRoot\..\scripts\Load-Config.ps1" -ConfigPath "$PSScriptRoot\..\azure\config.json"

$repoRoot = Resolve-Path "$PSScriptRoot\..\.."
Push-Location $repoRoot

if (-not (Test-Path ".git")) {
    throw "Not a git repository. Run: git init && git remote add origin $($cfg.GitHubRemote)"
}

$remoteUrl = git remote get-url origin 2>$null
if (-not $remoteUrl) {
    Write-Host "Adding origin remote: $($cfg.GitHubRemote)"
    git remote add origin $cfg.GitHubRemote
}

Write-Host "=== Push to GitHub ===" -ForegroundColor Cyan
git status

git add -A
$status = git status --porcelain
if (-not $status -and -not $AllowEmpty) {
    Write-Host "Nothing to commit." -ForegroundColor Yellow
    Pop-Location
    exit 0
}

if ($status -or $AllowEmpty) {
    git commit -m $Message
}

$branch = $cfg.GitHubBranch
git push -u origin "HEAD:$branch"

Write-Host ""
Write-Host "Pushed to $($cfg.GitHubRemote) ($branch)" -ForegroundColor Green

Pop-Location
