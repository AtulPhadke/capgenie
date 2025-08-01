#!/bin/bash

# CapGenie Universal Build Script
# Builds executables for all supported platforms

set -e  # Exit on any error

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

# Function to detect platform
detect_platform() {
    case "$(uname -s)" in
        Darwin*)    echo "macos";;
        Linux*)     echo "linux";;
        CYGWIN*|MINGW*|MSYS*) echo "windows";;
        *)          echo "unknown";;
    esac
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check Python version
    python_version=$(python3 --version 2>&1 | cut -d' ' -f2)
    python_major=$(echo $python_version | cut -d'.' -f1)
    python_minor=$(echo $python_version | cut -d'.' -f2)
    
    if [ "$python_major" -lt 3 ] || ([ "$python_major" -eq 3 ] && [ "$python_minor" -lt 12 ]); then
        print_error "Python 3.12 or higher is required. Found: $python_version"
        exit 1
    fi
    
    print_success "Python version: $python_version"
    
    # Check pip
    if ! command -v pip3 &> /dev/null; then
        print_error "pip3 is not installed"
        exit 1
    fi
    
    print_success "pip3 found"
    
    # Check PyInstaller
    if ! python3 -c "import PyInstaller" 2>/dev/null; then
        print_warning "PyInstaller not found, installing..."
        pip3 install pyinstaller
    fi
    
    print_success "PyInstaller found"
}

# Function to clean build artifacts
clean_builds() {
    print_status "Cleaning previous builds..."
    
    # Remove build and dist directories
    rm -rf build/ dist/ 2>/dev/null || true
    
    # Remove compiled extensions (platform-specific)
    find src/capgenie -name "*.so" -delete 2>/dev/null || true
    find src/capgenie -name "*.pyd" -delete 2>/dev/null || true
    
    # Remove egg-info
    rm -rf src/*.egg-info/ 2>/dev/null || true
    
    print_success "Build artifacts cleaned"
}

# Function to install package
install_package() {
    print_status "Installing CapGenie package..."
    
    # Force reinstall to ensure clean compilation
    pip3 install -e . --force-reinstall --no-cache-dir
    
    print_success "Package installed successfully"
}

# Function to build macOS executable
build_macos() {
    print_status "Building macOS executable..."
    
    # Check for macOS-specific requirements
    if ! command -v clang++ &> /dev/null; then
        print_warning "clang++ not found, installing Xcode Command Line Tools..."
        xcode-select --install || {
            print_error "Failed to install Xcode Command Line Tools"
            print_error "Please install manually: xcode-select --install"
            exit 1
        }
    fi
    
    # Build executable
    pyinstaller --clean \
        --hidden-import=inquirer \
        --hidden-import=readchar \
        --hidden-import=capgenie.filter_module \
        --hidden-import=capgenie.denoise \
        --hidden-import=capgenie.mani \
        --hidden-import=capgenie.fuzzy_match \
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
    
    # Create launcher script
    cat > dist/capgenie.sh << 'EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/cli/cli" "$@"
EOF
    chmod +x dist/capgenie.sh
    
    print_success "macOS executable built successfully"
}

# Function to build Linux executable
build_linux() {
    print_status "Building Linux executable..."
    
    # Check for Linux-specific requirements
    if ! command -v g++ &> /dev/null; then
        print_warning "g++ not found, please install build-essential"
        print_error "Run: sudo apt-get install build-essential (Ubuntu/Debian)"
        exit 1
    fi
    
    # Build executable
    pyinstaller --clean \
        --hidden-import=inquirer \
        --hidden-import=readchar \
        --hidden-import=capgenie.filter_module \
        --hidden-import=capgenie.denoise \
        --hidden-import=capgenie.mani \
        --hidden-import=capgenie.fuzzy_match \
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
    
    # Create launcher script
    cat > dist/capgenie.sh << 'EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/cli/cli" "$@"
EOF
    chmod +x dist/capgenie.sh
    
    print_success "Linux executable built successfully"
}

# Function to build Windows executable
build_windows() {
    print_status "Building Windows executable..."
    
    # Check if we're on Windows or using WSL
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        # Native Windows
        print_status "Detected native Windows environment"
        
        # Check for Visual Studio Build Tools
        if ! command -v cl.exe &> /dev/null; then
            print_warning "Visual Studio Build Tools not found"
            print_error "Please install Visual Studio Build Tools"
            print_error "Download from: https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022"
            exit 1
        fi
        
        # Use the Windows batch script
        if [ -f "build-executable-windows.bat" ]; then
            cmd //c build-executable-windows.bat
        else
            print_error "build-executable-windows.bat not found"
            exit 1
        fi
        
    else
        # WSL or cross-compilation
        print_warning "Cross-compiling for Windows from non-Windows environment"
        print_warning "This may not work correctly. Consider building on Windows directly."
        
        # Try to build anyway
        pyinstaller --clean \
            --hidden-import=inquirer \
            --hidden-import=readchar \
            --hidden-import=capgenie.filter_module \
            --hidden-import=capgenie.denoise \
            --hidden-import=capgenie.mani \
            --hidden-import=capgenie.fuzzy_match \
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
    fi
    
    print_success "Windows executable built successfully"
}

# Function to test executable
test_executable() {
    local platform=$1
    print_status "Testing $platform executable..."
    
    case $platform in
        "macos"|"linux")
            if [ -f "dist/capgenie.sh" ]; then
                if ./dist/capgenie.sh --help &>/dev/null; then
                    print_success "$platform executable test passed"
                else
                    print_warning "$platform executable test failed (may need arguments)"
                fi
            else
                print_error "$platform executable not found"
            fi
            ;;
        "windows")
            if [ -f "dist/cli/cli.exe" ]; then
                if ./dist/cli/cli.exe --help &>/dev/null; then
                    print_success "$platform executable test passed"
                else
                    print_warning "$platform executable test failed (may need arguments)"
                fi
            else
                print_error "$platform executable not found"
            fi
            ;;
    esac
}

# Function to organize executables
organize_executables() {
    print_status "Organizing executables..."
    
    # Create executables directory
    mkdir -p executables
    
    # Copy platform-specific executables
    case $(detect_platform) in
        "macos")
            if [ -f "dist/capgenie.sh" ]; then
                cp dist/capgenie.sh executables/capgenie-macos.sh
                cp -r dist/cli executables/capgenie-macos
                print_success "macOS executable organized"
            fi
            ;;
        "linux")
            if [ -f "dist/capgenie.sh" ]; then
                cp dist/capgenie.sh executables/capgenie-linux.sh
                cp -r dist/cli executables/capgenie-linux
                print_success "Linux executable organized"
            fi
            ;;
        "windows")
            if [ -f "dist/cli/cli.exe" ]; then
                cp dist/cli/cli.exe executables/capgenie-windows.exe
                if [ -f "dist/capgenie.bat" ]; then
                    cp dist/capgenie.bat executables/capgenie-windows.bat
                fi
                print_success "Windows executable organized"
            fi
            ;;
    esac
}

# Function to generate build summary
generate_summary() {
    print_status "Generating build summary..."
    
    cat > executables/build-summary.md << EOF
# CapGenie Build Summary

**Build Date:** $(date)
**Platform:** $(detect_platform)
**Python Version:** $(python3 --version 2>&1)

## Executables Built

EOF
    
    # List built executables
    if [ -d "executables" ]; then
        for exe in executables/*; do
            if [ -f "$exe" ]; then
                size=$(du -h "$exe" | cut -f1)
                echo "- **$(basename "$exe")** ($size)" >> executables/build-summary.md
            fi
        done
    fi
    
    cat >> executables/build-summary.md << EOF

## Usage

### macOS/Linux
\`\`\`bash
./capgenie-macos.sh --help
./capgenie-linux.sh --help
\`\`\`

### Windows
\`\`\`cmd
capgenie-windows.exe --help
\`\`\`

## Troubleshooting

If you encounter issues:
1. Check the troubleshooting guide: WINDOWS_BUILD_TROUBLESHOOTING.md
2. Run the diagnostic script: python3 test_windows_build.py
3. Ensure all dependencies are installed
4. Verify platform-specific requirements

## File Structure

\`\`\`
executables/
├── capgenie-macos/          # macOS executable directory
├── capgenie-macos.sh        # macOS launcher script
├── capgenie-linux/          # Linux executable directory
├── capgenie-linux.sh        # Linux launcher script
├── capgenie-windows.exe     # Windows executable
├── capgenie-windows.bat     # Windows launcher script
└── build-summary.md         # This file
\`\`\`
EOF
    
    print_success "Build summary generated"
}

# Main function
main() {
    print_status "Starting CapGenie universal build..."
    
    # Check if we're in the right directory
    if [ ! -f "pyproject.toml" ]; then
        print_error "pyproject.toml not found. Please run this script from the cap_genie_dist directory."
        exit 1
    fi
    
    # Detect platform
    platform=$(detect_platform)
    print_status "Detected platform: $platform"
    
    # Check prerequisites
    check_prerequisites
    
    # Clean previous builds
    clean_builds
    
    # Install package
    install_package
    
    # Build for current platform
    case $platform in
        "macos")
            build_macos
            test_executable "macos"
            ;;
        "linux")
            build_linux
            test_executable "linux"
            ;;
        "windows")
            build_windows
            test_executable "windows"
            ;;
        *)
            print_error "Unsupported platform: $platform"
            exit 1
            ;;
    esac
    
    # Organize executables
    organize_executables
    
    # Generate summary
    generate_summary
    
    print_success "Build completed successfully!"
    print_status "Executables are available in the 'executables/' directory"
    print_status "See 'executables/build-summary.md' for details"
}

# Run main function
main "$@" 