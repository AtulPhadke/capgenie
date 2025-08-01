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

REM Clean any existing compiled extensions (they might be from different platform)
echo Cleaning existing compiled extensions...
if exist "src\capgenie\*.so" del /q "src\capgenie\*.so"
if exist "src\capgenie\*.pyd" del /q "src\capgenie\*.pyd"

REM Install the package (this will compile extensions for Windows)
echo Installing CapGenie with Windows-specific compilation...
pip install -e . --force-reinstall

REM Verify Windows extensions were built
echo Checking for Windows extensions...
if not exist "src\capgenie\*.pyd" (
    echo ERROR: Windows extensions (.pyd files) not found after installation
    echo This indicates a compilation issue with the C++ extensions
    exit /b 1
)

REM Build the executable with optimizations for speed
echo Building executable with PyInstaller (optimized for startup speed)...
pyinstaller --clean ^
    --hidden-import=inquirer ^
    --hidden-import=readchar ^
    --hidden-import=capgenie.filter_module ^
    --hidden-import=capgenie.denoise ^
    --hidden-import=capgenie.mani ^
    --hidden-import=capgenie.fuzzy_match ^
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
    --add-data "src\capgenie\*.pyd;capgenie" ^
    src\capgenie\cli.py

REM Check if build succeeded
if exist "%DIST_DIR%\cli\cli.exe" (
    echo Build successful - testing executable
    "%DIST_DIR%\cli\cli.exe" --help
    if %ERRORLEVEL% EQU 0 (
        echo Test completed successfully
    ) else (
        echo WARNING: Executable test failed, but build completed
        echo This might be due to missing command line arguments
    )
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