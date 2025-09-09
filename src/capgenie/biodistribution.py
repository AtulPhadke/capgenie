import pandas as pd
#import plotly.graph_objects as px 
from matplotlib import pyplot as plt
from base64 import b64encode
import os
import glob
import numpy as np

"""
 * gen_bio_graphs: str, str, str, str --> None
-- Generates biodistribution graphs for frequency data
 * @param [in] freq_dir (str) - Directory to save frequency graphs
 * @param [in] session_folder (str) - Session folder path
 * @param [in] dir (str) - Data directory name
 * @param [in] cache_folder (str) - Cache folder path
 * @param [out] None - Saves SVG files to freq_dir
** Creates log-scale biodistribution plots for peptide frequency data
"""
def gen_bio_graphs(freq_dir, session_folder, dir, cache_folder):
    pkl_dir = os.path.join(cache_folder, session_folder, "pkl_files", dir)
    avg_pkl_path = os.path.join(pkl_dir, f"average_{dir}.pkl")
    
    # Check if average file exists (multiple files case)
    if os.path.exists(avg_pkl_path):
        normal_df = pd.read_pickle(avg_pkl_path)
        title = f"average_{dir}.svg"
    else:
        # Single file case - find the individual pkl file
        pkl_files = glob.glob(os.path.join(pkl_dir, "*.pkl"))
        # Filter out enrichment files
        pkl_files = [f for f in pkl_files if not "enrichment" in os.path.basename(f)]
        
        if not pkl_files:
            print(f"Warning: No pkl files found in {pkl_dir}")
            return
            
        # Use the first (and likely only) pkl file
        normal_df = pd.read_pickle(pkl_files[0])
        filename = os.path.splitext(os.path.basename(pkl_files[0]))[0]
        title = f"{filename}.svg"
    
    normal_cols = normal_df.columns.tolist()

    # Limit to top 1000 peptides for better performance and readability
    y = list(normal_df[normal_cols[-1]])
    if len(y) > 1000:
        print(f"Limiting frequency distribution to top 1000 peptides (from {len(y)} total)")
        y = y[:1000]
    
    y = [f*100 for f in y]
    x = range(len(y))
    plt.figure(figsize=(10,6))
    plt.title(title)
    plt.plot(x,y)
    plt.yscale("log")
    plt.ylim(0.001, 10)
    plt.ylabel("Percentage of Reads")
    plt.xlabel("Peptide")
    plt.fill_between(x, 0, y)
    plt.savefig(os.path.join(freq_dir, title), format="svg")

