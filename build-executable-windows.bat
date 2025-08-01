@echo off
echo Building CapGenie executable for Windows (Optimized for Speed)...

REM Configuration
set SCRIPT_DIR=%~dp0
set BUILD_DIR=%SCRIPT_DIR%build
set DIST_DIR=%SCRIPT_DIR%dist

REM Check if we're in the correct directory
if not exist "pyproject.toml" (
    echo pyproject.toml not found
    exit /b 1
)

echo pyproject.toml found - proceeding with build

REM Clean previous builds
echo Cleaning previous builds...
if exist "%BUILD_DIR%" rmdir /s /q "%BUILD_DIR%"
if exist "%DIST_DIR%" rmdir /s /q "%DIST_DIR%"

REM Install PyInstaller
echo Installing PyInstaller...
pip install pyinstaller

REM Install the package
echo Installing CapGenie...
pip install -e .

REM Build the executable with optimizations for speed
echo Building executable with PyInstaller (optimized for startup speed)...
pyinstaller --clean ^
    --hidden-import=inquirer ^
    --hidden-import=readchar ^
    --copy-metadata readchar ^
    --onedir ^
    --strip ^
    --optimize=2 ^
    --exclude-module matplotlib.tests ^
    --exclude-module numpy.random.tests ^
    --exclude-module scipy.tests ^
    --exclude-module sklearn.tests ^
    --exclude-module Bio.tests ^
    --exclude-module plotly.tests ^
    src/capgenie/cli.py

REM Check if build succeeded
if exist "%DIST_DIR%\cli\cli.exe" (
    echo Build successful - testing executable
    "%DIST_DIR%\cli\cli.exe" --help
    echo Test completed
) else (
    echo Build failed - executable not found
    dir "%DIST_DIR%"
    exit /b 1
)

REM Create a simple launcher script for easier integration
echo Creating launcher script...
(
echo @echo off
echo set SCRIPT_DIR=%%~dp0
echo "%SCRIPT_DIR%cli\cli.exe" %%*
) > "%DIST_DIR%\capgenie.bat"

echo Windows build completed successfully
echo Note: This creates a directory structure instead of a single file for faster startup.
echo Use the launcher script 'capgenie.bat' for easier integration. 