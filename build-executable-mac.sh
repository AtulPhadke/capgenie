#!/bin/bash
set -e

echo "🔧 Building CapGenie executable for macOS..."

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
DIST_DIR="$SCRIPT_DIR/dist"
SPEC_FILE="$SCRIPT_DIR/capgenie.spec"

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

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is designed for macOS. Use build-executable-windows.bat for Windows."
    exit 1
fi

# Check if we're in the correct directory
if [ ! -f "pyproject.toml" ]; then
    print_error "pyproject.toml not found. Please run this script from the cap_genie_dist directory."
    exit 1
fi

# Clean previous builds
print_status "Cleaning previous builds..."
rm -rf "$BUILD_DIR" "$DIST_DIR" "$SPEC_FILE"

# Install PyInstaller if not already installed
print_status "Installing PyInstaller..."
pip install pyinstaller

# Install the package in development mode
print_status "Installing CapGenie in development mode..."
pip install -e .

# Create PyInstaller spec file
print_status "Creating PyInstaller spec file..."
cat > "$SPEC_FILE" << 'EOF'
# -*- mode: python ; coding: utf-8 -*-
from PyInstaller.utils.hooks import collect_data_files

block_cipher = None

a = Analysis(
    ['src/capgenie/cli.py'],
    pathex=[],
    binaries=[],
    datas=[
        ('src/capgenie', 'capgenie'),
        ('assets', 'assets'),
    ] + collect_data_files('inquirer') + collect_data_files('readchar', include_py_files=True) + collect_data_files('Bio') + collect_data_files('sklearn') + collect_data_files('umap') + collect_data_files('pyahocorasick') + collect_data_files('logomaker'),
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
        'Bio',
        'Bio.Seq',
        'ahocorasick',
        'sklearn',
        'sklearn.cluster',
        'umap',
        'umap.umap_',
        'logomaker',
        'inquirer',
        'inquirer.themes',
        'inquirer.questions',
        'inquirer.render',
        'inquirer.render.console',
        'inquirer.render.console._list',
        'inquirer.render.console._text',
        'inquirer.render.console._checkbox',
        'inquirer.render.console._confirm',
        'inquirer.render.console._password',
        'inquirer.render.console._path',
        'inquirer.render.console._editor',
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
EOF

# Build the executable
print_status "Building executable with PyInstaller..."
pyinstaller --clean "$SPEC_FILE"

# Test the executable
print_status "Testing the executable..."
if [ -f "$DIST_DIR/capgenie" ]; then
    echo "Testing executable with --help..."
    "$DIST_DIR/capgenie" --help
    EXIT_CODE=$?
    echo "Exit code: $EXIT_CODE"
    
    if [ $EXIT_CODE -eq 0 ] || [ $EXIT_CODE -eq 1 ]; then
        print_success "Executable built and tested successfully!"
    else
        print_error "Executable test failed with exit code $EXIT_CODE"
        exit 1
    fi
else
    print_error "Executable not found in dist directory"
    exit 1
fi

# Calculate final size
FINAL_SIZE=$(du -sh "$DIST_DIR/capgenie" | cut -f1)
print_success "Executable created successfully!"
print_status "Final size: $FINAL_SIZE"
print_status "Location: $DIST_DIR/capgenie"

# Create a simple launcher script for easier integration
print_status "Creating launcher script..."
cat > "$DIST_DIR/capgenie.sh" << 'EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/capgenie" "$@"
EOF
chmod +x "$DIST_DIR/capgenie.sh"

print_success "🎉 CapGenie executable for macOS is ready!"
print_status "You can now use this executable in your Electron application."
print_status "The executable is self-contained and includes all dependencies." 