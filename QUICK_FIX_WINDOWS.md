# Quick Fix for Windows Executable "Failed to load Python DLL" Error

## The Problem
The Windows executable fails with "failed to load Python DLL" and "Invalid access to memory location" because:
- C++ extensions are compiled for the wrong platform (macOS .so files instead of Windows .pyd files)
- Missing Visual C++ Redistributable
- Platform mismatch in PyInstaller configuration

## Quick Solution (3 Steps)

### Step 1: Clean Everything
```cmd
cd cap_genie_dist
rmdir /s /q build
rmdir /s /q dist
del /q src\capgenie\*.so
del /q src\capgenie\*.pyd
```

### Step 2: Reinstall with Force Rebuild
```cmd
pip install -e . --force-reinstall --no-cache-dir
```

### Step 3: Build Executable
```cmd
build-executable-windows.bat
```

## If That Doesn't Work

### Install Visual C++ Redistributable
Download and install: https://aka.ms/vs/17/release/vc_redist.x64.exe

### Install Visual Studio Build Tools
```cmd
winget install Microsoft.VisualStudio.2022.BuildTools
```

### Run Diagnostic
```cmd
python test_windows_build.py
```

## Expected Results
After successful build, you should see:
- `dist/cli/cli.exe` - The main executable
- `dist/capgenie.bat` - Launcher script
- Windows .pyd files in `src/capgenie/` (not .so files)

## Test the Executable
```cmd
dist\cli\cli.exe --help
```

## Still Having Issues?
See the detailed troubleshooting guide: `WINDOWS_BUILD_TROUBLESHOOTING.md` 