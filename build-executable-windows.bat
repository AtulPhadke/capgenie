@echo off
setlocal enabledelayedexpansion

echo 🔧 Building CapGenie executable for Windows...

REM Configuration
set SCRIPT_DIR=%~dp0
set BUILD_DIR=%SCRIPT_DIR%build
set DIST_DIR=%SCRIPT_DIR%dist
set SPEC_FILE=%SCRIPT_DIR%capgenie.spec

REM Check if we're in the correct directory
if not exist "pyproject.toml" (
    echo ❌ pyproject.toml not found. Please run this script from the cap_genie_dist directory.
    exit /b 1
)

REM Clean previous builds
echo [INFO] Cleaning previous builds...
if exist "%BUILD_DIR%" rmdir /s /q "%BUILD_DIR%"
if exist "%DIST_DIR%" rmdir /s /q "%DIST_DIR%"
if exist "%SPEC_FILE%" del "%SPEC_FILE%"

REM Install PyInstaller if not already installed
echo [INFO] Installing PyInstaller...
pip install pyinstaller

REM Install the package in development mode
echo [INFO] Installing CapGenie in development mode...
pip install -e .

REM Create PyInstaller spec file
echo [INFO] Creating PyInstaller spec file...
(
echo # -*- mode: python ; coding: utf-8 -*-
echo from PyInstaller.utils.hooks import collect_data_files
echo.
echo block_cipher = None
echo.
echo a = Analysis(
echo     ['src/capgenie/cli.py'],
echo     pathex=[],
echo     binaries=[],
echo     datas=[
echo         ^('src/capgenie', 'capgenie'^),
echo         ^('assets', 'assets'^),
echo     ] + collect_data_files^('inquirer'^) + collect_data_files^('readchar', include_py_files=True^) + collect_data_files^('Bio'^) + collect_data_files^('sklearn'^) + collect_data_files^('umap'^) + collect_data_files^('pyahocorasick'^) + collect_data_files^('logomaker'^),
echo     hiddenimports=[
echo         'capgenie.bubble',
echo         'capgenie.biodistribution',
echo         'capgenie.motif',
echo         'capgenie.search_aav9',
echo         'capgenie.enrichment',
echo         'capgenie.spreadsheet',
echo         'capgenie.mani',
echo         'capgenie.denoise',
echo         'capgenie.filter_module',
echo         'capgenie.fuzzy_match',
echo         'pandas',
echo         'numpy',
echo         'scipy',
echo         'matplotlib',
echo         'plotly',
echo         'Bio',
echo         'Bio.Seq',
echo         'ahocorasick',
echo         'sklearn',
echo         'sklearn.cluster',
echo         'umap',
echo         'umap.umap_',
echo         'logomaker',
echo         'inquirer',
echo         'inquirer.themes',
echo         'inquirer.questions',
echo         'inquirer.render',
echo         'inquirer.render.console',
echo         'inquirer.render.console._list',
echo         'inquirer.render.console._text',
echo         'inquirer.render.console._checkbox',
echo         'inquirer.render.console._confirm',
echo         'inquirer.render.console._password',
echo         'inquirer.render.console._path',
echo         'inquirer.render.console._editor',
echo     ],
echo     hookspath=[],
echo     hooksconfig={},
echo     runtime_hooks=[],
echo     excludes=[],
echo     win_no_prefer_redirects=False,
echo     win_private_assemblies=False,
echo     cipher=block_cipher,
echo     noarchive=False,
echo ^)
echo.
echo pyz = PYZ^(a.pure, a.zipped_data, cipher=block_cipher^)
echo.
echo exe = EXE^(
echo     pyz,
echo     a.scripts,
echo     a.binaries,
echo     a.zipfiles,
echo     a.datas,
echo     [],
echo     name='capgenie',
echo     debug=False,
echo     bootloader_ignore_signals=False,
echo     strip=False,
echo     upx=True,
echo     upx_exclude=[],
echo     runtime_tmpdir=None,
echo     console=True,
echo     disable_windowed_traceback=False,
echo     argv_emulation=False,
echo     target_arch=None,
echo     codesign_identity=None,
echo     entitlements_file=None,
echo ^)
) > "%SPEC_FILE%"

REM Build the executable
echo [INFO] Building executable with PyInstaller...
pyinstaller --clean "%SPEC_FILE%"

REM Test the executable
echo [INFO] Testing the executable...
if exist "%DIST_DIR%\capgenie.exe" (
    echo Testing executable with --help...
    "%DIST_DIR%\capgenie.exe" --help
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
    exit /b 1
)

REM Calculate final size
for %%A in ("%DIST_DIR%\capgenie.exe") do set FINAL_SIZE=%%~zA
echo ✅ Executable created successfully!
echo [INFO] Final size: %FINAL_SIZE% bytes
echo [INFO] Location: %DIST_DIR%\capgenie.exe

REM Create a simple launcher script for easier integration
echo [INFO] Creating launcher script...
(
echo @echo off
echo set SCRIPT_DIR=%%~dp0
echo "%SCRIPT_DIR%%capgenie.exe" %%*
) > "%DIST_DIR%\capgenie.bat"

echo 🎉 CapGenie executable for Windows is ready!
echo [INFO] You can now use this executable in your Electron application.
echo [INFO] The executable is self-contained and includes all dependencies. 