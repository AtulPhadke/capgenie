# -*- mode: python ; coding: utf-8 -*-
# Optimized PyInstaller spec for maximum performance and minimal size

import os
import sys
from PyInstaller.utils.hooks import collect_data_files, collect_submodules

# Platform-specific settings
is_windows = sys.platform.startswith('win')

# Collect only essential capgenie modules
capgenie_modules = collect_submodules('capgenie')

# Collect only essential data files
capgenie_data = collect_data_files('capgenie')

# Comprehensive list of modules to exclude for maximum optimization
excluded_modules = [
    # Test modules
    'matplotlib.tests', 'numpy.random.tests', 'scipy.tests', 'sklearn.tests', 
    'Bio.tests', 'plotly.tests', 'unittest', 'test', 'tests', '_pytest', 
    'pytest', 'coverage', 'pkg_resources.tests',
    
    # Development tools
    'pdb', 'pydoc', 'pydoc_data', 'profile', 'pstats', 'cProfile', 'timeit', 
    'trace', 'tracemalloc', 'cgitb', 'doctest', 'py_compile', 'compileall',
    
    # GUI and graphics
    'tkinter', 'turtle', 'idlelib', 'lib2to3', 'matplotlib', 'plotly',
    
    # Package management
    'ensurepip', 'venv', 'distutils', 'setuptools', 'pip', 'wheel',
    'setuptools._distutils', 'setuptools._vendor', 'setuptools.command',
    'setuptools.dist', 'setuptools.extension', 'setuptools.glob',
    'setuptools.msvc', 'setuptools.namespaces', 'setuptools.package_index',
    'setuptools.py27compat', 'setuptools.py31compat', 'setuptools.py33compat',
    'setuptools.sandbox', 'setuptools.ssl_support', 'setuptools.unicode_utils',
    'setuptools.wheel', 'setuptools.windows_support',
    'pkg_resources', 'pkg_resources._vendor', 'pkg_resources.extern',
    'pkg_resources.py2_warn', 'pkg_resources.py31compat', 'pkg_resources.py33compat',
    'pkg_resources.safe_extra',
    
    # Network and web
    'email', 'http', 'urllib', 'xml', 'xmlrpc', 'ssl', 'socket', 'select',
    'urllib3', 'requests', 'certifi', 'chardet', 'idna', 'charset_normalizer',
    'wsgiref',
    
    # Concurrency
    'multiprocessing', 'concurrent', 'asyncio', 'threading', 'queue',
    
    # Core Python modules (keep only essential ones)
    'weakref', 'gc', 'sysconfig', 'site', 'runpy', 'importlib', 'zipimport',
    'marshal', 'pickle', 'copyreg', 'struct', 'array', 'collections',
    'itertools', 'functools', 'operator', 'types', 'builtins', '__future__',
    'warnings', 'traceback', 'linecache', 'inspect', 'ast', 'tokenize',
    'token', 'keyword', 'codeop', 'code', 'dis', 'opcode', 'symtable',
    'tabnanny', 'pyclbr', 'filecmp', 'difflib',
    
    # Packaging and dependencies
    'packaging', 'pyparsing', 'six', 'appdirs', 'distlib', 'filelock',
    'platformdirs', 'tomli', 'tomllib', 'typing_extensions', 'zipp',
    'importlib_metadata', 'importlib_resources', 'pathlib2', 'scandir',
    'contextlib2', 'configparser', 'configparser2',
    
    # Backports
    'backports', 'backports.entry_points_selectable', 'backports.functools_lru_cache',
    'backports.shutil_get_terminal_size', 'backports.shutil_which',
    'backports.statistics', 'backports.weakref', 'backports.zoneinfo',
]

a = Analysis(
    ['src/capgenie/cli.py'],
    pathex=[],
    binaries=[],
    datas=capgenie_data,
    hiddenimports=[
        'inquirer',
        'readchar',
        'capgenie.denoise',
        'capgenie.fuzzy_match', 
        'capgenie.mani',
        'capgenie.filter_module',
        'capgenie',
    ] + capgenie_modules,
    hookspath=[],
    hooksconfig={},
    runtime_hooks=['runtime-hook-readchar.py'],
    excludes=excluded_modules,
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=None,
    noarchive=False,
)

# Windows-specific DLL handling
if is_windows:
    # Ensure Python DLL is included
    python_dll_name = f'python{sys.version_info.major}{sys.version_info.minor}.dll'
    
    # Add Python DLL to binaries if it exists
    python_dll_path = None
    for path in sys.path:
        potential_dll = os.path.join(path, python_dll_name)
        if os.path.exists(potential_dll):
            python_dll_path = potential_dll
            break
    
    if python_dll_path:
        a.binaries.append((python_dll_name, python_dll_path, 'BINARY'))
        print(f"Added Python DLL: {python_dll_path}")
    else:
        print(f"Warning: Could not find Python DLL: {python_dll_name}")

pyz = PYZ(a.pure, a.zipped_data, cipher=None)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name='cli',
    debug=False,
    bootloader_ignore_signals=False,
    strip=True,  # Enable stripping for smaller size
    upx=True,    # Enable UPX compression
    console=True,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)

coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=True,  # Enable stripping for all binaries
    upx=True,    # Enable UPX compression for all binaries
    upx_exclude=[],
    name='cli',
) 