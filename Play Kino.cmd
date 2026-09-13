@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0.tools\play-kino.ps1"
if errorlevel 1 pause
