from setuptools import setup, Extension, find_packages
from setuptools.command.build_ext import build_ext
import sysconfig
import platform
import os

class get_pybind_include(object):
    """Helper class to determine the pybind11 include path, based on the python version"""
    def __init__(self, user=False):
        self.user = user

    def __str__(self):
        import pybind11
        return pybind11.get_include(self.user)

def l_requirements(filename):
    with open(filename) as f:
        return [line.strip() for line in f if line.strip() and not line.startswith("#")]

def get_platform_flags():
    """Get platform-specific compilation and linking flags"""
    system = platform.system()
    python_libdir = sysconfig.get_config_var("LIBDIR")
    
    print(f"Detected platform: {system}")
    
    if system == "Darwin":  # macOS
        compile_args = ["-std=c++17", "-mmacosx-version-min=10.15"]
        link_args = [f"-L{python_libdir}"] if python_libdir else []
        print(f"macOS flags: compile={compile_args}, link={link_args}")
    elif system == "Windows":  # Windows
        compile_args = ["/std:c++17"]
        link_args = [f"/LIBPATH:{python_libdir}"] if python_libdir else []
        print(f"Windows flags: compile={compile_args}, link={link_args}")
    else:  # Linux and other Unix-like systems
        compile_args = ["-std=c++17"]
        link_args = [f"-L{python_libdir}"] if python_libdir else []
        print(f"Linux flags: compile={compile_args}, link={link_args}")
    
    return compile_args, link_args

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

setup(
    name="capgenie",
    version="0.1",
    ext_modules=ext_modules,
    cmdclass={"build_ext": build_ext},
    package_dir={"": "src"},
    packages=find_packages(where="src"),
    install_requires=l_requirements("requirements.txt"),
    entry_points={
        'console_scripts': [
            'capgenie = capgenie.cli:main',
        ],
    },
)
