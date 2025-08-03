@echo off
echo Building CapGenie executable for Windows (Maximum Optimization)...

REM Configuration
set SCRIPT_DIR=%~dp0
set BUILD_DIR=%SCRIPT_DIR%build
set DIST_DIR=%SCRIPT_DIR%dist

REM Check if we're in the correct directory
if not exist "pyproject.toml" (
    echo pyproject.toml not found
    exit /b 1
)

echo pyproject.toml found - proceeding with optimized build

REM Clean previous builds
echo Cleaning previous builds...
if exist "%BUILD_DIR%" rmdir /s /q "%BUILD_DIR%"
if exist "%DIST_DIR%" rmdir /s /q "%DIST_DIR%"

REM Install PyInstaller with latest version
echo Installing PyInstaller...
pip install --upgrade pyinstaller

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

REM Build the executable with maximum optimizations
echo Building executable with PyInstaller (maximum optimization)...
pyinstaller --clean ^
    --specpath . ^
    capgenie-optimized.spec ^
    --add-binary "python312.dll;." ^
    --log-level WARN

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

REM Calculate final size
echo Calculating final executable size...
python -c "import os; import glob; total_size = 0; for root, dirs, files in os.walk(r'%DIST_DIR%\cli'): total_size += sum(os.path.getsize(os.path.join(root, name)) for name in files); print(f'Total executable size: {total_size / (1024*1024):.2f} MB')"

echo Optimized build completed successfully!
echo Executable location: %DIST_DIR%\cli\cli.exe
echo Launcher script: %DIST_DIR%\capgenie.bat
echo.
echo Optimization features applied:
echo - Aggressive module exclusion
echo - UPX compression enabled
echo - Binary stripping enabled
echo - Optimized Python bytecode
echo - Minimal dependencies included 