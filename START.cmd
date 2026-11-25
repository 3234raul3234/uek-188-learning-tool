@echo off
title UeK 188 Lern-Tool installieren
if not exist "%~dp0Setup\installieren.ps1" (
  echo Bitte zuerst die ZIP-Datei entpacken: Rechtsklick auf die ZIP-Datei, "Alle extrahieren",
  echo dann im entpackten Ordner START.cmd doppelklicken.
  pause
  exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Setup\installieren.ps1"
pause
