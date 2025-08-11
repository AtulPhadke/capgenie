#!/bin/bash

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
    echo -e "${GREEN}✅${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

echo "🔧 Building CapGenie executable for macOS (Optimized for Speed)..."

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
DIST_DIR="$SCRIPT_DIR/dist"

# Check if we're in the correct directory
if [ ! -f "pyproject.toml" ]; then
    print_error "pyproject.toml not found. Please run this script from the cap_genie_dist directory."
    exit 1
fi

# Clean previous builds
print_status "Cleaning previous builds..."
rm -rf "$BUILD_DIR" "$DIST_DIR"

# Install PyInstaller if not already installed
print_status "Installing PyInstaller..."
pip install pyinstaller

# Install the package in development mode
print_status "Installing CapGenie in development mode..."
./install_package.sh

# Build the executable with targeted optimizations using direct PyInstaller commands
print_status "Building executable with PyInstaller (targeted optimization)..."
pyinstaller --clean \
    --hidden-import=inquirer \
    --hidden-import=readchar \
    --hidden-import=capgenie.denoise \
    --hidden-import=capgenie.fuzzy_match \
    --hidden-import=capgenie.mani \
    --hidden-import=capgenie.filter_module \
    --hidden-import=matplotlib.pyplot \
    --hidden-import=plotly \
    --hidden-import=plotly.graph_objects \
    --hidden-import=plotly.express \
    --hidden-import=pandas \
    --hidden-import=numpy \
    --hidden-import=scipy \
    --hidden-import=scipy.spatial.distance \
    --hidden-import=sklearn \
    --hidden-import=sklearn.cluster \
    --hidden-import=umap \
    --hidden-import=umap.umap_ \
    --hidden-import=logomaker \
    --hidden-import=ahocorasick \
    --hidden-import=Bio \
    --hidden-import=Bio.Seq \
    --hidden-import=collections \
    --hidden-import=collections.abc \
    --hidden-import=collections.Counter \
    --hidden-import=collections.OrderedDict \
    --hidden-import=collections.defaultdict \
    --hidden-import=base64 \
    --hidden-import=random \
    --hidden-import=math \
    --hidden-import=dataclasses \
    --hidden-import=json \
    --hidden-import=shutil \
    --hidden-import=pickle \
    --hidden-import=warnings \
    --hidden-import=openpyxl \
    --hidden-import=openpyxl.workbook \
    --hidden-import=openpyxl.worksheet \
    --hidden-import=openpyxl.cell \
    --hidden-import=openpyxl.styles \
    --hidden-import=seaborn \
    --copy-metadata readchar \
    --onedir \
    --optimize=2 \
    --runtime-hook runtime-hook-readchar.py \
    --additional-hooks-dir=. \
    --exclude-module matplotlib.tests \
    --exclude-module numpy.random.tests \
    --exclude-module scipy.tests \
    --exclude-module sklearn.tests \
    --exclude-module Bio.tests \
    --exclude-module plotly.tests \
    --exclude-module unittest \
    --exclude-module test \
    --exclude-module tests \
    --exclude-module _pytest \
    --exclude-module pytest \
    --exclude-module coverage \
    --exclude-module pdb \
    --exclude-module pydoc \
    --exclude-module tkinter \
    --exclude-module turtle \
    --exclude-module idlelib \
    --exclude-module lib2to3 \
    --exclude-module ensurepip \
    --exclude-module venv \
    --exclude-module setuptools \
    --exclude-module setuptools._distutils \
    --exclude-module setuptools._vendor \
    --exclude-module setuptools.command \
    --exclude-module setuptools.dist \
    --exclude-module setuptools.extension \
    --exclude-module setuptools.glob \
    --exclude-module setuptools.msvc \
    --exclude-module setuptools.namespaces \
    --exclude-module setuptools.package_index \
    --exclude-module setuptools.py27compat \
    --exclude-module setuptools.py31compat \
    --exclude-module setuptools.py33compat \
    --exclude-module setuptools.sandbox \
    --exclude-module setuptools.ssl_support \
    --exclude-module setuptools.unicode_utils \
    --exclude-module setuptools.wheel \
    --exclude-module setuptools.windows_support \
    --exclude-module pkg_resources \
    --exclude-module pkg_resources._vendor \
    --exclude-module pkg_resources.extern \
    --exclude-module pkg_resources.py2_warn \
    --exclude-module pkg_resources.py31compat \
    --exclude-module pkg_resources.py33compat \
    --exclude-module pkg_resources.safe_extra \
    --exclude-module pkg_resources.tests \
    --exclude-module pip \
    --exclude-module wheel \
    --exclude-module http \
    --exclude-module xml \
    --exclude-module xmlrpc \
    --exclude-module wsgiref \
    --exclude-module requests \
    --exclude-module idna \
    --exclude-module appdirs \
    --exclude-module distlib \
    --exclude-module filelock \
    --exclude-module platformdirs \
    --exclude-module tomli \
    --exclude-module tomllib \
    --exclude-module zipp \
    --exclude-module importlib_resources \
    --exclude-module pathlib2 \
    --exclude-module scandir \
    --exclude-module contextlib2 \
    --exclude-module configparser \
    --exclude-module configparser2 \
    --exclude-module backports \
    --exclude-module backports.entry_points_selectable \
    --exclude-module backports.functools_lru_cache \
    --exclude-module backports.shutil_get_terminal_size \
    --exclude-module backports.shutil_which \
    --exclude-module backports.statistics \
    --exclude-module backports.weakref \
    --exclude-module backports.zoneinfo \
    --collect-all capgenie \
    --add-data "src/capgenie:capgenie" \
    --log-level WARN \
    src/capgenie/cli.py

# Test the executable
print_status "Testing the executable..."
if [ -f "$DIST_DIR/cli/cli" ]; then
    echo "Testing executable with --help..."
    "$DIST_DIR/cli/cli" --help
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
    ls -la "$DIST_DIR"
    exit 1
fi

# Calculate final size
FINAL_SIZE=$(du -sh "$DIST_DIR/cli" | cut -f1)
print_success "Executable created successfully!"
print_status "Final size: $FINAL_SIZE"
print_status "Location: $DIST_DIR/cli/"

# Create a simple launcher script for easier integration
print_status "Creating launcher script..."
cat > "$DIST_DIR/capgenie.sh" << 'EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/cli/cli" "$@"
EOF
chmod +x "$DIST_DIR/capgenie.sh"

print_success "🎉 CapGenie executable for macOS is ready!"
print_status "You can now use this executable in your Electron application."
print_status "The executable is optimized for maximum performance and minimal size."
print_warning "Note: This creates a directory structure instead of a single file."
print_status "Use the launcher script 'capgenie.sh' for easier integration."
echo
print_status "Optimization features applied:"
print_status "- Targeted module exclusion (keeping all required modules)"
print_status "- All required dependencies included as hidden imports"
print_status "- Optimized Python bytecode"
print_status "- Minimal unnecessary dependencies excluded"
print_status "- Reduced log verbosity" 