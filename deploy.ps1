# Van Dwellers deployment entry point
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("azure-backend", "azure-full", "apk", "github-push", "github-release")]
    [string]$Target,
    [string]$Message = "Update Van Dwellers",
    [string]$ReleaseNotes = "Van Dwellers update."
)

$root = $PSScriptRoot

switch ($Target) {
    "azure-backend" {
        & "$root\deploy\azure\deploy-backend.ps1"
    }
    "azure-full" {
        & "$root\deploy\azure\deploy-full.ps1"
    }
    "apk" {
        & "$root\deploy\azure\build-apk.ps1"
    }
    "github-push" {
        & "$root\deploy\github\push.ps1" -Message $Message
    }
    "github-release" {
        & "$root\deploy\github\release.ps1" -ReleaseNotes $ReleaseNotes
    }
}
