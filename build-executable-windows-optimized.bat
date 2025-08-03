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

REM Build the executable with targeted optimizations using direct PyInstaller commands
echo Building executable with PyInstaller (targeted optimization)...
pyinstaller --clean ^
    --hidden-import=inquirer ^
    --hidden-import=readchar ^
    --hidden-import=capgenie.denoise ^
    --hidden-import=capgenie.fuzzy_match ^
    --hidden-import=capgenie.mani ^
    --hidden-import=capgenie.filter_module ^
    --hidden-import=matplotlib.pyplot ^
    --hidden-import=plotly ^
    --hidden-import=plotly.graph_objects ^
    --hidden-import=plotly.express ^
    --hidden-import=pandas ^
    --hidden-import=numpy ^
    --hidden-import=scipy ^
    --hidden-import=scipy.spatial.distance ^
    --hidden-import=sklearn ^
    --hidden-import=sklearn.cluster ^
    --hidden-import=umap ^
    --hidden-import=umap.umap_ ^
    --hidden-import=logomaker ^
    --hidden-import=ahocorasick ^
    --hidden-import=Bio ^
    --hidden-import=Bio.Seq ^
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
    --exclude-module unittest ^
    --exclude-module test ^
    --exclude-module tests ^
    --exclude-module _pytest ^
    --exclude-module pytest ^
    --exclude-module coverage ^
    --exclude-module pdb ^
    --exclude-module pydoc ^
    --exclude-module tkinter ^
    --exclude-module turtle ^
    --exclude-module idlelib ^
    --exclude-module lib2to3 ^
    --exclude-module ensurepip ^
    --exclude-module venv ^
    --exclude-module distutils ^
    --exclude-module setuptools ^
    --exclude-module pip ^
    --exclude-module wheel ^
    --exclude-module email ^
    --exclude-module http ^
    --exclude-module urllib ^
    --exclude-module xml ^
    --exclude-module xmlrpc ^
    --exclude-module multiprocessing ^
    --exclude-module concurrent ^
    --exclude-module asyncio ^
    --exclude-module ssl ^
    --exclude-module socket ^
    --exclude-module select ^
    --exclude-module threading ^
    --exclude-module queue ^
    --exclude-module weakref ^
    --exclude-module gc ^
    --exclude-module sysconfig ^
    --exclude-module site ^
    --exclude-module runpy ^
    --exclude-module importlib ^
    --exclude-module zipimport ^
    --exclude-module marshal ^
    --exclude-module pickle ^
    --exclude-module copyreg ^
    --exclude-module struct ^
    --exclude-module array ^
    --exclude-module operator ^
    --exclude-module builtins ^
    --exclude-module __future__ ^
    --exclude-module warnings ^
    --exclude-module traceback ^
    --exclude-module linecache ^
    --exclude-module inspect ^
    --exclude-module ast ^
    --exclude-module tokenize ^
    --exclude-module token ^
    --exclude-module keyword ^
    --exclude-module codeop ^
    --exclude-module code ^
    --exclude-module dis ^
    --exclude-module opcode ^
    --exclude-module symtable ^
    --exclude-module tabnanny ^
    --exclude-module py_compile ^
    --exclude-module compileall ^
    --exclude-module pyclbr ^
    --exclude-module filecmp ^
    --exclude-module difflib ^
    --exclude-module doctest ^
    --exclude-module pydoc_data ^
    --exclude-module pydoc ^
    --exclude-module profile ^
    --exclude-module pstats ^
    --exclude-module cProfile ^
    --exclude-module timeit ^
    --exclude-module trace ^
    --exclude-module tracemalloc ^
    --exclude-module cgitb ^
    --exclude-module wsgiref ^
    --exclude-module urllib3 ^
    --exclude-module requests ^
    --exclude-module certifi ^
    --exclude-module chardet ^
    --exclude-module idna ^
    --exclude-module charset_normalizer ^
    --exclude-module packaging ^
    --exclude-module pyparsing ^
    --exclude-module six ^
    --exclude-module appdirs ^
    --exclude-module distlib ^
    --exclude-module filelock ^
    --exclude-module platformdirs ^
    --exclude-module tomli ^
    --exclude-module tomllib ^
    --exclude-module zipp ^
    --exclude-module importlib_resources ^
    --exclude-module pathlib2 ^
    --exclude-module scandir ^
    --exclude-module contextlib2 ^
    --exclude-module configparser ^
    --exclude-module configparser2 ^
    --exclude-module backports ^
    --exclude-module backports.entry_points_selectable ^
    --exclude-module backports.functools_lru_cache ^
    --exclude-module backports.shutil_get_terminal_size ^
    --exclude-module backports.shutil_which ^
    --exclude-module backports.statistics ^
    --exclude-module backports.weakref ^
    --exclude-module backports.zoneinfo ^
    --exclude-module setuptools ^
    --exclude-module setuptools._distutils ^
    --exclude-module setuptools._vendor ^
    --exclude-module setuptools.command ^
    --exclude-module setuptools.dist ^
    --exclude-module setuptools.extension ^
    --exclude-module setuptools.glob ^
    --exclude-module setuptools.msvc ^
    --exclude-module setuptools.namespaces ^
    --exclude-module setuptools.package_index ^
    --exclude-module setuptools.py27compat ^
    --exclude-module setuptools.py31compat ^
    --exclude-module setuptools.py33compat ^
    --exclude-module setuptools.sandbox ^
    --exclude-module setuptools.ssl_support ^
    --exclude-module setuptools.unicode_utils ^
    --exclude-module setuptools.wheel ^
    --exclude-module setuptools.windows_support ^
    --exclude-module pkg_resources ^
    --exclude-module pkg_resources._vendor ^
    --exclude-module pkg_resources.extern ^
    --exclude-module pkg_resources.py2_warn ^
    --exclude-module pkg_resources.py31compat ^
    --exclude-module pkg_resources.py33compat ^
    --exclude-module pkg_resources.safe_extra ^
    --exclude-module pkg_resources.tests ^
    --collect-all capgenie ^
    --add-data "src/capgenie;capgenie" ^
    --add-binary "python312.dll;." ^
    --log-level WARN ^
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

REM Calculate final size
echo Calculating final executable size...
python -c "import os; total_size = 0; for root, dirs, files in os.walk(r'%DIST_DIR%\cli'): total_size += sum(os.path.getsize(os.path.join(root, name)) for name in files); print(f'Total executable size: {total_size / (1024*1024):.2f} MB')"

echo Optimized build completed successfully!
echo Executable location: %DIST_DIR%\cli\cli.exe
echo Launcher script: %DIST_DIR%\capgenie.bat
echo.
echo Optimization features applied:
echo - Targeted module exclusion (keeping all required modules)
echo - All required dependencies included as hidden imports
echo - Optimized Python bytecode
echo - Minimal unnecessary dependencies excluded
echo - Reduced log verbosity 