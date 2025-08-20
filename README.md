<p align="center">
  <img src="assets/capgenie_desc.svg" width="90%" />
</p>

# capgenie

**capgenie** is a comprehensive bioinformatics software pipeline designed for the analysis of AAV9 reads in Next-Generation Sequencing (NGS) files. It provides advanced tools for sequence analysis, variant detection, and data visualization.

## Features

capgenie currently supports these key features:

- **Known Variant Analysis**: Count frequency of AAV9 read variants based on a given CSV file of peptides and their sequences
- **Unknown Variant Discovery**: Search for unknown variants in FastQ files and count their read frequencies
- **Data Quality Control**: 
  - Denoise FastQ files based on quality thresholds
  - Prune duplicate/near-duplicate reads to reduce bias
- **Enrichment Analysis**: Calculate enrichment vectors based on pre-insert files
- **Advanced Visualization**:
  - Create intricate bubble charts mapping frequency and enrichment vectors
  - Generate frequency distribution charts showing read spread
  - Biodistribution analysis and visualization
- **Motif Analysis**: Identify and analyze sequence motifs in capsid files
- **Spreadsheet Integration**: Export results to Excel or CSV formats

## Installation

### Prerequisites

- **Python** version 3.12 or above
- **C++ compiler** (for building native extensions):
  - **macOS**: Xcode Command Line Tools
  - **Windows**: Visual Studio Build Tools or MinGW
  - **Linux**: GCC or Clang

### Quick Installation

The easiest way to install capgenie is using the provided installation script:

```bash
cd cap_genie_dist/
chmod +x install_package.sh
./install_package.sh
```

### Manual Installation

1. **Clone or download** the capgenie repository
2. **Navigate** to the cap_genie_dist directory:
   ```bash
   cd cap_genie_dist/
   ```

3. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

4. **Install capgenie** in editable mode:
   ```bash
   pip install -e .
   ```

### Alternative Installation Methods

#### Using Virtual Environment (Recommended)
```bash
python -m venv capgenie_env
source capgenie_env/bin/activate  # On Windows: capgenie_env\Scripts\activate
pip install -e .
```

#### Using Conda
```bash
conda create -n capgenie python=3.12
conda activate capgenie
pip install -e .
```

## Usage

capgenie provides a comprehensive command-line interface for all analysis tasks.

### Basic Usage

```bash
capgenie -f <input_folder> -cf <capsid_file> -m <mismatches> -mt <mismatch_type> [options]
```

### Key Commands

#### Known Variant Analysis
```bash
capgenie -f /path/to/fastq/files -cf capsid_peptides.csv -m 2 -mt hamming
```

#### Unknown Variant Discovery
```bash
capgenie -f /path/to/fastq/files -unk -f1 "flank1_sequence" -f2 "flank2_sequence"
```

#### Quality Control
```bash
capgenie -f /path/to/fastq/files -qual 30
```

#### Generate Visualizations
```bash
capgenie -f /path/to/fastq/files -cf capsid_file.csv -b -fd
```

### Command Line Options

- `-f, --folder`: Input folder containing FastQ files (required)
- `-cf, --capsidfile`: Path to capsid peptide CSV file
- `-m, --mismatches`: Number of allowed mismatches for known variants
- `-mt, --mtype`: Mismatch type (hamming, levenshtein, etc.)
- `-unk, --unknownvariants`: Search for unknown variants
- `-f1, --flank1`: First flank sequence for unknown variant search
- `-f2, --flank2`: Second flank sequence for unknown variant search
- `-o, --output`: Output directory for results
- `-b, --bubble`: Generate bubble charts
- `-fd, --freq_distribution`: Generate frequency distribution charts
- `-qual, --quality_threshold`: Quality threshold for denoising
- `-mot, --motif`: Perform motif analysis
- `-cls, --clear_cache`: Clear all cached data

## Examples

See the `examples/` directory for detailed Jupyter notebooks demonstrating:
- Counting known variants (`counting_known_variants.ipynb`)
- Searching unknown variants (`searching_unknown_variants.ipynb`)
- Sample datasets for testing

## Building Executables

capgenie can be built into standalone executables for distribution:

### macOS
```bash
./build-executable-mac.sh
```

### Windows
```bash
build-executable-windows-optimized.bat
```

### All Platforms
```bash
./build-all-executables.sh
```

## Documentation

- **Command Line Interface**: See the examples in the `examples/` directory
- **API Documentation**: Available in the source code with detailed docstrings
- **Advanced Usage**: Check `OPTIMIZATION_README.md` for performance optimization tips
- **Build Instructions**: See `EXECUTABLE_BUILD_README.md` for executable creation

## Development

### Building from Source

To build the C++ extensions from source:

```bash
python setup.py build_ext --inplace
```

### Testing

Run the test suite:
```bash
python -m pytest tests/
```

## Support

For questions, issues, or contributions:

- **Contact**: [Atul Phadke](mailto:phadke.at@northeastern.edu)
- **Issues**: Please use the GitHub issue tracker
- **Documentation**: Check the `examples/` directory and source code comments

## License

This project is licensed under the MIT License - see the LICENSE file for details.

