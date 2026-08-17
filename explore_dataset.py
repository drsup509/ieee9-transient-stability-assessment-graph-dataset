#!/usr/bin/env python3
"""
explore_dataset.py
==================

Explore the transient-stability dataset and print a structured summary.

It works on either container:

  * the original MATLAB v7.3 file  (``*.mat``), or
  * the clean export produced by ``convert_mat_to_hdf5.py`` (``*_clean.h5``).

For the clean file it also demonstrates how to pull a single scenario's rotor
trajectory, reference it to the centre of inertia, and (optionally) plot it.

Usage
-----
    python explore_dataset.py FILE.h5                 # summary of clean export
    python explore_dataset.py FILE.mat               # summary of raw .mat
    python explore_dataset.py FILE_clean.h5 --plot 0 # plot scenario index 0

Requirements: numpy, h5py.  (matplotlib only needed for --plot.)
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

import numpy as np

try:
    import h5py
except ImportError:  # pragma: no cover
    sys.exit("This script requires h5py:  pip install h5py")

RAD2DEG = 180.0 / np.pi


def _decode_chars(node) -> str:
    return "".join(chr(int(c)) for c in np.asarray(node).flatten())


# --------------------------------------------------------------------------- #
# Clean HDF5 export
# --------------------------------------------------------------------------- #
def summarize_clean(path: Path, plot_index: int | None) -> None:
    with h5py.File(path, "r") as f:
        print("=" * 66)
        print(f"CLEAN DATASET: {path.name}")
        print("=" * 66)
        for k, v in f.attrs.items():
            print(f"  {k:15s}: {v}")

        print("\n-- metadata --")
        for k in f["metadata"].keys():
            print(f"  {k:18s}: {float(np.asarray(f['metadata'][k])):g}")
        print("\n-- statistics --")
        for k in f["statistics"].keys():
            print(f"  {k:18s}: {float(np.asarray(f['statistics'][k])):g}")

        print("\n-- scalar fields (min / mean / max) --")
        sc = f["scalars"]
        for name in sorted(sc.keys()):
            a = np.asarray(sc[name], dtype=float)
            finite = a[np.isfinite(a)]
            if finite.size:
                print(f"  {name:32s}: {finite.min():12.4g} "
                      f"{finite.mean():12.4g} {finite.max():12.4g}")

        if "stable" in sc:
            st = np.asarray(sc["stable"]).astype(bool)
            print(f"\n  class balance (label: separation <= 180 deg): "
                  f"stable={int(st.sum())}  unstable={int((~st).sum())}")

        print("\n-- trajectories --")
        tr = f["trajectories"]
        for k in tr.keys():
            print(f"  {k:8s}: shape={tr[k].shape}  {dict(tr[k].attrs)}")

        # Demonstrate accessing one scenario's rotor angles.
        idx = plot_index if plot_index is not None else 0
        delta = np.asarray(tr["delta"][idx])          # (n_gen, n_time) [rad]
        omega = np.asarray(tr["omega"][idx])          # (n_gen, n_time) [pu]
        t = np.asarray(tr["time"])                     # (n_time,)
        coi = delta.mean(axis=0, keepdims=True)        # centre of inertia
        sep_deg = (delta - coi) * RAD2DEG              # inter-machine [deg]
        max_sep = (delta.max(axis=0) - delta.min(axis=0)).max() * RAD2DEG
        print(f"\n-- example scenario index {idx} --")
        print(f"  peak inter-machine separation : {max_sep:8.2f} deg")
        print(f"  peak |omega-1|                : {np.abs(omega - 1).max():8.5f} pu")
        if "transient_tsi" in sc:
            print(f"  TSI                           : {float(sc['transient_tsi'][idx]):8.2f}")

        if plot_index is not None:
            _plot(t, sep_deg, omega, idx, path)


def _plot(t, sep_deg, omega, idx, path) -> None:
    try:
        import matplotlib.pyplot as plt
    except ImportError:
        print("  (matplotlib not installed; skipping plot)")
        return
    fig, axes = plt.subplots(1, 2, figsize=(11, 4))
    for g in range(sep_deg.shape[0]):
        axes[0].plot(t, sep_deg[g], label=f"gen {g + 1}")
        axes[1].plot(t, omega[g], label=f"gen {g + 1}")
    axes[0].set(title=f"Rotor angle vs COI (scenario {idx})",
                xlabel="time [s]", ylabel="angle [deg]")
    axes[1].set(title=f"Speed (scenario {idx})",
                xlabel="time [s]", ylabel=r"$\omega$ [pu]")
    axes[0].legend(); axes[1].legend()
    fig.tight_layout()
    out = path.with_name(f"scenario_{idx}.png")
    fig.savefig(out, dpi=150)
    print(f"  saved plot -> {out}")


# --------------------------------------------------------------------------- #
# Raw MATLAB v7.3 file
# --------------------------------------------------------------------------- #
def summarize_raw(path: Path) -> None:
    with h5py.File(path, "r") as f:
        print("=" * 66)
        print(f"RAW MATLAB v7.3 FILE: {path.name}")
        print("=" * 66)
        md = f["dataset/metadata"]
        print(f"  caseName     : {_decode_chars(md['caseName'])}")
        for k in ["totalSamples", "stableRate", "unstableRate",
                  "acceptedRate", "borderlineRate", "rejectedRate"]:
            if k in md:
                print(f"  {k:14s}: {float(np.asarray(md[k])):g}")

        print("\n-- statistics --")
        for k in f["dataset/statistics"].keys():
            arr = np.asarray(f["dataset/statistics"][k])
            if arr.dtype.kind in "fiu" and arr.size == 1 and arr.dtype != np.uint64:
                print(f"  {k:16s}: {float(arr.flatten()[0]):g}")

        samples = f["dataset/samples"]
        n = samples.shape[0]
        print(f"\n  samples: {n} structs (HDF5 object references)")
        smp = f[samples[0, 0]]
        print("  groups in each sample:")
        for grp in smp.keys():
            node = smp[grp]
            kind = "group" if isinstance(node, h5py.Group) else "dataset"
            print(f"    {grp:12s} ({kind})")

        print("\n  Tip: run convert_mat_to_hdf5.py first for a flat, "
              "analysis-ready file.")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("file", type=Path, help="a .mat (v7.3) or _clean.h5 file")
    ap.add_argument("--plot", type=int, default=None, metavar="IDX",
                    help="plot the trajectory of scenario IDX (clean file only)")
    args = ap.parse_args()

    if not args.file.exists():
        sys.exit(f"File not found: {args.file}")

    # A clean export has a top-level 'scalars' group; the raw .mat does not.
    with h5py.File(args.file, "r") as probe:
        is_clean = "scalars" in probe

    if is_clean:
        summarize_clean(args.file, args.plot)
    else:
        if args.plot is not None:
            print("(--plot works on the clean export; showing summary only)\n")
        summarize_raw(args.file)


if __name__ == "__main__":
    main()
