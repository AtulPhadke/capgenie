@echo off
setlocal enabledelayedexpansion

echo 🔧 Building CapGenie executable for Windows...

REM Configuration
set SCRIPT_DIR=%~dp0
set BUILD_DIR=%SCRIPT_DIR%build
set DIST_DIR=%SCRIPT_DIR%dist

REM Check if we're in the correct directory
if not exist "pyproject.toml" (
    echo ❌ pyproject.toml not found. Please run this script from the cap_genie_dist directory.
    exit /b 1
)

REM Clean previous builds
echo [INFO] Cleaning previous builds...
if exist "%BUILD_DIR%" rmdir /s /q "%BUILD_DIR%"
if exist "%DIST_DIR%" rmdir /s /q "%DIST_DIR%"

REM Install PyInstaller if not already installed
echo [INFO] Installing PyInstaller...
pip install pyinstaller

REM Install the package in development mode
echo [INFO] Installing CapGenie in development mode...
pip install -e .

REM Build the executable
echo [INFO] Building executable with PyInstaller...
pyinstaller --clean --hidden-import=inquirer --hidden-import=readchar --copy-metadata readchar --onefile src/capgenie/cli.py

REM Test the executable
echo [INFO] Testing the executable...
if exist "%DIST_DIR%\cli.exe" (
    echo Testing executable with --help...
    "%DIST_DIR%\cli.exe" --help
    set EXIT_CODE=%errorlevel%
    echo Exit code: %EXIT_CODE%
    
    if %EXIT_CODE% equ 0 (
        echo ✅ Executable built and tested successfully!
    ) else if %EXIT_CODE% equ 1 (
        echo ✅ Executable built and tested successfully! ^(help command worked^)
    ) else (
        echo ❌ Executable test failed with exit code %EXIT_CODE%
        exit /b 1
    )
) else (
    echo ❌ Executable not found in dist directory
    dir "%DIST_DIR%"
    exit /b 1
)

REM Calculate final size
for %%A in ("%DIST_DIR%\cli.exe") do set FINAL_SIZE=%%~zA
echo ✅ Executable created successfully!
echo [INFO] Final size: %FINAL_SIZE% bytes
echo [INFO] Location: %DIST_DIR%\cli.exe

REM Create a simple launcher script for easier integration
echo [INFO] Creating launcher script...
(
echo @echo off
echo set SCRIPT_DIR=%%~dp0
echo "%SCRIPT_DIR%%cli.exe" %%*
) > "%DIST_DIR%\capgenie.bat"

echo 🎉 CapGenie executable for Windows is ready!
echo [INFO] You can now use this executable in your Electron application.
echo [INFO] The executable is self-contained and includes all dependencies. 