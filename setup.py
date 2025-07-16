from setuptools import setup, Extension, find_packages
from setuptools.command.build_ext import build_ext
import sysconfig

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

# Dynamically detect Python lib dir
python_libdir = sysconfig.get_config_var("LIBDIR")

# Define the extension modules
ext_modules = [
    Extension(
        "capgenie.filter_module",
        ["src/capgenie/filter_count.cpp"],
        include_dirs=[
            get_pybind_include(),
            get_pybind_include(user=True),
        ],
        extra_link_args=[f"-L{python_libdir}"],
        language="c++",
        extra_compile_args=["-std=c++11"],
    ),
    Extension(
        "capgenie.denoise",
        ["src/capgenie/denoise.cpp"],
        include_dirs=[
            get_pybind_include(),
            get_pybind_include(user=True),
        ],
        extra_link_args=[f"-L{python_libdir}"],
        language="c++",
        extra_compile_args=["-std=c++11"],
    ),
    Extension(
        "capgenie.mani",
        ["src/capgenie/mani.cpp"],
        include_dirs=[
            get_pybind_include(),
            get_pybind_include(user=True),
        ],
        extra_link_args=[f"-L{python_libdir}"],
        language="c++",
        extra_compile_args=["-std=c++17", "-mmacosx-version-min=10.15"],
    ),
    Extension(
        "capgenie.fuzzy_match",
        ["src/capgenie/fuzzy_match.cpp", "src/capgenie/edlib/edlib.cpp"],
        include_dirs=[
            get_pybind_include(),
            get_pybind_include(user=True),
            "src/capgenie/edlib",
        ],
        extra_link_args=[f"-L{python_libdir}"],
        language="c++",
        extra_compile_args=["-std=c++17"],
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
