@echo off
setlocal
cd /d "%~dp0"
if not exist ".venv\Scripts\python.exe" (
  echo Run setup_windows.bat first.
  exit /b 1
)
".venv\Scripts\python.exe" -m jobbot.cli run
exit /b %errorlevel%
