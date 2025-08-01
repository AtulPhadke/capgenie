# Runtime hook to fix readchar metadata issue in PyInstaller
import sys
import os

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