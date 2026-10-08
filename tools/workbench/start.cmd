@echo off
cd /d "%~dp0..\.."
python tools\workbench\server.py
if errorlevel 1 pause
