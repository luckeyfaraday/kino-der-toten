@echo off
title Black Ops - Mobile
node "%~dp0.tools\serve.mjs" 5184 --lan
if errorlevel 1 pause
