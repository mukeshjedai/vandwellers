@echo off
setlocal
if "%~1"=="" (
  echo.
  echo Van Dwellers deployment
  echo.
  echo Usage: deploy.bat ^<target^> [options]
  echo.
  echo Targets:
  echo   azure-backend     Publish API to Azure
  echo   azure-full        Full Azure setup ^(first time^)
  echo   apk               Build release APK
  echo   github-push       Push to GitHub  ^(requires message as 2nd arg^)
  echo   github-release    Build APK and create GitHub release
  echo.
  echo Examples:
  echo   deploy.bat azure-backend
  echo   deploy.bat github-push "Fix map and campsite form"
  echo   deploy.bat github-release
  echo.
  exit /b 1
)

set TARGET=%~1
shift

if /i "%TARGET%"=="github-push" (
  if "%~1"=="" (
    echo Error: commit message required for github-push
    echo Example: deploy.bat github-push "Your commit message"
    exit /b 1
  )
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0deploy.ps1" -Target github-push -Message %*
  exit /b %ERRORLEVEL%
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0deploy.ps1" -Target %TARGET% %*
exit /b %ERRORLEVEL%
