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

REM Ensure C++ extensions are built correctly
echo Building C++ extensions...
python setup.py build_ext --inplace

REM Find Python DLL location and verify it
echo Finding Python DLL location...
python -c "import sys; import os; import shutil; python_dir = os.path.dirname(sys.executable); dll_path = os.path.join(python_dir, 'python312.dll'); print('Python executable:', sys.executable); print('Python directory:', python_dir); print('DLL path:', dll_path); print('DLL exists:', os.path.exists(dll_path)); print('DLL size:', os.path.getsize(dll_path) if os.path.exists(dll_path) else 'N/A')"

REM Copy Python DLL to current directory to ensure it's available
echo Copying Python DLL to current directory...
python -c "import sys; import os; import shutil; python_dir = os.path.dirname(sys.executable); dll_path = os.path.join(python_dir, 'python312.dll'); local_dll = 'python312.dll'; shutil.copy2(dll_path, local_dll) if os.path.exists(dll_path) else None; print('DLL copied to current directory:', os.path.exists(local_dll))"

REM Build the executable with optimizations for speed (NO STRIPPING)
echo Building executable with PyInstaller (optimized for startup speed, no stripping)...
pyinstaller --clean ^
    --hidden-import=inquirer ^
    --hidden-import=readchar ^
    --hidden-import=capgenie.denoise ^
    --hidden-import=capgenie.fuzzy_match ^
    --hidden-import=capgenie.mani ^
    --hidden-import=capgenie.filter_module ^
    --copy-metadata readchar ^
    --onedir ^
    --optimize=2 ^
    --runtime-hook runtime-hook-readchar.py ^
    --additional-hooks-dir=. ^
    --exclude-module matplotlib.tests ^
    --exclude-module numpy.random.tests ^
    --exclude-module scipy.tests ^
    --exclude-module sklearn.tests ^
    --exclude-module Bio.tests ^
    --exclude-module plotly.tests ^
    --collect-all capgenie ^
    --add-data "src/capgenie;capgenie" ^
    --add-binary "python312.dll;." ^
    src/capgenie/cli.py

REM Check if build succeeded
if exist "%DIST_DIR%\cli\cli.exe" (
    echo Build successful - testing executable
    echo Testing executable location: %DIST_DIR%\cli\cli.exe
    dir "%DIST_DIR%\cli"
    echo Testing executable size and properties...
    python -c "import os; exe_path = r'%DIST_DIR%\cli\cli.exe'; print('Executable size:', os.path.getsize(exe_path) if os.path.exists(exe_path) else 'Not found')"
    echo Running executable test...
    "%DIST_DIR%\cli\cli.exe" --help
    if %ERRORLEVEL% neq 0 (
        echo Executable test failed with exit code %ERRORLEVEL%
        echo This may indicate a runtime issue
    ) else (
        echo Executable test completed successfully
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

echo Build completed successfully!
echo Executable location: %DIST_DIR%\cli\cli.exe
echo Launcher script: %DIST_DIR%\capgenie.bat 