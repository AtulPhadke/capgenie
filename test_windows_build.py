#!/usr/bin/env python3
"""
Windows Build Diagnostic Script
Helps identify issues with CapGenie Windows executable builds
"""

import os
import sys
import platform
import subprocess
import importlib
from pathlib import Path

def print_header(title):
    """Print a formatted header"""
    print("\n" + "=" * 60)
    print(f" {title}")
    print("=" * 60)

def check_python_environment():
    """Check Python environment details"""
    print_header("Python Environment")
    
    print(f"Python Version: {sys.version}")
    print(f"Platform: {platform.platform()}")
    print(f"Architecture: {platform.architecture()}")
    print(f"Executable: {sys.executable}")
    print(f"Python Path: {sys.path[0]}")
    
    # Check if running in virtual environment
    if hasattr(sys, 'real_prefix') or (hasattr(sys, 'base_prefix') and sys.base_prefix != sys.prefix):
        print("✓ Running in virtual environment")
    else:
        print("⚠ Not running in virtual environment")

def check_compiler():
    """Check for available C++ compilers"""
    print_header("C++ Compiler Check")
    
    compilers = {
        'cl.exe': 'Visual Studio',
        'g++.exe': 'MinGW/GCC',
        'clang++.exe': 'Clang'
    }
    
    found_compilers = []
    
    for compiler, name in compilers.items():
        try:
            result = subprocess.run([compiler, '/?'] if compiler == 'cl.exe' else [compiler, '--version'], 
                                  capture_output=True, text=True, timeout=5)
            if result.returncode == 0 or 'Microsoft' in result.stderr:
                print(f"✓ {name} ({compiler}) found")
                found_compilers.append(name)
            else:
                print(f"✗ {name} ({compiler}) not found")
        except (subprocess.TimeoutExpired, FileNotFoundError):
            print(f"✗ {name} ({compiler}) not found")
    
    if not found_compilers:
        print("\n⚠ No C++ compilers found!")
        print("   Install Visual Studio Build Tools or MinGW")
    else:
        print(f"\n✓ Found {len(found_compilers)} compiler(s): {', '.join(found_compilers)}")

def check_dependencies():
    """Check required Python dependencies"""
    print_header("Python Dependencies")
    
    required_packages = [
        'pybind11',
        'numpy',
        'pandas',
        'scipy',
        'matplotlib',
        'sklearn',
        'plotly',
        'biopython',
        'pyahocorasick',
        'inquirer',
        'readchar',
        'umap',
        'logomaker'
    ]
    
    missing_packages = []
    
    for package in required_packages:
        try:
            importlib.import_module(package)
            print(f"✓ {package}")
        except ImportError:
            print(f"✗ {package}")
            missing_packages.append(package)
    
    if missing_packages:
        print(f"\n⚠ Missing packages: {', '.join(missing_packages)}")
        print("   Install with: pip install " + " ".join(missing_packages))
    else:
        print("\n✓ All required packages are installed")

def check_extensions():
    """Check for compiled C++ extensions"""
    print_header("C++ Extensions")
    
    src_dir = Path("src/capgenie")
    if not src_dir.exists():
        print("✗ src/capgenie directory not found")
        return
    
    extensions = [
        'filter_module',
        'denoise', 
        'mani',
        'fuzzy_match'
    ]
    
    for ext in extensions:
        # Check for compiled files
        so_files = list(src_dir.glob(f"{ext}*.so"))
        pyd_files = list(src_dir.glob(f"{ext}*.pyd"))
        
        if so_files:
            print(f"✓ {ext}: {len(so_files)} .so file(s) found")
            for f in so_files:
                print(f"  - {f.name}")
        elif pyd_files:
            print(f"✓ {ext}: {len(pyd_files)} .pyd file(s) found")
            for f in pyd_files:
                print(f"  - {f.name}")
        else:
            print(f"✗ {ext}: No compiled extension found")
        
        # Try to import
        try:
            module = importlib.import_module(f"capgenie.{ext}")
            print(f"  ✓ Import successful")
        except ImportError as e:
            print(f"  ✗ Import failed: {e}")

def check_build_artifacts():
    """Check for build artifacts"""
    print_header("Build Artifacts")
    
    build_dir = Path("build")
    dist_dir = Path("dist")
    
    if build_dir.exists():
        print(f"✓ Build directory exists: {build_dir}")
        build_contents = list(build_dir.glob("*"))
        print(f"  Contents: {len(build_contents)} items")
        for item in build_contents[:5]:  # Show first 5 items
            print(f"  - {item.name}")
        if len(build_contents) > 5:
            print(f"  ... and {len(build_contents) - 5} more")
    else:
        print("✗ Build directory not found")
    
    if dist_dir.exists():
        print(f"✓ Dist directory exists: {dist_dir}")
        dist_contents = list(dist_dir.glob("*"))
        print(f"  Contents: {len(dist_contents)} items")
        for item in dist_contents:
            print(f"  - {item.name}")
            
        # Check for executable
        exe_files = list(dist_dir.glob("**/*.exe"))
        if exe_files:
            print(f"✓ Found {len(exe_files)} executable(s):")
            for exe in exe_files:
                print(f"  - {exe}")
        else:
            print("✗ No executables found in dist directory")
    else:
        print("✗ Dist directory not found")

def check_system_requirements():
    """Check system requirements"""
    print_header("System Requirements")
    
    # Check Windows version
    if platform.system() == "Windows":
        print(f"✓ Windows detected: {platform.release()}")
        
        # Check for Visual C++ Redistributable
        vcredist_paths = [
            r"C:\Windows\System32\msvcp140.dll",
            r"C:\Windows\SysWOW64\msvcp140.dll"
        ]
        
        for path in vcredist_paths:
            if os.path.exists(path):
                print(f"✓ Visual C++ Redistributable found: {path}")
                break
        else:
            print("⚠ Visual C++ Redistributable not found")
            print("   Download from: https://aka.ms/vs/17/release/vc_redist.x64.exe")
    else:
        print(f"⚠ Not running on Windows: {platform.system()}")

def run_diagnostic():
    """Run all diagnostic checks"""
    print("CapGenie Windows Build Diagnostic")
    print("This script helps identify issues with Windows executable builds")
    
    check_python_environment()
    check_compiler()
    check_dependencies()
    check_extensions()
    check_build_artifacts()
    check_system_requirements()
    
    print_header("Recommendations")
    
    print("If you're experiencing 'Failed to load Python DLL' errors:")
    print("1. Clean all existing builds: rmdir /s /q build dist")
    print("2. Remove compiled extensions: del /q src\\capgenie\\*.so src\\capgenie\\*.pyd")
    print("3. Reinstall package: pip install -e . --force-reinstall")
    print("4. Rebuild executable: build-executable-windows.bat")
    print("5. Install Visual C++ Redistributable if not already installed")
    
    print("\nFor more detailed troubleshooting, see WINDOWS_BUILD_TROUBLESHOOTING.md")

if __name__ == "__main__":
    run_diagnostic() 