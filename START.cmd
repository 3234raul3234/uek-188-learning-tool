@echo off
title UEK 188 Learning Tool setup
if not exist "%~dp0Setup\installieren.ps1" (
  echo Please extract the ZIP file first: right-click the ZIP file, "Extract All",
  echo then double-click START.cmd in the extracted folder.
  pause
  exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Setup\installieren.ps1"
pause
