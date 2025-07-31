# PyInstaller hook for readchar
from PyInstaller.utils.hooks import collect_data_files, collect_submodules

# Collect all submodules
hiddenimports = collect_submodules('readchar')

# Collect data files if any
datas = collect_data_files('readchar')

# Add specific metadata handling
try:
    import readchar
    import pkg_resources
    readchar_dist = pkg_resources.get_distribution('readchar')
    if readchar_dist.has_metadata('METADATA'):
        datas.append((readchar_dist.get_metadata('METADATA'), 'readchar'))
    elif readchar_dist.has_metadata('PKG-INFO'):
        datas.append((readchar_dist.get_metadata('PKG-INFO'), 'readchar'))
except (ImportError, pkg_resources.DistributionNotFound):
    pass 