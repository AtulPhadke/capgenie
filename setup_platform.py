#!/usr/bin/env python3
"""
Platform-specific setup script for capgenie
Handles cross-platform compilation issues and dependencies
"""

import os
import sys
import platform
import subprocess
from pathlib import Path

def check_compiler():
    """Check if a suitable C++ compiler is available"""
    system = platform.system()
    
    if system == "Windows":
        # Check for Visual Studio or MinGW
        try:
            subprocess.run(["cl"], capture_output=True, check=True)
            print("✓ Visual Studio compiler found")
            return True
        except (subprocess.CalledProcessError, FileNotFoundError):
            try:
                subprocess.run(["g++", "--version"], capture_output=True, check=True)
                print("✓ MinGW compiler found")
                return True
            except (subprocess.CalledProcessError, FileNotFoundError):
                print("✗ No suitable C++ compiler found on Windows")
                print("  Please install Visual Studio Build Tools or MinGW")
                return False
    
    elif system == "Darwin":  # macOS
        try:
            subprocess.run(["clang++", "--version"], capture_output=True, check=True)
            print("✓ Clang compiler found")
            return True
        except (subprocess.CalledProcessError, FileNotFoundError):
            print("✗ No C++ compiler found on macOS")
            print("  Please install Xcode Command Line Tools: xcode-select --install")
            return False
    
    else:  # Linux and other Unix-like systems
        try:
            subprocess.run(["g++", "--version"], capture_output=True, check=True)
            print("✓ GCC compiler found")
            return True
        except (subprocess.CalledProcessError, FileNotFoundError):
            print("✗ No C++ compiler found")
            print("  Please install GCC: sudo apt-get install build-essential (Ubuntu/Debian)")
            return False

def check_python_version():
    """Check if Python version is compatible"""
    version = sys.version_info
    if version < (3, 8):
        print(f"✗ Python {version.major}.{version.minor} is not supported")
        print("  Please use Python 3.8 or higher")
        return False
    
    print(f"✓ Python {version.major}.{version.minor}.{version.micro} is compatible")
    return True

def install_dependencies():
    """Install required dependencies"""
    print("Installing dependencies...")
    try:
        subprocess.run([sys.executable, "-m", "pip", "install", "-r", "requirements.txt"], check=True)
        print("✓ Dependencies installed successfully")
        return True
    except subprocess.CalledProcessError as e:
        print(f"✗ Failed to install dependencies: {e}")
        return False

def main():
    """Main setup function"""
    print("=== capgenie Platform Setup ===")
    print(f"Platform: {platform.system()} {platform.release()}")
    print(f"Architecture: {platform.machine()}")
    print()
    
    # Check Python version
    if not check_python_version():
        sys.exit(1)
    
    # Check compiler
    if not check_compiler():
        sys.exit(1)
    
    # Install dependencies
    if not install_dependencies():
        sys.exit(1)
    
    print("\n✓ Platform setup completed successfully!")
    print("You can now run: pip install -e .")

if __name__ == "__main__":
    main() 