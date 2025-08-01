@echo off
echo Starting Windows build...
echo Current directory: %CD%
echo Script directory: %~dp0

REM Check if we're in the correct directory
if not exist "pyproject.toml" (
    echo pyproject.toml not found
    exit /b 1
)

echo pyproject.toml found - proceeding with build

REM Install PyInstaller
echo Installing PyInstaller...
pip install pyinstaller

REM Install the package
echo Installing CapGenie...
pip install -e .

REM Build the executable
echo Building executable...
pyinstaller --clean --hidden-import=inquirer --hidden-import=readchar --copy-metadata readchar --onefile src/capgenie/cli.py

REM Check if build succeeded
if exist "dist\cli.exe" (
    echo Build successful - testing executable
    dist\cli.exe --help
    echo Test completed
) else (
    echo Build failed - executable not found
    dir dist
    exit /b 1
)

echo Windows build completed successfully 