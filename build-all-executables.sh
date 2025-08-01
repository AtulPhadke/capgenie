#!/bin/bash
set -e

echo "🚀 Building CapGenie Executables for All Platforms"
echo "=================================================="

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
DIST_DIR="$SCRIPT_DIR/dist"
EXECUTABLES_DIR="$SCRIPT_DIR/executables"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the correct directory
if [ ! -f "pyproject.toml" ]; then
    print_error "pyproject.toml not found. Please run this script from the cap_genie_dist directory."
    exit 1
fi

# Create executables directory
mkdir -p "$EXECUTABLES_DIR"

# Detect platform and build accordingly
if [[ "$OSTYPE" == "darwin"* ]]; then
    print_status "Detected macOS platform"
    
    # Build for macOS
    print_status "Building macOS executable..."
    if [ -f "build-executable-mac.sh" ]; then
        chmod +x build-executable-mac.sh
        ./build-executable-mac.sh
        
        # Copy executable to executables directory
        if [ -f "dist/capgenie" ]; then
            cp "dist/capgenie" "$EXECUTABLES_DIR/capgenie-macos"
            cp "dist/capgenie.sh" "$EXECUTABLES_DIR/capgenie-macos.sh"
            print_success "macOS executable copied to executables directory"
        else
            print_error "macOS executable not found after build"
            exit 1
        fi
    else
        print_error "build-executable-mac.sh not found"
        exit 1
    fi
    
    # Build for Windows using cross-compilation (if possible)
    print_status "Attempting Windows cross-compilation..."
    if command -v wine &> /dev/null; then
        print_status "Wine detected, attempting Windows build..."
        # This would require additional setup for cross-compilation
        print_warning "Windows cross-compilation not implemented yet"
    else
        print_warning "Wine not found, skipping Windows build"
        print_status "Please run build-executable-windows.bat on a Windows machine"
    fi
    
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    print_status "Detected Windows platform"
    
    # Build for Windows
    print_status "Building Windows executable..."
    if [ -f "build-executable-windows.bat" ]; then
        ./build-executable-windows.bat
        
        # Copy executable to executables directory
        if [ -f "dist/capgenie.exe" ]; then
            cp "dist/capgenie.exe" "$EXECUTABLES_DIR/capgenie-windows.exe"
            cp "dist/capgenie.bat" "$EXECUTABLES_DIR/capgenie-windows.bat"
            print_success "Windows executable copied to executables directory"
        else
            print_error "Windows executable not found after build"
            exit 1
        fi
    else
        print_error "build-executable-windows.bat not found"
        exit 1
    fi
    
    # Build for macOS using cross-compilation (if possible)
    print_warning "macOS cross-compilation not available on Windows"
    print_status "Please run build-executable-mac.sh on a macOS machine"
    
else
    print_status "Detected Linux platform"
    
    # Build for Linux
    print_status "Building Linux executable..."
    if [ -f "build-executable-linux.sh" ]; then
        chmod +x build-executable-linux.sh
        ./build-executable-linux.sh
        
        # Copy executable to executables directory
        if [ -f "dist/capgenie" ]; then
            cp "dist/capgenie" "$EXECUTABLES_DIR/capgenie-linux"
            cp "dist/capgenie.sh" "$EXECUTABLES_DIR/capgenie-linux.sh"
            print_success "Linux executable copied to executables directory"
        else
            print_error "Linux executable not found after build"
            exit 1
        fi
    else
        print_warning "build-executable-linux.sh not found, creating it..."
        
        # Create Linux build script
        cat > "build-executable-linux.sh" << 'EOF'
#!/bin/bash
set -e

echo "🔧 Building CapGenie executable for Linux..."

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
DIST_DIR="$SCRIPT_DIR/dist"
SPEC_FILE="$SCRIPT_DIR/capgenie.spec"

# Clean previous builds
rm -rf "$BUILD_DIR" "$DIST_DIR" "$SPEC_FILE"

# Install PyInstaller if not already installed
pip install pyinstaller

# Install the package in development mode
pip install -e .

# Create PyInstaller spec file
cat > "$SPEC_FILE" << 'SPEC_EOF'
# -*- mode: python ; coding: utf-8 -*-

block_cipher = None

a = Analysis(
    ['src/capgenie/cli.py'],
    pathex=[],
    binaries=[],
    datas=[
        ('src/capgenie', 'capgenie'),
        ('assets', 'assets'),
    ],
    hiddenimports=[
        'capgenie.bubble',
        'capgenie.biodistribution',
        'capgenie.motif',
        'capgenie.search_aav9',
        'capgenie.enrichment',
        'capgenie.spreadsheet',
        'capgenie.mani',
        'capgenie.denoise',
        'capgenie.filter_module',
        'capgenie.fuzzy_match',
        'pandas',
        'numpy',
        'scipy',
        'matplotlib',
        'plotly',
        'biopython',
        'pyahocorasick',
        'scikit-learn',
        'umap-learn',
        'logomaker',
        'inquirer',
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name='capgenie',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=True,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)
SPEC_EOF

# Build the executable
pyinstaller --clean "$SPEC_FILE"

# Test the executable
if [ -f "$DIST_DIR/capgenie" ]; then
    "$DIST_DIR/capgenie" --help > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "✅ Executable built and tested successfully!"
    else
        echo "❌ Executable test failed"
        exit 1
    fi
else
    echo "❌ Executable not found in dist directory"
    exit 1
fi

# Create a simple launcher script
cat > "$DIST_DIR/capgenie.sh" << 'LAUNCHER_EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/capgenie" "$@"
LAUNCHER_EOF
chmod +x "$DIST_DIR/capgenie.sh"

echo "🎉 CapGenie executable for Linux is ready!"
EOF
        
        chmod +x build-executable-linux.sh
        ./build-executable-linux.sh
        
        # Copy executable to executables directory
        if [ -f "dist/capgenie" ]; then
            cp "dist/capgenie" "$EXECUTABLES_DIR/capgenie-linux"
            cp "dist/capgenie.sh" "$EXECUTABLES_DIR/capgenie-linux.sh"
            print_success "Linux executable copied to executables directory"
        else
            print_error "Linux executable not found after build"
            exit 1
        fi
    fi
fi

# List all built executables
print_status "Built executables:"
ls -la "$EXECUTABLES_DIR/"

# Calculate sizes
print_status "Executable sizes:"
for exe in "$EXECUTABLES_DIR"/*; do
    if [ -f "$exe" ]; then
        size=$(du -sh "$exe" | cut -f1)
        echo "  - $(basename "$exe"): $size"
    fi
done

# Create a summary file
print_status "Creating build summary..."
cat > "$EXECUTABLES_DIR/build-summary.md" << EOF
# CapGenie Executables Build Summary

## Build Information
- **Build Date:** $(date -u)
- **Platform:** $(uname -s)
- **Architecture:** $(uname -m)

## Available Executables

$(ls -la "$EXECUTABLES_DIR" | grep -v "^total" | while read line; do
    echo "- $line"
done)

## Usage

### macOS
\`\`\`bash
./capgenie-macos --help
# or
./capgenie-macos.sh --help
\`\`\`

### Windows
\`\`\`cmd
capgenie-windows.exe --help
# or
capgenie-windows.bat --help
\`\`\`

### Linux
\`\`\`bash
./capgenie-linux --help
# or
./capgenie-linux.sh --help
\`\`\`

## Integration with Electron

Copy the appropriate executable to your Electron app's resources:

\`\`\`javascript
// In your Electron main process
const path = require('path');
const { app } = require('electron');

const executablePath = path.join(
  app.isPackaged ? process.resourcesPath : __dirname,
  'executables',
  process.platform === 'win32' ? 'capgenie-windows.exe' : 'capgenie-macos'
);
\`\`\`
EOF

print_success "🎉 All executables built successfully!"
print_status "Executables are available in: $EXECUTABLES_DIR"
print_status "Build summary: $EXECUTABLES_DIR/build-summary.md"
print_status ""
print_status "Next steps:"
print_status "1. Copy the appropriate executable to your Electron app"
print_status "2. Update your Electron app to call the executable directly"
print_status "3. Package the executable with your Electron app" 