<p align="center">
  <img src="assets/capgenie_desc.svg" width="90%" />
</p>

# capgenie

**capgenie** is a software pipeline designed to support the analysis of AAV9 reads in NextGenSequencing (NGS) files. 

capgenie currently supports these features:

- Count frequency of AAV9 read variants based on a given csv file of peptides and their sequences.
- Search for unknown variants in a FastQ file and count the frequency of their reads.
- Denoise FastQ files based on a quality threshold
- Prune duplicate/nigh-duplicate reads for regulating bias
- Calculate enrichment vectors based on a given pre-insert file.
- Create intricate bubble charts mapping frequency and enrichment vectors
- Create frequency distribution charts showing the spread of reads.


## Installation

Get started by installing **capgenie** onto your machine


### What you'll need

- [Python](https://www.python.org/downloads/) version 3.10 or above:
- All dependencies are in requirements.txt

Run the following to install all dependecies

```bash
cd capgenie/
python3 -m pip install -r requirements.txt
```

## Build capgenie

Until we upload **capgenie** to homebrew, we need to manually build the source code onto the machine.

```bash
cd capgenie/
python3 setup.py build_ext --inplace
```

You can type this command into Command Prompt, Powershell, Terminal, or any other integrated terminal of your code editor.

## Documentation

A page detailing documentation on the command line utility will be available on [capgenie.bio/docs](capgenie.bio/docs). For now, please utilize the Jupyter Notebooks in
examples/. 

## Authors

- Please contact [Atul Phadke](phadke.at@northeastern.edu) for any questions regarding the source code.

