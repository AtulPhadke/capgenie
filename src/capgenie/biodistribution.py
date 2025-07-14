import pandas as pd
#import plotly.graph_objects as px 
from matplotlib import pyplot as plt
from base64 import b64encode
import os
import numpy as np

def gen_bio_graphs(freq_dir, session_folder, dir):
    normal_df = pd.read_pickle(os.path.join("cache", session_folder, "pkl_files", dir, f"average_{dir}.pkl"))
    normal_cols = normal_df.columns.tolist()

    y = list(normal_df[normal_cols[-1]])
    y = [f*100 for f in y]
    x = range(len(y))
    plt.figure(figsize=(10,6))
    plt.title(f"average_{dir}.svg")
    plt.plot(x,y)
    plt.yscale("log")
    plt.ylim(0.001, 10)
    plt.ylabel("Percentage of Reads")
    plt.xlabel("Peptide")
    plt.fill_between(x, 0, y)
    plt.savefig(os.path.join(freq_dir, f"average_{dir}.svg"), format="svg")

