# capgenie Installation Guide

This guide provides platform-specific instructions for installing capgenie on Windows, macOS, and Linux.

## Prerequisites

### Python Requirements
- Python 3.8 or higher
- pip (Python package installer)

### Platform-Specific Requirements

#### Windows
- **Visual Studio Build Tools** (recommended) or **MinGW**
- **Git** (for cloning the repository)

**Install Visual Studio Build Tools:**
1. Download from: https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022
2. Install "C++ build tools" workload
3. Or use MinGW: Download from https://www.mingw-w64.org/

#### macOS
- **Xcode Command Line Tools**
- **Git** (usually pre-installed)

**Install Xcode Command Line Tools:**
```bash
xcode-select --install
```

#### Linux (Ubuntu/Debian)
- **Build essentials**
- **Git**

**Install build tools:**
```bash
sudo apt-get update
sudo apt-get install build-essential git
```

## Installation Steps

### 1. Clone the Repository
```bash
git clone <repository-url>
cd capgenie_dist
```

### 2. Run Platform Setup (Optional but Recommended)
```bash
python setup_platform.py
```

This script will:
- Check your Python version
- Verify C++ compiler availability
- Install required dependencies

### 3. Install capgenie
```bash
pip install -e .
```

## Troubleshooting

### Common Issues

#### Windows
**Error: "Microsoft Visual C++ 14.0 is required"**
- Install Visual Studio Build Tools with C++ workload
- Or install MinGW and add to PATH

**Error: "cl.exe not found"**
- Open "Developer Command Prompt for VS" or
- Add Visual Studio tools to your PATH

#### macOS
**Error: "clang: error: unsupported argument"**
- Update Xcode Command Line Tools: `xcode-select --install`

**Error: "fatal error: 'Python.h' file not found"**
- Install Python development headers: `brew install python`

#### Linux
**Error: "g++: command not found"**
- Install build essentials: `sudo apt-get install build-essential`

**Error: "Python.h: No such file or directory"**
- Install Python development headers: `sudo apt-get install python3-dev`

### Compilation Issues

If you encounter compilation errors:

1. **Check compiler version:**
   ```bash
   # Windows
   cl
   # macOS
   clang++ --version
   # Linux
   g++ --version
   ```

2. **Verify pybind11 installation:**
   ```bash
   pip install --upgrade pybind11
   ```

3. **Clean and rebuild:**
   ```bash
   pip uninstall capgenie
   pip install -e . --force-reinstall
   ```

## Verification

After installation, verify capgenie works:

```bash
capgenie --help
```

## Development Installation

For development work:

```bash
# Install in editable mode with development dependencies
pip install -e .[dev]

# Run tests
python -m pytest tests/

# Build documentation
python setup.py build_sphinx
```

## Platform-Specific Notes

### Windows
- Use Visual Studio Build Tools for best compatibility
- MinGW may work but is less tested
- Consider using WSL2 for development

### macOS
- Xcode Command Line Tools are required
- Homebrew can help with dependencies
- ARM64 (Apple Silicon) is fully supported

### Linux
- Tested on Ubuntu 20.04+ and CentOS 7+
- GCC 7+ is recommended
- Consider using conda for dependency management

## Support

If you encounter issues:
1. Check this troubleshooting guide
2. Run `python setup_platform.py` for diagnostics
3. Check the GitHub issues page
4. Provide platform information when reporting bugs 