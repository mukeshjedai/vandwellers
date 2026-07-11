@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0deploy-backend.ps1" %*
exit /b %ERRORLEVEL%
