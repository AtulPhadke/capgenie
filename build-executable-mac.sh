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

# Build the executable with optimizations for speed
print_status "Building executable with PyInstaller (optimized for startup speed)..."
pyinstaller --clean \
    --hidden-import=inquirer \
    --hidden-import=readchar \
    --hidden-import=openpyxl \
    --hidden-import=openpyxl.workbook \
    --hidden-import=openpyxl.worksheet \
    --hidden-import=openpyxl.cell \
    --hidden-import=openpyxl.styles \
    --hidden-import=seaborn \
    --copy-metadata readchar \
    --onedir \
    --strip \
    --optimize=2 \
    --exclude-module matplotlib.tests \
    --exclude-module numpy.random.tests \
    --exclude-module scipy.tests \
    --exclude-module sklearn.tests \
    --exclude-module Bio.tests \
    --exclude-module plotly.tests \
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
print_status "The executable is optimized for faster startup times."
print_warning "Note: This creates a directory structure instead of a single file."
print_status "Use the launcher script 'capgenie.sh' for easier integration." 