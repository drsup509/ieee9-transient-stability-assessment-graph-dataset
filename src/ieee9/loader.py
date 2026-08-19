"""Load the flat sample table and the file-level metadata."""

from __future__ import annotations

import numpy as np
import pandas as pd
import h5py

from . import MAT_FILE
from .extract import extract


def load_samples(force: bool = False, mat_file=None) -> pd.DataFrame:
    """Return the tidy 10k-row sample table (extracting/caching as needed).

    force : re-read the .mat even if a cache exists.
    mat_file : path to the source .mat (defaults to package MAT_FILE).
    """
    return extract(force=force, mat_file=mat_file)


def load_metadata(mat_file=None) -> dict:
    """Return file-level metadata + statistics as a plain dict of scalars."""
    src = mat_file if mat_file is not None else MAT_FILE
    out: dict = {}
    with h5py.File(src, "r") as f:
        md = f["dataset/metadata"]
        cn = np.asarray(md["caseName"])
        out["caseName"] = "".join(chr(c) for c in cn.flatten())
        for k in [
            "totalSamples", "numberRequested", "acceptedRate", "borderlineRate",
            "rejectedRate", "stableRate", "unstableRate",
        ]:
            out[k] = float(np.asarray(md[k]).flatten()[0])
        # tsiThresholdDeg lives under an optional postSim group; some dataset
        # versions omit it. Read it when present, else fall back to NaN.
        if "postSim" in md and "tsiThresholdDeg" in md["postSim"]:
            out["tsiThresholdDeg"] = float(np.asarray(md["postSim/tsiThresholdDeg"]).flatten()[0])
        else:
            out["tsiThresholdDeg"] = float("nan")
        st = f["dataset/statistics"]
        for k in ["accepted", "borderline", "rejected", "stable", "unstable",
                  "total", "transientFailed"]:
            out[f"stat_{k}"] = float(np.asarray(st[k]).flatten()[0])
    return out
