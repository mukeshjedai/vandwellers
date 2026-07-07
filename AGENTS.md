# AGENTS.md

## Cursor Cloud specific instructions

### Product overview
Single product, **Van Dwellers** (a van-life community app), split into two parts:

- **Flutter mobile app** (Android-only) at the repo root; code in `lib/`, manifest `pubspec.yaml`.
- **.NET 9 backend** under `backend/` with two interchangeable hosts sharing `VanDwellers.Core`:
  - `backend/VanDwellers.Functions` — primary Azure Functions host (needs the `func` Core Tools, not installed).
  - `backend/VanDwellers.Api` — legacy ASP.NET Core minimal-API host, runs with just the .NET SDK (no `func`).
  Both expose the same `/api/*` surface. For local dev, prefer the legacy `VanDwellers.Api` host.

### Toolchain (already installed in the VM snapshot; on PATH in login shells)
- .NET 9 SDK (`dotnet`), Flutter stable 3.44.x + Dart 3.12.x (`flutter`/`dart`), Android SDK (`$HOME/android-sdk`, `adb`/`sdkmanager`).
- The update script runs `flutter pub get` and `dotnet restore` for both backend hosts. It does NOT reinstall the SDKs (those live in the snapshot).

### Running / testing (non-obvious caveats)
- **Backend needs no external services for dev.** Both hosts default to `Azure:UseLocalFallback=true` with empty Cosmos/Blob connection strings, so they use on-disk `LocalJsonStore` + `LocalPhotoStorage`. No Cosmos DB / Blob Storage / emulator required. Local data persists to JSON files in the system temp dir, so restarting the host keeps registered users.
- Run legacy backend: `cd backend/VanDwellers.Api && ASPNETCORE_URLS="http://0.0.0.0:5000" dotnet run`. Health check: `GET http://localhost:5000/api/health`.
- Flutter checks that work headless: `flutter analyze`, `flutter test`. There is one pre-existing info-level lint (`prefer_final_fields` in `lib/screens/login_screen.dart`) — not an error.
- `flutter build apk --debug` works; the first build auto-downloads NDK + extra SDK platforms/build-tools and takes several minutes.
- **The app cannot be run as a GUI in this headless VM** (Android-only, no `web/` platform, no hardware-accelerated emulator). Exercise core functionality through the backend API instead (register → login → list users → send message).
- The app's API base URL is a compile-time define: `flutter run --dart-define=API_BASE_URL=http://<host>:<port>`; default is the production Azure Functions URL in `lib/config/azure_config.dart`. For an Android emulator hitting a local host, use `http://10.0.2.2:5000`.
- The in-app update checker fetches `versions.txt` from `raw.githubusercontent.com`; it fails gracefully and is not required for core flows.
- Note: the root `README.md` is leftover Flutter boilerplate ("bluetooth_scanner") and is not accurate; trust `pubspec.yaml` and this file instead.
