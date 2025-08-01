# Runtime hook to fix readchar metadata issue and Python DLL loading in PyInstaller
import sys
import os

# Fix Python DLL loading issues on Windows
if sys.platform.startswith('win'):
    # Set DLL search path to include the executable directory
    if hasattr(sys, '_MEIPASS'):
        # We're running from PyInstaller
        os.environ['PATH'] = sys._MEIPASS + os.pathsep + os.environ.get('PATH', '')
        
        # Try to ensure Python DLL is available
        try:
            import ctypes
            # This should work if Python DLL is in PATH
            ctypes.PyDLL(None)
        except Exception as e:
            print(f"Warning: Could not load Python DLL: {e}")
            # Try alternative approach - load from system
            try:
                import sys
                python_dll_name = f'python{sys.version_info.major}{sys.version_info.minor}.dll'
                ctypes.CDLL(python_dll_name)
                print(f"Loaded Python DLL: {python_dll_name}")
            except Exception as e2:
                print(f"Warning: Could not load Python DLL from system: {e2}")

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