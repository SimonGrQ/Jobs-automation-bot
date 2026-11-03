@echo off
setlocal
cd /d "%~dp0"
set "PYTHON_EXE="
set "PYTHON_ARGS="
where py >nul 2>nul
if not errorlevel 1 set "PYTHON_EXE=py"
if not defined PYTHON_EXE if exist "%LocalAppData%\Programs\Python\Launcher\py.exe" set "PYTHON_EXE=%LocalAppData%\Programs\Python\Launcher\py.exe"
if not defined PYTHON_EXE if exist "%LocalAppData%\Programs\Python\Python313\python.exe" set "PYTHON_EXE=%LocalAppData%\Programs\Python\Python313\python.exe"
if not defined PYTHON_EXE if exist "%LocalAppData%\Programs\Python\Python312\python.exe" set "PYTHON_EXE=%LocalAppData%\Programs\Python\Python312\python.exe"
if not defined PYTHON_EXE if exist "%LocalAppData%\Programs\Python\Python311\python.exe" set "PYTHON_EXE=%LocalAppData%\Programs\Python\Python311\python.exe"
if not defined PYTHON_EXE (
  echo Python 3.11 or newer is required. Install it from https://www.python.org/downloads/windows/
  exit /b 1
)
if /i "%PYTHON_EXE:~-5%"=="py.exe" set "PYTHON_ARGS=-3"
"%PYTHON_EXE%" %PYTHON_ARGS% -c "import sys; assert sys.version_info >= (3, 11), 'Python 3.11 or newer is required'"
if errorlevel 1 exit /b 1
"%PYTHON_EXE%" %PYTHON_ARGS% -m venv .venv
if errorlevel 1 exit /b %errorlevel%
call .venv\Scripts\activate.bat
python -m pip install --upgrade pip
if errorlevel 1 exit /b %errorlevel%
python -m pip install -e ".[dev]"
if errorlevel 1 exit /b %errorlevel%
python -m playwright install chromium
if errorlevel 1 exit /b %errorlevel%
if not exist profile.json copy profile.example.json profile.json
if errorlevel 1 exit /b %errorlevel%
echo Setup completed. Edit profile.json and config.yaml before running JobBot.
