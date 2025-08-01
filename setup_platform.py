#!/usr/bin/env python3
"""
Platform-specific setup script for CapGenie
Handles compilation flags and dependencies for different platforms
"""

import os
import sys
import platform
import subprocess
from setuptools import setup, Extension, find_packages
from setuptools.command.build_ext import build_ext
import sysconfig

class get_pybind_include(object):
    """Helper class to determine the pybind11 include path"""
    def __init__(self, user=False):
        self.user = user

    def __str__(self):
        import pybind11
        return pybind11.get_include(self.user)

class CustomBuildExt(build_ext):
    """Custom build command to handle platform-specific compilation"""
    
    def build_extension(self, ext):
        system = platform.system()
        
        if system == "Windows":
            # Windows-specific compiler setup
            self._setup_windows_compiler()
        elif system == "Darwin":
            # macOS-specific compiler setup
            self._setup_macos_compiler()
        else:
            # Linux and other Unix-like systems
            self._setup_linux_compiler()
        
        super().build_extension(ext)
    
    def _setup_windows_compiler(self):
        """Setup Windows-specific compiler options"""
        # Ensure we're using the right compiler on Windows
        if not hasattr(self.compiler, 'compiler_so'):
            self.compiler.compiler_so = ['cl.exe']
        if not hasattr(self.compiler, 'compiler_cxx'):
            self.compiler.compiler_cxx = ['cl.exe']
        
        # Set Windows-specific environment variables
        os.environ['PYTHON_LIB'] = sysconfig.get_config_var("LIBDIR")
        os.environ['PYTHON_INCLUDE'] = sysconfig.get_config_var("INCLUDEDIR")
    
    def _setup_macos_compiler(self):
        """Setup macOS-specific compiler options"""
        # Set macOS-specific environment variables
        os.environ['MACOSX_DEPLOYMENT_TARGET'] = '10.15'
    
    def _setup_linux_compiler(self):
        """Setup Linux-specific compiler options"""
        # Linux-specific setup if needed
        pass

def get_platform_flags():
    """Get platform-specific compilation and linking flags"""
    system = platform.system()
    python_libdir = sysconfig.get_config_var("LIBDIR")
    python_include = sysconfig.get_config_var("INCLUDEDIR")
    
    print(f"Detected platform: {system}")
    print(f"Python libdir: {python_libdir}")
    print(f"Python include: {python_include}")
    
    if system == "Darwin":  # macOS
        compile_args = [
            "-std=c++17", 
            "-mmacosx-version-min=10.15",
            "-O3",
            "-DNDEBUG"
        ]
        link_args = []
        if python_libdir:
            link_args.append(f"-L{python_libdir}")
        print(f"macOS flags: compile={compile_args}, link={link_args}")
        
    elif system == "Windows":  # Windows
        # Windows-specific compilation flags
        compile_args = [
            "/std:c++17", 
            "/EHsc", 
            "/MD", 
            "/D_CRT_SECURE_NO_WARNINGS",
            "/O2",
            "/DNDEBUG"
        ]
        link_args = []
        if python_libdir:
            link_args.append(f"/LIBPATH:{python_libdir}")
        print(f"Windows flags: compile={compile_args}, link={link_args}")
        
    else:  # Linux and other Unix-like systems
        compile_args = [
            "-std=c++17",
            "-O3",
            "-DNDEBUG"
        ]
        link_args = []
        if python_libdir:
            link_args.append(f"-L{python_libdir}")
        print(f"Linux flags: compile={compile_args}, link={link_args}")
    
    return compile_args, link_args

def check_dependencies():
    """Check if required dependencies are available"""
    required_packages = ['pybind11', 'numpy']
    missing_packages = []
    
    for package in required_packages:
        try:
            __import__(package)
            print(f"✓ {package} found")
        except ImportError:
            missing_packages.append(package)
            print(f"✗ {package} not found")
    
    if missing_packages:
        print(f"\nMissing required packages: {missing_packages}")
        print("Please install them with: pip install " + " ".join(missing_packages))
        return False
    
    return True

def main():
    """Main setup function"""
    print("CapGenie Platform-Specific Setup")
    print("=" * 40)
    
    # Check dependencies
    if not check_dependencies():
        sys.exit(1)
    
    # Get platform-specific flags
    compile_args, link_args = get_platform_flags()
    
    # Define the extension modules
    ext_modules = [
        Extension(
            "capgenie.filter_module",
            ["src/capgenie/filter_count.cpp"],
            include_dirs=[
                str(get_pybind_include()),
                str(get_pybind_include(user=True)),
                "src/capgenie",
            ],
            extra_link_args=link_args,
            language="c++",
            extra_compile_args=compile_args,
        ),
        Extension(
            "capgenie.denoise",
            ["src/capgenie/denoise.cpp"],
            include_dirs=[
                str(get_pybind_include()),
                str(get_pybind_include(user=True)),
                "src/capgenie",
            ],
            extra_link_args=link_args,
            language="c++",
            extra_compile_args=compile_args,
        ),
        Extension(
            "capgenie.mani",
            ["src/capgenie/mani.cpp"],
            include_dirs=[
                str(get_pybind_include()),
                str(get_pybind_include(user=True)),
                "src/capgenie",
            ],
            extra_link_args=link_args,
            language="c++",
            extra_compile_args=compile_args,
        ),
        Extension(
            "capgenie.fuzzy_match",
            ["src/capgenie/fuzzy_match.cpp", "src/capgenie/edlib/edlib.cpp"],
            include_dirs=[
                str(get_pybind_include()),
                str(get_pybind_include(user=True)),
                "src/capgenie/edlib",
            ],
            extra_link_args=link_args,
            language="c++",
            extra_compile_args=compile_args,
        ),
    ]
    
    # Run setup
    setup(
        name="capgenie",
        version="0.1",
        ext_modules=ext_modules,
        cmdclass={"build_ext": CustomBuildExt},
        package_dir={"": "src"},
        packages=find_packages(where="src"),
    )

if __name__ == "__main__":
    main() 