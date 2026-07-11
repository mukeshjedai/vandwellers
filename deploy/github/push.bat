@echo off
setlocal
if "%~1"=="" (
  echo Usage: push.bat "Your commit message"
  exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0push.ps1" -Message %*
exit /b %ERRORLEVEL%
