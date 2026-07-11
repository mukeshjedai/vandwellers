# Van Dwellers deployment

Scripts and workflows to deploy the backend to **Azure** and publish the app to **GitHub**.

## Prerequisites

- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) — `az login`
- [Azure Functions Core Tools v4](https://learn.microsoft.com/azure/azure-functions/functions-run-local)
- [.NET 9 SDK](https://dotnet.microsoft.com/download)
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- Git

Config lives in `deploy/azure/config.json` (copy from `config.example.json` for new environments).

---

## 1. Deploy to Azure

### First-time (full infrastructure + backend)

Creates resource group, Cosmos DB, storage, Function App, and publishes the API.

```powershell
powershell -ExecutionPolicy Bypass -File deploy/azure/deploy-full.ps1
```

### Backend code only (day-to-day updates)

After infrastructure exists, publish API changes:

```powershell
powershell -ExecutionPolicy Bypass -File deploy/azure/deploy-backend.ps1
```

Or double-click / run:

```bat
deploy\azure\deploy-backend.bat
```

### Build production APK

```powershell
powershell -ExecutionPolicy Bypass -File deploy/azure/build-apk.ps1
```

Output: `VanDwellers-release.apk` in the repo root.

---

## 2. Deploy to GitHub

### Push code to GitHub

```powershell
powershell -ExecutionPolicy Bypass -File deploy/github/push.ps1 -Message "Your commit message"
```

### Release APK to GitHub Releases

Builds APK, bumps `versions.txt`, pushes, and creates a release:

```powershell
powershell -ExecutionPolicy Bypass -File deploy/github/release.ps1 -ReleaseNotes "Bug fixes and map updates"
```

Optional flags: `-VersionBuild 3` `-Tag v3`

---

## GitHub Actions (automatic)

### Azure backend — `.github/workflows/deploy-azure.yml`

Runs on push to `main` when `backend/**` changes, or manually via **Actions → Deploy Azure Functions**.

**Required secret:** `AZURE_CREDENTIALS`

Create with:

```powershell
az ad sp create-for-rbac --name "vandwellers-github" --role contributor `
  --scopes /subscriptions/YOUR_SUBSCRIPTION_ID/resourceGroups/rg-vandwellers-prod `
  --sdk-auth
```

Copy the JSON output into GitHub → **Settings → Secrets → Actions → AZURE_CREDENTIALS**.

### GitHub release — `.github/workflows/github-release.yml`

Manual workflow: **Actions → GitHub Release APK**. Enter build number and tag (e.g. `3`, `v3`).

Uses built-in `GITHUB_TOKEN` for releases.

---

## Quick reference

| Task | PowerShell | Batch (.bat) |
|------|------------|--------------|
| Azure backend update | `deploy/azure/deploy-backend.ps1` | `deploy\azure\deploy-backend.bat` |
| Azure full setup | `deploy/azure/deploy-full.ps1` | `deploy\azure\deploy-full.bat` |
| Build APK | `deploy/azure/build-apk.ps1` | `deploy\azure\build-apk.bat` |
| Push to GitHub | `deploy/github/push.ps1 -Message "..."` | `deploy\github\push.bat "..."` |
| GitHub release + APK | `deploy/github/release.ps1` | `deploy\github\release.bat` |
| All targets (wrapper) | `deploy.ps1 -Target ...` | `deploy.bat ...` |

Production API: `https://func-vandwellers-mk01.azurewebsites.net`  
GitHub repo: `https://github.com/mukeshjedai/vandwellers`
