import pandas as pd
import plotly.graph_objects as px 
from base64 import b64encode
import os
import random
import numpy as np
import warnings

warnings.simplefilter(action='ignore', category=FutureWarning)

def kv_dict(df, factor=1):
    return {row[0]:row[1]*float(factor) for index,row in df.iterrows()}

def Set_Color(x):    
    return "gray"

def gen_bubble_plots(bubble_dir, session_dir, dir):
    
    enrich_df = pd.read_pickle(os.path.join("cache", session_dir, "pkl_files", dir, f"average_enrichment_{dir}.pkl"))
    normal_df = pd.read_pickle(os.path.join("cache", session_dir, "pkl_files", dir, f"average_{dir}.pkl"))
    peptides = normal_df.index.tolist()[:500]

    enrich_df = enrich_df.iloc[:, -1].to_dict()
    normal_df = normal_df.iloc[:, -1].to_dict()

    temp =list(zip(peptides, [enrich_df[x] if x in enrich_df else 0 for x in peptides], [normal_df[x]*100 if x in normal_df else 0 for x in peptides]))
    random.shuffle(temp)

    peptides, enrichment, normals = zip(*temp)

    scale_factor = 10/np.mean(enrichment)

    plot = px.Figure(data=[px.Scatter( 
        x = list(peptides), 
        y = normals, 
        mode = 'markers',
        marker_size = [x*scale_factor for x in list(enrichment)],
        marker_color=list(map(Set_Color, list(peptides))),
        text = [f"{enrich_df[x]}" if x in enrich_df else "0" for x in peptides],
        hovertemplate =
        '<b>Peptide</b>: %{x}<br>' + 
        '<b>Enrichment Factor</b>: %{text}<br>'+ 
        '<b>Percentage</b>: %{y}<br>')
    ])
    title = f"{dir}_data"

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