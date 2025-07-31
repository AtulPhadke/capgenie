# PyInstaller hook for readchar
from PyInstaller.utils.hooks import collect_submodules

# Collect all submodules
hiddenimports = collect_submodules('readchar')

# No data files needed for readchar
datas = [] 