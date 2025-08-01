# Runtime hook to fix readchar metadata issue and Python DLL loading in PyInstaller
import sys
import os

# Fix Python DLL loading issues on Windows
if sys.platform.startswith('win'):
    # Ensure Python DLL is properly loaded
    try:
        import ctypes
        # Get the Python DLL handle
        python_dll = ctypes.PyDLL(None)
    except Exception as e:
        print(f"Warning: Could not load Python DLL: {e}")
    
    # Set DLL search path to include the executable directory
    try:
        if hasattr(sys, '_MEIPASS'):
            # We're running from PyInstaller
            os.environ['PATH'] = sys._MEIPASS + os.pathsep + os.environ.get('PATH', '')
    except Exception as e:
        print(f"Warning: Could not set DLL search path: {e}")

# Add the readchar package to the path
try:
    import readchar
    readchar_path = os.path.dirname(readchar.__file__)
    if readchar_path not in sys.path:
        sys.path.insert(0, readchar_path)
except ImportError:
    pass

# Create a dummy metadata for readchar if it doesn't exist
try:
    import pkg_resources
    try:
        pkg_resources.get_distribution('readchar')
    except pkg_resources.DistributionNotFound:
        # Create a dummy distribution
        class DummyDistribution:
            def __init__(self):
                self.project_name = 'readchar'
                self.version = '1.0.0'
                self.location = os.path.dirname(__file__)
            
            def has_metadata(self, name):
                return False
            
            def get_metadata(self, name):
                return ''
        
        # Register the dummy distribution
        pkg_resources.working_set.add(DummyDistribution())
except ImportError:
    pass

# Ensure capgenie extensions are properly loaded
try:
    import capgenie.denoise
    import capgenie.fuzzy_match
    import capgenie.mani
    import capgenie.filter_module
except ImportError as e:
    print(f"Warning: Could not import capgenie extensions: {e}") 