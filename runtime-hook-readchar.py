# Runtime hook to fix Python DLL loading and readchar metadata issues in PyInstaller
import sys
import os
import ctypes
from ctypes import wintypes

def fix_python_dll_loading():
    """Fix Python DLL loading issues on Windows"""
    if os.name == 'nt':  # Windows
        print("=== Python DLL Loading Fix ===")
        try:
            # Try to load Python DLL explicitly
            python_dll_name = 'python312.dll'
            
            # Get current Python executable info
            python_exe = sys.executable
            python_dir = os.path.dirname(python_exe)
            print(f"Python executable: {python_exe}")
            print(f"Python directory: {python_dir}")
            print(f"Current working directory: {os.getcwd()}")
            
            # Method 1: Try to load from current directory
            try:
                print(f"Trying to load {python_dll_name} from current directory...")
                ctypes.PyDLL(python_dll_name)
                print(f"✓ Successfully loaded {python_dll_name} from current directory")
                return
            except OSError as e:
                print(f"✗ Failed to load from current directory: {e}")
            
            # Method 2: Try to load from Python installation directory
            if python_dir:
                try:
                    dll_path = os.path.join(python_dir, python_dll_name)
                    print(f"Trying to load from Python directory: {dll_path}")
                    if os.path.exists(dll_path):
                        ctypes.PyDLL(dll_path)
                        print(f"✓ Successfully loaded {python_dll_name} from Python directory")
                        return
                    else:
                        print(f"✗ DLL not found at: {dll_path}")
                except OSError as e:
                    print(f"✗ Failed to load from Python directory: {e}")
            
            # Method 3: Try to load from _MEIPASS (PyInstaller bundle)
            if hasattr(sys, '_MEIPASS'):
                try:
                    dll_path = os.path.join(sys._MEIPASS, python_dll_name)
                    print(f"Trying to load from _MEIPASS: {dll_path}")
                    if os.path.exists(dll_path):
                        ctypes.PyDLL(dll_path)
                        print(f"✓ Successfully loaded {python_dll_name} from _MEIPASS")
                        return
                    else:
                        print(f"✗ DLL not found in _MEIPASS: {dll_path}")
                except OSError as e:
                    print(f"✗ Failed to load from _MEIPASS: {e}")
            
            # Method 4: Try to load from Windows System32
            try:
                system32_path = os.path.join(os.environ.get('SystemRoot', 'C:\\Windows'), 'System32', python_dll_name)
                print(f"Trying to load from System32: {system32_path}")
                if os.path.exists(system32_path):
                    ctypes.PyDLL(system32_path)
                    print(f"✓ Successfully loaded {python_dll_name} from System32")
                    return
                else:
                    print(f"✗ DLL not found in System32: {system32_path}")
            except OSError as e:
                print(f"✗ Failed to load from System32: {e}")
            
            # Method 5: Try to load from system PATH
            try:
                print("Trying to load from system PATH...")
                ctypes.PyDLL(python_dll_name)
                print(f"✓ Successfully loaded {python_dll_name} from system PATH")
                return
            except OSError as e:
                print(f"✗ Failed to load from system PATH: {e}")
            
            # Method 6: Fallback - try to load the DLL that Python is currently using
            try:
                print("Trying fallback method (load current Python DLL)...")
                ctypes.PyDLL(None)  # This loads the DLL that Python is currently using
                print("✓ Successfully loaded Python DLL using fallback method")
                return
            except OSError as e:
                print(f"✗ Failed fallback method: {e}")
                
            print(f"⚠ Warning: Could not load {python_dll_name} using any method")
            print("This may cause issues with C++ extensions")
            
        except Exception as e:
            print(f"❌ Error during Python DLL loading: {e}")

def fix_path_for_pyinstaller():
    """Fix PATH issues for PyInstaller"""
    print("=== PATH Fix ===")
    if hasattr(sys, '_MEIPASS'):
        # Add PyInstaller bundle directory to PATH
        bundle_dir = sys._MEIPASS
        current_path = os.environ.get('PATH', '')
        if bundle_dir not in current_path:
            os.environ['PATH'] = f"{bundle_dir};{current_path}"
            print(f"✓ Added {bundle_dir} to PATH")
        else:
            print(f"✓ {bundle_dir} already in PATH")
    else:
        print("⚠ No _MEIPASS found (not running in PyInstaller bundle)")

def fix_readchar_metadata():
    """Fix readchar metadata issue"""
    print("=== Readchar Metadata Fix ===")
    try:
        import readchar
        readchar_path = os.path.dirname(readchar.__file__)
        if readchar_path not in sys.path:
            sys.path.insert(0, readchar_path)
            print(f"✓ Added readchar path to sys.path: {readchar_path}")
        else:
            print(f"✓ Readchar path already in sys.path: {readchar_path}")
    except ImportError as e:
        print(f"⚠ Could not import readchar: {e}")

    # Create a dummy metadata for readchar if it doesn't exist
    try:
        import pkg_resources
        try:
            pkg_resources.get_distribution('readchar')
            print("✓ Readchar distribution found")
        except pkg_resources.DistributionNotFound:
            print("⚠ Readchar distribution not found, creating dummy...")
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
            print("✓ Dummy readchar distribution created")
    except ImportError as e:
        print(f"⚠ Could not import pkg_resources: {e}")

# Apply all fixes
print("=== Applying Runtime Hook Fixes ===")
fix_python_dll_loading()
fix_path_for_pyinstaller()
fix_readchar_metadata()
print("=== Runtime Hook Fixes Applied ===") 