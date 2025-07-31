# CapGenie Executable Build Guide

This guide explains how to build standalone executables for the CapGenie toolkit that can be used directly in your Electron application.

## Overview

Instead of embedding the entire Python environment, we create standalone executables using PyInstaller. This approach is:
- **More efficient**: Smaller file sizes
- **Easier to distribute**: Single executable files
- **Simpler integration**: Direct executable calls from Electron
- **Better performance**: No Python interpreter overhead

## Prerequisites

### For macOS:
- Python 3.12 or higher
- pip (comes with Python)
- PyInstaller (will be installed automatically)

### For Windows:
- Python 3.12 or higher
- pip (comes with Python)
- PyInstaller (will be installed automatically)

## Build Scripts

### 1. Platform-Specific Builds

**macOS:**
```bash
cd cap_genie_dist
chmod +x build-executable-mac.sh
./build-executable-mac.sh
```

**Windows:**
```cmd
cd cap_genie_dist
build-executable-windows.bat
```

**Linux:**
```bash
cd cap_genie_dist
chmod +x build-executable-linux.sh
./build-executable-linux.sh
```

### 2. Universal Build Script

**For any platform:**
```bash
cd cap_genie_dist
chmod +x build-all-executables.sh
./build-all-executables.sh
```

This script will:
- Detect your platform
- Build the appropriate executable
- Create an `executables/` directory with all built files
- Generate a build summary

## Build Output

After a successful build, you'll find:

### Directory Structure
```
cap_genie_dist/
├── dist/
│   ├── capgenie          # macOS/Linux executable
│   ├── capgenie.exe      # Windows executable
│   ├── capgenie.sh       # macOS/Linux launcher script
│   └── capgenie.bat      # Windows launcher script
└── executables/          # Organized executables
    ├── capgenie-macos    # macOS executable
    ├── capgenie-macos.sh # macOS launcher
    ├── capgenie-windows.exe # Windows executable
    ├── capgenie-windows.bat # Windows launcher
    └── build-summary.md  # Build information
```

### File Sizes

Typical executable sizes:
- **macOS:** ~50-100 MB
- **Windows:** ~60-120 MB
- **Linux:** ~45-90 MB

The size includes:
- All Python dependencies
- CapGenie toolkit
- Required libraries (numpy, pandas, scipy, etc.)
- PyInstaller runtime

## Testing the Executables

### macOS/Linux:
```bash
./capgenie-macos --help
# or
./capgenie-macos.sh --help
```

### Windows:
```cmd
capgenie-windows.exe --help
# or
capgenie-windows.bat --help
```

## Integration with Electron

### 1. Copy Executables to Your Electron App

Create an `executables` directory in your Electron app:

```bash
# From your Electron app directory
mkdir -p resources/executables
cp ../cap_genie_dist/executables/capgenie-macos resources/executables/
cp ../cap_genie_dist/executables/capgenie-windows.exe resources/executables/
```

### 2. Update Your Electron Main Process

Replace the embedded Python calls with direct executable calls:

```javascript
// In your Electron main.js
const { spawn } = require('child_process');
const path = require('path');
const { app } = require('electron');

function getCapGenieExecutable() {
  const executableDir = path.join(
    app.isPackaged ? process.resourcesPath : __dirname,
    'resources',
    'executables'
  );
  
  if (process.platform === 'win32') {
    return path.join(executableDir, 'capgenie-windows.exe');
  } else {
    return path.join(executableDir, 'capgenie-macos');
  }
}

// Example usage
function runCapGenie(args) {
  const executable = getCapGenieExecutable();
  
  return new Promise((resolve, reject) => {
    const process = spawn(executable, args);
    
    let stdout = '';
    let stderr = '';
    
    process.stdout.on('data', (data) => {
      stdout += data.toString();
    });
    
    process.stderr.on('data', (data) => {
      stderr += data.toString();
    });
    
    process.on('close', (code) => {
      if (code === 0) {
        resolve(stdout);
      } else {
        reject(new Error(`CapGenie failed with code ${code}: ${stderr}`));
      }
    });
  });
}

// Usage example
ipcMain.handle('run-capgenie', async (event, args) => {
  try {
    const result = await runCapGenie(args);
    return { success: true, output: result };
  } catch (error) {
    return { success: false, error: error.message };
  }
});
```

### 3. Update package.json

Add the executables to your Electron build configuration:

```json
{
  "build": {
    "extraResources": [
      {
        "from": "resources/executables",
        "to": "executables",
        "filter": ["**/*"]
      }
    ]
  }
}
```

## Benefits of This Approach

### Compared to Embedded Python:
- **Smaller size**: ~50-100 MB vs ~200-300 MB
- **Faster startup**: No Python interpreter initialization
- **Simpler distribution**: Single executable files
- **Better compatibility**: No Python version conflicts
- **Easier debugging**: Direct executable calls

### Compared to System Python:
- **Self-contained**: No external dependencies
- **Consistent**: Same behavior across systems
- **Reliable**: No missing Python installations
- **Portable**: Works on any compatible system

## Troubleshooting

### Common Issues

1. **Executable not found:**
   - Check that the build completed successfully
   - Verify the executable path in your Electron app
   - Ensure the executable has proper permissions

2. **Permission denied:**
   ```bash
   chmod +x capgenie-macos
   ```

3. **Missing dependencies:**
   - Rebuild the executable with updated requirements
   - Check that all imports are included in the PyInstaller spec

4. **Large file size:**
   - The executable includes all dependencies
   - Consider using UPX compression (already enabled)
   - Remove unnecessary dependencies from requirements.txt

### Build Failures

1. **PyInstaller not found:**
   ```bash
   pip install pyinstaller
   ```

2. **Missing Python packages:**
   ```bash
   pip install -r requirements.txt
   pip install -e .
   ```

3. **Compilation errors:**
   - Check that all C++ extensions compile correctly
   - Ensure pybind11 is properly installed
   - Verify Python version compatibility

## Cross-Platform Building

For building executables for multiple platforms:

1. **macOS → Windows:** Use a Windows VM or CI/CD
2. **Windows → macOS:** Use a macOS VM or CI/CD
3. **Linux → All:** Use Docker containers for each platform

## CI/CD Integration

You can integrate these build scripts into your CI/CD pipeline:

```yaml
# Example GitHub Actions workflow
- name: Build CapGenie Executables
  run: |
    cd cap_genie_dist
    chmod +x build-all-executables.sh
    ./build-all-executables.sh

- name: Upload Executables
  uses: actions/upload-artifact@v4
  with:
    name: capgenie-executables
    path: cap_genie_dist/executables/
```

## Next Steps

1. **Build the executables** using the provided scripts
2. **Test the executables** to ensure they work correctly
3. **Integrate with Electron** by updating your main process
4. **Update your build process** to include the executables
5. **Test the complete application** end-to-end

This approach will give you a much cleaner and more efficient distribution of your CapGenie Electron application! 