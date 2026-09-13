@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0.tools\play-coast.ps1"
if errorlevel 1 pause
