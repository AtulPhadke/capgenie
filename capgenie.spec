# -*- mode: python ; coding: utf-8 -*-

import os
import sys
from PyInstaller.utils.hooks import collect_data_files, collect_submodules

# Platform-specific settings
is_windows = sys.platform.startswith('win')

# Collect all capgenie modules
capgenie_modules = collect_submodules('capgenie')

# Collect data files
capgenie_data = collect_data_files('capgenie')

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
    excludes=[
        'matplotlib.tests',
        'numpy.random.tests', 
        'scipy.tests',
        'sklearn.tests',
        'Bio.tests',
        'plotly.tests',
    ],
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
    strip=False,
    upx=True,
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
    strip=False,
    upx=True,
    upx_exclude=[],
    name='cli',
) 