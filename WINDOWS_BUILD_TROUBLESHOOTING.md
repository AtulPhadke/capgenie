# Windows Build Troubleshooting Guide

This guide addresses common issues when building CapGenie executables on Windows, particularly the "failed to load Python DLL" error.

## Common Issues and Solutions

### 1. "Failed to load Python DLL" Error

**Symptoms:**
- Executable fails to start with "failed to load Python DLL"
- "Invalid access to memory location" error
- Executable appears to hang or crash immediately

**Root Causes:**
1. **Platform mismatch**: C++ extensions compiled for wrong platform (e.g., macOS .so files on Windows)
2. **Missing Visual C++ Redistributable**: Required DLLs not present
3. **Python version mismatch**: Executable built with different Python version than runtime
4. **Architecture mismatch**: 32-bit vs 64-bit mismatch

**Solutions:**

#### A. Clean and Rebuild
```cmd
cd cap_genie_dist

REM Clean all existing builds and compiled extensions
rmdir /s /q build
rmdir /s /q dist
del /q src\capgenie\*.so
del /q src\capgenie\*.pyd

REM Reinstall with force rebuild
pip install -e . --force-reinstall --no-cache-dir

REM Build executable
build-executable-windows.bat
```

#### B. Install Visual C++ Redistributable
Download and install the latest Visual C++ Redistributable:
- [Microsoft Visual C++ Redistributable](https://aka.ms/vs/17/release/vc_redist.x64.exe)

#### C. Verify Python Environment
```cmd
REM Check Python version and architecture
python --version
python -c "import platform; print(platform.architecture())"

REM Ensure you're using the same Python for build and runtime
where python
```

### 2. C++ Extension Compilation Failures

**Symptoms:**
- Build fails during C++ extension compilation
- "cl.exe not found" error
- Compilation errors in .cpp files

**Solutions:**

#### A. Install Visual Studio Build Tools
```cmd
REM Install Visual Studio Build Tools (if not already installed)
REM Download from: https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022

REM Or use winget
winget install Microsoft.VisualStudio.2022.BuildTools
```

#### B. Set Up Build Environment
```cmd
REM Open Developer Command Prompt for VS 2022
REM Or set environment variables manually:
set VS2022INSTALLDIR=C:\Program Files\Microsoft Visual Studio\2022\Community
set PATH=%VS2022INSTALLDIR%\VC\Tools\MSVC\14.xx.xxxxx\bin\Hostx64\x64;%PATH%
```

#### C. Alternative: Use MinGW
```cmd
REM Install MinGW-w64
winget install MSYS2.MSYS2

REM Add MinGW to PATH
set PATH=C:\msys64\mingw64\bin;%PATH%

REM Set compiler environment variable
set CC=gcc
set CXX=g++
```

### 3. PyInstaller Issues

**Symptoms:**
- PyInstaller fails to find modules
- Missing dependencies in executable
- Large executable size

**Solutions:**

#### A. Update PyInstaller Configuration
```cmd
REM Use the updated build script with proper hidden imports
build-executable-windows.bat
```

#### B. Manual PyInstaller Command
```cmd
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
    --add-data "src\capgenie\*.pyd;capgenie" ^
    src\capgenie\cli.py
```

#### C. Create Spec File for Better Control
```cmd
pyi-makespec src\capgenie\cli.py --onedir --name capgenie
REM Edit capgenie.spec to add hidden imports and data files
pyinstaller capgenie.spec
```

### 4. Dependency Issues

**Symptoms:**
- Missing module errors
- Import errors in executable
- Runtime errors related to dependencies

**Solutions:**

#### A. Verify All Dependencies
```cmd
REM Check installed packages
pip list

REM Install missing dependencies
pip install -r requirements.txt

REM Install development dependencies
pip install pybind11 setuptools wheel
```

#### B. Update Requirements
Ensure `requirements.txt` includes all necessary packages:
```
pyahocorasick>=2.0.0
biopython>=1.79
plotly>=5.0.0
pandas>=1.5.0
pybind11>=2.10.0
inquirer>=2.7.0
matplotlib>=3.5.0
scikit-learn>=1.0.0
umap-learn>=0.5.0
logomaker>=0.8
scipy>=1.7.0
numpy>=1.21.0
```

### 5. Testing and Debugging

#### A. Test Executable
```cmd
REM Test basic functionality
dist\cli\cli.exe --help

REM Test with sample data
dist\cli\cli.exe --input sample.fastq --output results.csv
```

#### B. Debug with Verbose Output
```cmd
REM Run with verbose PyInstaller
pyinstaller --debug=all src\capgenie\cli.py

REM Check executable dependencies
dumpbin /dependents dist\cli\cli.exe
```

#### C. Check File Structure
```cmd
REM Verify all required files are present
dir dist\cli /s

REM Check for missing DLLs
dir dist\cli\*.dll
```

## Best Practices

### 1. Environment Setup
- Use a clean virtual environment
- Install dependencies in the correct order
- Use consistent Python versions

### 2. Build Process
- Always clean previous builds
- Verify platform-specific extensions
- Test executables on target systems

### 3. Distribution
- Include Visual C++ Redistributable
- Test on clean Windows systems
- Provide installation instructions

## Advanced Troubleshooting

### 1. Dependency Walker Analysis
Use Dependency Walker to analyze executable dependencies:
1. Download [Dependency Walker](http://www.dependencywalker.com/)
2. Open your executable
3. Look for missing DLLs (marked in red)
4. Install missing dependencies

### 2. Process Monitor
Use Process Monitor to track file access:
1. Download [Process Monitor](https://docs.microsoft.com/en-us/sysinternals/downloads/procmon)
2. Filter for your executable
3. Look for file access failures

### 3. Event Viewer
Check Windows Event Viewer for application errors:
1. Open Event Viewer
2. Navigate to Windows Logs > Application
3. Look for errors related to your executable

## Getting Help

If you continue to experience issues:

1. **Check the logs**: Look for detailed error messages
2. **Verify environment**: Ensure all prerequisites are met
3. **Test incrementally**: Build and test each component separately
4. **Use clean environment**: Test on a fresh Windows installation

## Common Error Messages

| Error Message | Likely Cause | Solution |
|---------------|--------------|----------|
| "Failed to load Python DLL" | Platform mismatch | Clean rebuild with correct platform |
| "cl.exe not found" | Missing Visual Studio | Install Build Tools |
| "ImportError: No module named X" | Missing dependency | Install missing package |
| "Access violation" | Architecture mismatch | Use consistent 32/64-bit |
| "Entry point not found" | DLL version mismatch | Update Visual C++ Redistributable | 