import pandas as pd
import plotly.graph_objects as px 
from base64 import b64encode
import os
import glob
import random
import numpy as np
import warnings

warnings.simplefilter(action='ignore', category=FutureWarning)

"""
 * kv_dict: pd.DataFrame, float --> dict
-- Converts a pandas DataFrame to a dictionary with optional factor multiplication
 * @param [in] df (pd.DataFrame) - DataFrame to convert
 * @param [in] factor (float) - Multiplication factor for values
 * @param [out] result (dict) - Dictionary with first column as keys and second column as values
** Converts DataFrame to key-value dictionary
"""
def kv_dict(df, factor=1):
    return {row[0]:row[1]*float(factor) for index,row in df.iterrows()}

"""
 * Set_Color: any --> str
-- Returns a color for plotting (currently returns "gray")
 * @param [in] x (any) - Input value (unused)
 * @param [out] color (str) - Color string ("gray")
** Returns consistent color for plotting
"""
def Set_Color(x):    
    return "gray"

"""
 * gen_bubble_plots: str, str, str, str --> None
-- Generates bubble plots for enrichment data visualization
 * @param [in] bubble_dir (str) - Directory to save bubble plots
 * @param [in] session_dir (str) - Session directory path
 * @param [in] dir (str) - Data directory name
 * @param [in] cache_folder (str) - Cache folder path
 * @param [out] None - Saves HTML and SVG files to bubble_dir
** Creates interactive bubble plots for peptide enrichment data
"""
def gen_bubble_plots(bubble_dir, session_dir, dir, cache_folder):
    pkl_dir = os.path.join(cache_folder, session_dir, "pkl_files", dir)
    avg_enrich_path = os.path.join(pkl_dir, f"average_enrichment_{dir}.pkl")
    avg_normal_path = os.path.join(pkl_dir, f"average_{dir}.pkl")
    
    # Check if average files exist (multiple files case)
    if os.path.exists(avg_enrich_path) and os.path.exists(avg_normal_path):
        enrich_df = pd.read_pickle(avg_enrich_path)
        normal_df = pd.read_pickle(avg_normal_path)
        title = f"{dir}_data"
    else:
        # Single file case - find individual pkl files
        pkl_files = glob.glob(os.path.join(pkl_dir, "*.pkl"))
        enrich_files = [f for f in pkl_files if "enrichment" in os.path.basename(f)]
        normal_files = [f for f in pkl_files if "enrichment" not in os.path.basename(f)]
        
        if not enrich_files or not normal_files:
            print(f"Warning: Missing enrichment or normal pkl files in {pkl_dir}")
            return
            
        # Use the first (and likely only) files
        enrich_df = pd.read_pickle(enrich_files[0])
        normal_df = pd.read_pickle(normal_files[0])
        filename = os.path.splitext(os.path.basename(normal_files[0]))[0]
        title = f"{filename}_data"
    
    peptides = normal_df.index.tolist()[:500]

    enrich_df = enrich_df.iloc[:, -1].to_dict()
    normal_df = normal_df.iloc[:, -1].to_dict()

    temp =list(zip(peptides, [enrich_df[x] if x in enrich_df else 0 for x in peptides], [normal_df[x]*100 if x in normal_df else 0 for x in peptides]))
    random.shuffle(temp)

    peptides, enrichment, normals = zip(*temp)

    # Improved bubble scaling logic
    enrichment_values = [x for x in enrichment if x > 0]  # Filter out zero values
    if not enrichment_values:
        print(f"Warning: No positive enrichment values found for {dir}")
        return
    
    # Use percentiles for more robust scaling
    min_enrich = np.percentile(enrichment_values, 5)  # 5th percentile
    max_enrich = np.percentile(enrichment_values, 95)  # 95th percentile
    
    # Scale between reasonable bubble sizes (5 to 50 pixels)
    min_size, max_size = 5, 50
    
    # Calculate scale factor using percentile range
    if max_enrich > min_enrich:
        scale_factor = (max_size - min_size) / (max_enrich - min_enrich)
        scaled_sizes = [max(min_size, min(max_size, (x - min_enrich) * scale_factor + min_size)) if x > 0 else min_size for x in enrichment]
    else:
        # All values are similar, use medium size
        scaled_sizes = [20 for _ in enrichment]

    plot = px.Figure(data=[px.Scatter( 
        x = list(peptides), 
        y = normals, 
        mode = 'markers',
        marker_size = scaled_sizes,
        marker_color=list(map(Set_Color, list(peptides))),
        text = [f"{enrich_df[x]}" if x in enrich_df else "0" for x in peptides],
        hovertemplate =
        '<b>Peptide</b>: %{x}<br>' + 
        '<b>Enrichment Factor</b>: %{text}<br>'+ 
        '<b>Percentage</b>: %{y}<br>')
    ])

    plot.update_layout(
        title=dict(text=title, font=dict(size=35), automargin=True, yref='paper'),
        xaxis=dict(
            title='Peptide',
            gridcolor='white',
            gridwidth=2,
        ),
        yaxis=dict(
            title='Percentage',
            gridcolor='white',
            gridwidth=2,
        ),
        paper_bgcolor='rgb(243, 243, 243)',
        plot_bgcolor='rgb(243, 243, 243)'
    )
    plot.update_xaxes(visible=False)

    plot.write_html(os.path.join(bubble_dir, title) + ".html")
    plot.write_image(os.path.join(bubble_dir, title) + ".svg", format="svg", width=1920, height=1080)