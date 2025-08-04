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
    --hidden-import=openpyxl ^
    --hidden-import=openpyxl.workbook ^
    --hidden-import=openpyxl.worksheet ^
    --hidden-import=openpyxl.cell ^
    --hidden-import=openpyxl.styles ^
    --hidden-import=seaborn ^
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
    --exclude-module collections ^
    --exclude-module itertools ^
    --exclude-module functools ^
    --exclude-module operator ^
    --exclude-module types ^
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
    --exclude-module typing_extensions ^
    --exclude-module zipp ^
    --exclude-module importlib_metadata ^
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
    --exclude-module pkg_resources.tests.test_develop ^
    --exclude-module pkg_resources.tests.test_distutils ^
    --exclude-module pkg_resources.tests.test_egg_info ^
    --exclude-module pkg_resources.tests.test_extern ^
    --exclude-module pkg_resources.tests.test_find ^
    --exclude-module pkg_resources.tests.test_markers ^
    --exclude-module pkg_resources.tests.test_pkg_resources ^
    --exclude-module pkg_resources.tests.test_scripts ^
    --exclude-module pkg_resources.tests.test_util ^
    --exclude-module pkg_resources.tests.test_wsgi ^
    --exclude-module pkg_resources.tests.test_zip ^
    --exclude-module pkg_resources.tests.test_zipimport ^
    --exclude-module pkg_resources.tests.test_zipimport2 ^
    --exclude-module pkg_resources.tests.test_zipimport3 ^
    --exclude-module pkg_resources.tests.test_zipimport4 ^
    --exclude-module pkg_resources.tests.test_zipimport5 ^
    --exclude-module pkg_resources.tests.test_zipimport6 ^
    --exclude-module pkg_resources.tests.test_zipimport7 ^
    --exclude-module pkg_resources.tests.test_zipimport8 ^
    --exclude-module pkg_resources.tests.test_zipimport9 ^
    --exclude-module pkg_resources.tests.test_zipimport10 ^
    --exclude-module pkg_resources.tests.test_zipimport11 ^
    --exclude-module pkg_resources.tests.test_zipimport12 ^
    --exclude-module pkg_resources.tests.test_zipimport13 ^
    --exclude-module pkg_resources.tests.test_zipimport14 ^
    --exclude-module pkg_resources.tests.test_zipimport15 ^
    --exclude-module pkg_resources.tests.test_zipimport16 ^
    --exclude-module pkg_resources.tests.test_zipimport17 ^
    --exclude-module pkg_resources.tests.test_zipimport18 ^
    --exclude-module pkg_resources.tests.test_zipimport19 ^
    --exclude-module pkg_resources.tests.test_zipimport20 ^
    --exclude-module pkg_resources.tests.test_zipimport21 ^
    --exclude-module pkg_resources.tests.test_zipimport22 ^
    --exclude-module pkg_resources.tests.test_zipimport23 ^
    --exclude-module pkg_resources.tests.test_zipimport24 ^
    --exclude-module pkg_resources.tests.test_zipimport25 ^
    --exclude-module pkg_resources.tests.test_zipimport26 ^
    --exclude-module pkg_resources.tests.test_zipimport27 ^
    --exclude-module pkg_resources.tests.test_zipimport28 ^
    --exclude-module pkg_resources.tests.test_zipimport29 ^
    --exclude-module pkg_resources.tests.test_zipimport30 ^
    --exclude-module pkg_resources.tests.test_zipimport31 ^
    --exclude-module pkg_resources.tests.test_zipimport32 ^
    --exclude-module pkg_resources.tests.test_zipimport33 ^
    --exclude-module pkg_resources.tests.test_zipimport34 ^
    --exclude-module pkg_resources.tests.test_zipimport35 ^
    --exclude-module pkg_resources.tests.test_zipimport36 ^
    --exclude-module pkg_resources.tests.test_zipimport37 ^
    --exclude-module pkg_resources.tests.test_zipimport38 ^
    --exclude-module pkg_resources.tests.test_zipimport39 ^
    --exclude-module pkg_resources.tests.test_zipimport40 ^
    --exclude-module pkg_resources.tests.test_zipimport41 ^
    --exclude-module pkg_resources.tests.test_zipimport42 ^
    --exclude-module pkg_resources.tests.test_zipimport43 ^
    --exclude-module pkg_resources.tests.test_zipimport44 ^
    --exclude-module pkg_resources.tests.test_zipimport45 ^
    --exclude-module pkg_resources.tests.test_zipimport46 ^
    --exclude-module pkg_resources.tests.test_zipimport47 ^
    --exclude-module pkg_resources.tests.test_zipimport48 ^
    --exclude-module pkg_resources.tests.test_zipimport49 ^
    --exclude-module pkg_resources.tests.test_zipimport50 ^
    --exclude-module pkg_resources.tests.test_zipimport51 ^
    --exclude-module pkg_resources.tests.test_zipimport52 ^
    --exclude-module pkg_resources.tests.test_zipimport53 ^
    --exclude-module pkg_resources.tests.test_zipimport54 ^
    --exclude-module pkg_resources.tests.test_zipimport55 ^
    --exclude-module pkg_resources.tests.test_zipimport56 ^
    --exclude-module pkg_resources.tests.test_zipimport57 ^
    --exclude-module pkg_resources.tests.test_zipimport58 ^
    --exclude-module pkg_resources.tests.test_zipimport59 ^
    --exclude-module pkg_resources.tests.test_zipimport60 ^
    --exclude-module pkg_resources.tests.test_zipimport61 ^
    --exclude-module pkg_resources.tests.test_zipimport62 ^
    --exclude-module pkg_resources.tests.test_zipimport63 ^
    --exclude-module pkg_resources.tests.test_zipimport64 ^
    --exclude-module pkg_resources.tests.test_zipimport65 ^
    --exclude-module pkg_resources.tests.test_zipimport66 ^
    --exclude-module pkg_resources.tests.test_zipimport67 ^
    --exclude-module pkg_resources.tests.test_zipimport68 ^
    --exclude-module pkg_resources.tests.test_zipimport69 ^
    --exclude-module pkg_resources.tests.test_zipimport70 ^
    --exclude-module pkg_resources.tests.test_zipimport71 ^
    --exclude-module pkg_resources.tests.test_zipimport72 ^
    --exclude-module pkg_resources.tests.test_zipimport73 ^
    --exclude-module pkg_resources.tests.test_zipimport74 ^
    --exclude-module pkg_resources.tests.test_zipimport75 ^
    --exclude-module pkg_resources.tests.test_zipimport76 ^
    --exclude-module pkg_resources.tests.test_zipimport77 ^
    --exclude-module pkg_resources.tests.test_zipimport78 ^
    --exclude-module pkg_resources.tests.test_zipimport79 ^
    --exclude-module pkg_resources.tests.test_zipimport80 ^
    --exclude-module pkg_resources.tests.test_zipimport81 ^
    --exclude-module pkg_resources.tests.test_zipimport82 ^
    --exclude-module pkg_resources.tests.test_zipimport83 ^
    --exclude-module pkg_resources.tests.test_zipimport84 ^
    --exclude-module pkg_resources.tests.test_zipimport85 ^
    --exclude-module pkg_resources.tests.test_zipimport86 ^
    --exclude-module pkg_resources.tests.test_zipimport87 ^
    --exclude-module pkg_resources.tests.test_zipimport88 ^
    --exclude-module pkg_resources.tests.test_zipimport89 ^
    --exclude-module pkg_resources.tests.test_zipimport90 ^
    --exclude-module pkg_resources.tests.test_zipimport91 ^
    --exclude-module pkg_resources.tests.test_zipimport92 ^
    --exclude-module pkg_resources.tests.test_zipimport93 ^
    --exclude-module pkg_resources.tests.test_zipimport94 ^
    --exclude-module pkg_resources.tests.test_zipimport95 ^
    --exclude-module pkg_resources.tests.test_zipimport96 ^
    --exclude-module pkg_resources.tests.test_zipimport97 ^
    --exclude-module pkg_resources.tests.test_zipimport98 ^
    --exclude-module pkg_resources.tests.test_zipimport99 ^
    --exclude-module pkg_resources.tests.test_zipimport100 ^
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