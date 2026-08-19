"""Inspect and plot a single scenario's transient trajectories.

The per-scenario trajectory arrays (``time``, ``delta``, ``omega``) are stored
inside the .mat file, not in the flat parquet table. This module reads one
scenario on demand and plots the rotor-angle (delta) and speed (omega) curves.

Units / conventions (verified against the dataset's own ``transient.label``):
  * ``delta`` is stored in RADIANS and is ABSOLUTE, i.e. it includes the
    synchronous reference ramp (omega_s * t ~ 377*3 ~ 1131 rad over the 3 s
    window). Plotting it raw yields an uninformative common ramp, so we plot the
    rotor angle RELATIVE to a reference machine (default: the generator mean,
    ~ centre of inertia) and convert to DEGREES. The resulting inter-machine
    separation reproduces ``label.maxSeparation`` and the 180 deg instability
    criterion exactly.
  * ``omega`` is the generator speed in per-unit (nominal = 1.0).

Indexing: scenario ``index`` is the 0-based row of ``dataset/samples`` and
matches the row order of the flat parquet table produced by ``extract.py``.
"""

from __future__ import annotations

import numpy as np
import pandas as pd
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt

import h5py

from . import MAT_FILE, FIG_DIR as _FIG_BASE, case_subdir
from .loader import load_samples

RAD2DEG = 180.0 / np.pi

# Output directory for figures; switch to a case-specific subfolder via
# ``set_case``. Defaults to the package-level figures folder.
FIG_DIR = _FIG_BASE


def set_case(case_name) -> None:
    """Route scenario figures into ``outputs/figures/<case_name>/``."""
    global FIG_DIR
    FIG_DIR = case_subdir(_FIG_BASE, case_name) if case_name else _FIG_BASE


def load_trajectory(index: int, mat_file=None) -> dict:
    """Read one scenario's transient trajectory + key scalars from the .mat.

    Parameters
    ----------
    index : int
        0-based row of ``dataset/samples`` (matches the flat parquet row order).
    mat_file : str | Path | None
        Source .mat file; defaults to the package-level ``MAT_FILE``. Pass the
        same file the DataFrame came from so indices line up.

    Returns a dict with:
        time       : (T,) seconds
        delta      : (G, T) absolute rotor angles [rad] as stored
        delta_deg  : (G, T) rotor angles relative to the generator mean [deg]
        omega      : (G, T) generator speeds [pu]
        max_sep_deg: (T,) inter-machine max separation [deg]
        tsi, time2LossSync, success : scalars
        stable     : bool (TSI > 0)
        n_gen      : number of generators
    """
    src = mat_file if mat_file is not None else MAT_FILE
    with h5py.File(src, "r") as f:
        samples = f["dataset/samples"]
        n = samples.shape[0]
        if not (0 <= index < n):
            raise IndexError(f"index {index} out of range [0, {n})")
        tr = f[samples[index, 0]]["transient"]
        time = np.asarray(tr["time"]).astype(float).flatten()
        delta = np.asarray(tr["delta"]).astype(float)
        omega = np.asarray(tr["omega"]).astype(float)
        if delta.shape[0] == time.size:  # came back (T, G) -> (G, T)
            delta = delta.T
            omega = omega.T
        tsi = float(np.asarray(tr["tsi"]).flatten()[0])
        t2l = float(np.asarray(tr["time2LossSync"]).flatten()[0])
        success = float(np.asarray(tr["success"]).flatten()[0])

    # Remove the common synchronous ramp: reference to the generator mean
    # (approx. centre of inertia) and convert rad -> deg.
    delta_rel = (delta - delta.mean(axis=0, keepdims=True)) * RAD2DEG
    max_sep_deg = (delta.max(axis=0) - delta.min(axis=0)) * RAD2DEG

    return {
        "index": index,
        "time": time,
        "delta": delta,
        "delta_deg": delta_rel,
        "omega": omega,
        "max_sep_deg": max_sep_deg,
        "tsi": tsi,
        "time2LossSync": t2l,
        "success": success,
        "stable": tsi > 0,
        "n_gen": delta.shape[0],
    }



def find_examples(df: pd.DataFrame | None = None) -> dict:
    """Return one representative stable and one unstable scenario index.

    Picks the median-TSI scenario within each class so the examples are typical
    rather than extreme.
    """
    if df is None:
        df = load_samples()
    stable = df["stable"].astype(bool)

    def _median_index(mask):
        sub = df.loc[mask, "tsi"]
        target = sub.median()
        return int((sub - target).abs().idxmin())

    return {
        "stable": _median_index(stable),
        "unstable": _median_index(~stable),
    }


def plot_scenario(index: int, name: str | None = None, save: bool = True,
                  mat_file=None):
    """Plot delta and omega curves for a single scenario. Returns the figure."""
    tr = load_trajectory(index, mat_file=mat_file)
    label = "STABLE" if tr["stable"] else "UNSTABLE"
    fig, axes = plt.subplots(1, 2, figsize=(12, 4.2))

    ng = tr["n_gen"]
    show_labels = ng <= 12  # avoid an unreadable legend for large networks
    for g in range(ng):
        lbl = f"Gen {g + 1}" if show_labels else None
        axes[0].plot(tr["time"], tr["delta_deg"][g], lw=1.2, label=lbl)
        axes[1].plot(tr["time"], tr["omega"][g], lw=1.2, label=lbl)

    axes[0].axhline(180, color="r", lw=0.8, ls="--", alpha=0.6)
    axes[0].axhline(-180, color="r", lw=0.8, ls="--", alpha=0.6)
    axes[0].set_title("Rotor angle $\\delta$ (relative to gen. mean)")
    axes[0].set_xlabel("time [s]")
    axes[0].set_ylabel("$\\delta$ [deg]")
    if show_labels:
        axes[0].legend(ncol=1 if ng <= 5 else 2, fontsize=8)

    axes[1].set_title("Generator speed $\\omega$")
    axes[1].set_xlabel("time [s]")
    axes[1].set_ylabel("$\\omega$ [pu]")
    axes[1].axhline(1.0, color="k", lw=0.8, ls=":")
    if show_labels:
        axes[1].legend(ncol=1 if ng <= 5 else 2, fontsize=8)

    fig.suptitle(
        f"Scenario {index} - {label}  (TSI = {tr['tsi']:.1f}, "
        f"max sep = {tr['max_sep_deg'].max():.0f} deg, "
        f"t2loss = {tr['time2LossSync']:.3g} s)",
        y=1.03,
    )
    if save:
        FIG_DIR.mkdir(parents=True, exist_ok=True)
        stem = name or f"scenario_{index}_{label.lower()}"
        fig.tight_layout()
        fig.savefig(FIG_DIR / f"{stem}.pdf", bbox_inches="tight")
        fig.savefig(FIG_DIR / f"{stem}.svg", bbox_inches="tight")
        plt.close(fig)
    return fig


def plot_stable_vs_unstable(df: pd.DataFrame | None = None, save: bool = True,
                            mat_file=None):
    """Plot a 2x2 comparison: rows = delta/omega, cols = stable/unstable."""
    ex = find_examples(df)
    s = load_trajectory(ex["stable"], mat_file=mat_file)
    u = load_trajectory(ex["unstable"], mat_file=mat_file)

    fig, axes = plt.subplots(2, 2, figsize=(12, 8), sharex=True)
    for col, tr, title in [(0, s, "STABLE"), (1, u, "UNSTABLE")]:
        ng = tr["n_gen"]
        show_labels = ng <= 12
        for g in range(ng):
            lbl = f"Gen {g + 1}" if show_labels else None
            axes[0, col].plot(tr["time"], tr["delta_deg"][g], lw=1.2, label=lbl)
            axes[1, col].plot(tr["time"], tr["omega"][g], lw=1.2, label=lbl)
        axes[0, col].axhline(180, color="r", lw=0.8, ls="--", alpha=0.6)
        axes[0, col].axhline(-180, color="r", lw=0.8, ls="--", alpha=0.6)
        axes[0, col].set_title(
            f"{title}  (scenario {tr['index']}, TSI = {tr['tsi']:.1f}, "
            f"max sep = {tr['max_sep_deg'].max():.0f} deg)"
        )
        axes[1, col].axhline(1.0, color="k", lw=0.8, ls=":")
        axes[1, col].set_xlabel("time [s]")

    axes[0, 0].set_ylabel("$\\delta$ [deg]  (rel. gen. mean)")
    axes[1, 0].set_ylabel("$\\omega$ [pu]")
    if s["n_gen"] <= 12:
        axes[0, 0].legend(fontsize=8, ncol=1 if s["n_gen"] <= 5 else 2)

    fig.suptitle("Transient trajectories: stable vs unstable", y=1.01)
    if save:
        FIG_DIR.mkdir(parents=True, exist_ok=True)
        fig.tight_layout()
        fig.savefig(FIG_DIR / "fig11_stable_vs_unstable.pdf", bbox_inches="tight")
        fig.savefig(FIG_DIR / "fig11_stable_vs_unstable.svg", bbox_inches="tight")
        plt.close(fig)
    return fig


if __name__ == "__main__":
    # Demo: locate a typical stable and unstable scenario and plot both.
    examples = find_examples()
    print("Example scenarios:", examples)
    plot_scenario(examples["stable"])
    plot_scenario(examples["unstable"])
    plot_stable_vs_unstable()
    print(f"Saved scenario figures to {FIG_DIR}")
