#!/usr/bin/env python3
"""
convert_mat_to_hdf5.py
======================

Convert the transient-stability dataset from its native MATLAB ``.mat``
container into a clean, self-describing, analysis-ready HDF5 file.

Why this script exists
----------------------
The distributed ``.mat`` file is already saved in MATLAB **v7.3** format,
which *is* an HDF5 container. However, it is not convenient to read directly
because:

  * per-sample records are stored as an ``(N, 1)`` array of HDF5 object
    *references* (one MATLAB struct per sample), so every field access
    requires dereferencing;
  * text fields (fault type, stability label text, timestamps, ...) are stored
    as MATLAB *MCOS* objects in the ``#subsystem#`` group and are **not**
    portably readable outside MATLAB;
  * numeric scalars are wrapped as ``(1, 1)`` matrices.

This converter produces a *flat*, portable HDF5 file in which:

  * every per-sample scalar becomes a 1-D array of length ``N``
    (group ``/scalars``);
  * the rotor-angle and speed trajectories are stacked into dense
    ``(N, n_gen, n_time)`` arrays (group ``/trajectories``);
  * the power-flow vectors and generator limits become ``(N, ...)`` arrays
    (group ``/powerflow``);
  * dataset-level ``metadata`` and ``statistics`` are copied as datasets with
    human-readable attributes.

The output can be opened with h5py, MATLAB ``h5read``, ``pandas``/``xarray``,
Julia, R (``rhdf5``), or any HDF5-aware tool.

Usage
-----
    python convert_mat_to_hdf5.py INPUT.mat [-o OUTPUT.h5] [--limit N]

Requirements: numpy, h5py.
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


# --------------------------------------------------------------------------- #
# Low-level helpers
# --------------------------------------------------------------------------- #
def _decode_chars(node) -> str:
    """Decode a MATLAB uint16 char array (e.g. caseName) into a Python string."""
    arr = np.asarray(node).flatten()
    return "".join(chr(int(c)) for c in arr)


def _is_opaque(arr: np.ndarray) -> bool:
    """True for MATLAB MCOS object references (not portable numeric data)."""
    return (arr.dtype == np.uint32 and arr.size == 6) or arr.dtype == np.uint64


def _collect_scalar_paths(group, prefix=()):
    """Recursively list all (1, 1) numeric leaves as tuples of path components."""
    paths = []
    for key in group.keys():
        child = group[key]
        comps = prefix + (key,)
        if isinstance(child, h5py.Group):
            paths.extend(_collect_scalar_paths(child, comps))
        else:
            arr = np.asarray(child)
            if arr.shape == (1, 1) and arr.dtype.kind in "fiu" and not _is_opaque(arr):
                paths.append(comps)
    return paths


def _get_by_path(sample, comps):
    """Descend a sample struct along path components; return np.ndarray or None."""
    node = sample
    for c in comps:
        if c not in node:
            return None
        node = node[c]
    return np.asarray(node)


def _read_2d(sample, key):
    """Return a 2-D float array for ``sample[key]`` or None if absent/opaque."""
    if key not in sample:
        return None
    arr = np.asarray(sample[key])
    if _is_opaque(arr):
        return None
    return arr.astype(float)


# --------------------------------------------------------------------------- #
# Main conversion
# --------------------------------------------------------------------------- #
def convert(mat_path: Path, out_path: Path, limit: int | None = None) -> None:
    with h5py.File(mat_path, "r") as f:
        if "dataset/samples" not in f:
            sys.exit("Unexpected file layout: 'dataset/samples' not found.")

        samples = f["dataset/samples"]
        n_total = samples.shape[0]
        n = n_total if limit is None else min(limit, n_total)
        print(f"Source: {mat_path.name}  ({n_total} samples, converting {n})")

        # --- discover the schema from the first sample -------------------- #
        first = f[samples[0, 0]]
        scalar_paths = _collect_scalar_paths(first)
        scalar_names = ["_".join(p) for p in scalar_paths]

        # Trajectory / power-flow shapes (assumed constant across samples).
        delta0 = _read_2d(first["transient"], "delta")      # (n_gen, n_time)
        omega0 = _read_2d(first["transient"], "omega")
        time0 = _read_2d(first["transient"], "time")        # (1, n_time)
        n_gen, n_time = delta0.shape
        pg0 = _read_2d(first["powerFlow"], "Pg")            # (1, n_gen)
        pd0 = _read_2d(first["powerFlow"], "Pd")            # (1, n_bus)
        n_bus = pd0.shape[1]
        case_name = _decode_chars(f["dataset/metadata/caseName"])

        print(f"  case={case_name}  n_gen={n_gen}  n_bus={n_bus}  n_time={n_time}")
        print(f"  {len(scalar_names)} scalar fields discovered")

        # --- allocate output arrays --------------------------------------- #
        scalars = {name: np.full(n, np.nan) for name in scalar_names}
        delta = np.full((n, n_gen, n_time), np.nan)
        omega = np.full((n, n_gen, n_time), np.nan)
        time_axis = time0.astype(float).flatten()
        pf = {
            "Pg": np.full((n, n_gen), np.nan),
            "Qg": np.full((n, n_gen), np.nan),
            "Pd": np.full((n, n_bus), np.nan),
            "Qd": np.full((n, n_bus), np.nan),
            "V": np.full((n, n_bus), np.nan),
            "theta": np.full((n, n_bus), np.nan),
        }
        # Generator active/reactive limits from MATPOWER mpc.gen (transposed).
        gen_lims = {k: np.full((n, n_gen), np.nan)
                    for k in ("Pmax", "Pmin", "Qmax", "Qmin")}
        gen_rows = {"Qmax": 3, "Qmin": 4, "Pmax": 8, "Pmin": 9}

        # --- iterate over all samples ------------------------------------- #
        for i in range(n):
            smp = f[samples[i, 0]]
            for name, comps in zip(scalar_names, scalar_paths):
                v = _get_by_path(smp, comps)
                if v is not None and v.size:
                    scalars[name][i] = float(v.flatten()[0])

            d = _read_2d(smp["transient"], "delta")
            o = _read_2d(smp["transient"], "omega")
            if d is not None and d.shape == (n_gen, n_time):
                delta[i] = d
            if o is not None and o.shape == (n_gen, n_time):
                omega[i] = o

            for key, dest in pf.items():
                arr = _read_2d(smp["powerFlow"], key)
                if arr is not None and arr.shape[1] == dest.shape[1]:
                    dest[i] = arr.flatten()

            gm = _read_2d(smp["mpc"], "gen")  # (21, n_gen)
            if gm is not None and gm.ndim == 2 and gm.shape[0] > 9:
                for k, r in gen_rows.items():
                    gen_lims[k][i] = gm[r, : n_gen]

            if (i + 1) % 1000 == 0:
                print(f"  processed {i + 1}/{n}")

        # Authoritative stability label. The dataset classifies a scenario as
        # UNSTABLE when the peak inter-machine angle separation exceeds
        # transient.label.threshold (= 180 deg for every sample), encoded in the
        # numeric field transient.label.value (1 = unstable, 0 = stable).
        # stable = (value == 0) reproduces statistics.stable exactly.
        label_value = scalars.get("transient_label_value")
        stable = (label_value == 0).astype(np.int8) if label_value is not None else None

        # --- read dataset-level metadata / statistics --------------------- #
        meta = {}
        md = f["dataset/metadata"]
        for k in md.keys():
            arr = np.asarray(md[k])
            if arr.dtype.kind == "f" and arr.size == 1:
                meta[k] = float(arr.flatten()[0])
        stats = {}
        for k in f["dataset/statistics"].keys():
            arr = np.asarray(f["dataset/statistics"][k])
            if arr.dtype.kind in "fiu" and arr.size == 1 and not _is_opaque(arr):
                stats[k] = float(arr.flatten()[0])

    # ----------------------------------------------------------------- #
    # Write the clean HDF5 file
    # ----------------------------------------------------------------- #
    with h5py.File(out_path, "w") as g:
        g.attrs["case_name"] = case_name
        g.attrs["n_samples"] = n
        g.attrs["n_generators"] = n_gen
        g.attrs["n_buses"] = n_bus
        g.attrs["n_time"] = n_time
        g.attrs["description"] = (
            "Clean, flat HDF5 export of the transient-stability dataset. "
            "Scalars are (N,) arrays; trajectories are (N, n_gen, n_time)."
        )

        gm = g.create_group("metadata")
        for k, v in meta.items():
            gm.create_dataset(k, data=v)
        gs = g.create_group("statistics")
        for k, v in stats.items():
            gs.create_dataset(k, data=v)

        sc = g.create_group("scalars")
        for name, arr in scalars.items():
            sc.create_dataset(name, data=arr, compression="gzip")
        if stable is not None:
            ds = sc.create_dataset("stable", data=stable, compression="gzip")
            ds.attrs["definition"] = (
                "1 if stable, 0 if unstable. Equals transient_label_value == 0, "
                "i.e. peak angle separation <= 180 deg. Matches statistics.stable."
            )

        tr = g.create_group("trajectories")
        tr.create_dataset("time", data=time_axis)
        d = tr.create_dataset("delta", data=delta, compression="gzip")
        d.attrs["units"] = "radian"
        d.attrs["note"] = (
            "Absolute rotor angle (includes synchronous ramp). For inter-machine "
            "separation, subtract the per-sample generator mean (centre of "
            "inertia) and convert to degrees (x 180/pi)."
        )
        o = tr.create_dataset("omega", data=omega, compression="gzip")
        o.attrs["units"] = "per-unit (nominal 1.0)"

        pfg = g.create_group("powerflow")
        pf_units = {"Pg": "MW", "Qg": "MVAr", "Pd": "MW", "Qd": "MVAr",
                    "V": "pu", "theta": "rad"}
        for key, arr in pf.items():
            dset = pfg.create_dataset(key, data=arr, compression="gzip")
            dset.attrs["units"] = pf_units[key]
        gl = g.create_group("generator_limits")
        gl_units = {"Pmax": "MW", "Pmin": "MW", "Qmax": "MVAr", "Qmin": "MVAr"}
        for key, arr in gen_lims.items():
            dset = gl.create_dataset(key, data=arr, compression="gzip")
            dset.attrs["units"] = gl_units[key]

    size_mb = out_path.stat().st_size / 1e6
    print(f"Wrote {out_path}  ({size_mb:.1f} MB)")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("mat", type=Path, help="input .mat file (MATLAB v7.3)")
    ap.add_argument("-o", "--out", type=Path, default=None,
                    help="output .h5 file (default: <input>_clean.h5)")
    ap.add_argument("--limit", type=int, default=None,
                    help="convert only the first N samples (for a quick test)")
    args = ap.parse_args()

    if not args.mat.exists():
        sys.exit(f"Input not found: {args.mat}")
    out = args.out or args.mat.with_name(args.mat.stem + "_clean.h5")
    convert(args.mat, out, args.limit)


if __name__ == "__main__":
    main()
