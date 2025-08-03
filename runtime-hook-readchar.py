# Runtime hook to fix Python DLL loading and readchar metadata issues in PyInstaller
import sys
import os
import ctypes
from ctypes import wintypes

def verify_dll_integrity(dll_path):
    """Verify that a DLL file is not corrupted"""
    try:
        if not os.path.exists(dll_path):
            return False, "DLL file does not exist"
        
        # Check file size (should be reasonable for python312.dll)
        file_size = os.path.getsize(dll_path)
        if file_size < 1000000:  # Less than 1MB is suspicious
            return False, f"DLL file size too small: {file_size} bytes"
        
        # Try to open the file to check if it's readable
        with open(dll_path, 'rb') as f:
            # Read first few bytes to check if it's a valid PE file
            header = f.read(2)
            if header != b'MZ':
                return False, "DLL file is not a valid PE file (missing MZ header)"
        
        return True, f"DLL appears valid (size: {file_size} bytes)"
    except Exception as e:
        return False, f"Error verifying DLL: {e}"

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
                current_dll = os.path.join(os.getcwd(), python_dll_name)
                if os.path.exists(current_dll):
                    is_valid, message = verify_dll_integrity(current_dll)
                    print(f"DLL integrity check: {message}")
                    if is_valid:
                        ctypes.PyDLL(current_dll)
                        print(f"[OK] Successfully loaded {python_dll_name} from current directory")
                        return
                    else:
                        print(f"[FAIL] DLL integrity check failed: {message}")
                else:
                    print(f"[FAIL] DLL not found in current directory: {current_dll}")
            except OSError as e:
                print(f"[FAIL] Failed to load from current directory: {e}")
            
            # Method 2: Try to load from Python installation directory
            if python_dir:
                try:
                    dll_path = os.path.join(python_dir, python_dll_name)
                    print(f"Trying to load from Python directory: {dll_path}")
                    if os.path.exists(dll_path):
                        is_valid, message = verify_dll_integrity(dll_path)
                        print(f"DLL integrity check: {message}")
                        if is_valid:
                            ctypes.PyDLL(dll_path)
                            print(f"[OK] Successfully loaded {python_dll_name} from Python directory")
                            return
                        else:
                            print(f"[FAIL] DLL integrity check failed: {message}")
                    else:
                        print(f"[FAIL] DLL not found at: {dll_path}")
                except OSError as e:
                    print(f"[FAIL] Failed to load from Python directory: {e}")
            
            # Method 3: Try to load from _MEIPASS (PyInstaller bundle)
            if hasattr(sys, '_MEIPASS'):
                try:
                    dll_path = os.path.join(sys._MEIPASS, python_dll_name)
                    print(f"Trying to load from _MEIPASS: {dll_path}")
                    if os.path.exists(dll_path):
                        is_valid, message = verify_dll_integrity(dll_path)
                        print(f"DLL integrity check: {message}")
                        if is_valid:
                            ctypes.PyDLL(dll_path)
                            print(f"[OK] Successfully loaded {python_dll_name} from _MEIPASS")
                            return
                        else:
                            print(f"[FAIL] DLL integrity check failed: {message}")
                    else:
                        print(f"[FAIL] DLL not found in _MEIPASS: {dll_path}")
                except OSError as e:
                    print(f"[FAIL] Failed to load from _MEIPASS: {e}")
            
            # Method 4: Try to load from Windows System32
            try:
                system32_path = os.path.join(os.environ.get('SystemRoot', 'C:\\Windows'), 'System32', python_dll_name)
                print(f"Trying to load from System32: {system32_path}")
                if os.path.exists(system32_path):
                    is_valid, message = verify_dll_integrity(system32_path)
                    print(f"DLL integrity check: {message}")
                    if is_valid:
                        ctypes.PyDLL(system32_path)
                        print(f"[OK] Successfully loaded {python_dll_name} from System32")
                        return
                    else:
                        print(f"[FAIL] DLL integrity check failed: {message}")
                else:
                    print(f"[FAIL] DLL not found in System32: {system32_path}")
            except OSError as e:
                print(f"[FAIL] Failed to load from System32: {e}")
            
            # Method 5: Try to load from system PATH
            try:
                print("Trying to load from system PATH...")
                ctypes.PyDLL(python_dll_name)
                print(f"[OK] Successfully loaded {python_dll_name} from system PATH")
                return
            except OSError as e:
                print(f"[FAIL] Failed to load from system PATH: {e}")
            
            # Method 6: Fallback - try to load the DLL that Python is currently using
            try:
                print("Trying fallback method (load current Python DLL)...")
                ctypes.PyDLL(None)  # This loads the DLL that Python is currently using
                print("[OK] Successfully loaded Python DLL using fallback method")
                return
            except OSError as e:
                print(f"[FAIL] Failed fallback method: {e}")
                
            print(f"[WARN] Warning: Could not load {python_dll_name} using any method")
            print("This may cause issues with C++ extensions")
            
        except Exception as e:
            print(f"[ERROR] Error during Python DLL loading: {e}")

def fix_path_for_pyinstaller():
    """Fix PATH issues for PyInstaller"""
    print("=== PATH Fix ===")
    try:
        if hasattr(sys, '_MEIPASS'):
            # Add PyInstaller bundle directory to PATH
            bundle_dir = sys._MEIPASS
            current_path = os.environ.get('PATH', '')
            if bundle_dir not in current_path:
                os.environ['PATH'] = f"{bundle_dir};{current_path}"
                print(f"[OK] Added {bundle_dir} to PATH")
            else:
                print(f"[OK] {bundle_dir} already in PATH")
        else:
            print("[WARN] No _MEIPASS found (not running in PyInstaller bundle)")
    except Exception as e:
        print(f"[ERROR] Error during PATH fix: {e}")

def fix_readchar_metadata():
    """Fix readchar metadata issue"""
    print("=== Readchar Metadata Fix ===")
    try:
        import readchar
        readchar_path = os.path.dirname(readchar.__file__)
        if readchar_path not in sys.path:
            sys.path.insert(0, readchar_path)
            print(f"[OK] Added readchar path to sys.path: {readchar_path}")
        else:
            print(f"[OK] Readchar path already in sys.path: {readchar_path}")
    except ImportError as e:
        print(f"[WARN] Could not import readchar: {e}")

    # Simple approach: just ensure readchar is importable
    # Don't try to create dummy distributions as it can cause issues
    try:
        import readchar
        print("[OK] Readchar is importable")
    except Exception as e:
        print(f"[WARN] Readchar import issue: {e}")
        print("[WARN] This may not affect functionality")

def test_capgenie_imports():
    """Test if CapGenie modules can be imported successfully"""
    print("=== Testing CapGenie Imports ===")
    try:
        # Test importing the main CLI module
        import capgenie.cli
        print("[OK] Successfully imported capgenie.cli")
        
        # Test importing C++ extensions
        import capgenie.denoise
        print("[OK] Successfully imported capgenie.denoise")
        
        import capgenie.fuzzy_match
        print("[OK] Successfully imported capgenie.fuzzy_match")
        
        import capgenie.mani
        print("[OK] Successfully imported capgenie.mani")
        
        import capgenie.filter_module
        print("[OK] Successfully imported capgenie.filter_module")
        
        print("[OK] All CapGenie modules imported successfully")
        return True
    except Exception as e:
        print(f"[ERROR] Failed to import CapGenie modules: {e}")
        return False

# Apply all fixes with comprehensive error handling
print("=== Applying Runtime Hook Fixes ===")
try:
    fix_python_dll_loading()
    fix_path_for_pyinstaller()
    fix_readchar_metadata()
    test_capgenie_imports()
    print("=== Runtime Hook Fixes Applied Successfully ===")
except Exception as e:
    print(f"[CRITICAL ERROR] Runtime hook failed: {e}")
    # Don't raise the exception - let the application continue
    print("[CRITICAL ERROR] Continuing despite runtime hook failure...") 