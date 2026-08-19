# IEEE 9-Bus Transient-Stability Dataset

A dataset of **20,000** transient-stability simulations on the IEEE 9-bus
system (3 generators, 9 buses, 9 branches). Each scenario contains a
steady-state operating point, a fault definition, the full rotor-angle and
speed trajectories, a stability label, and a set of engineered features.
https://ieee-dataport.org/documents/20000-scenario-graph-dataset-full-generator-trajectories-transient-stability-assessment

| Property | Value |
| --- | --- |
| Scenarios | 20,000 |
| Generators / Buses / Branches | 3 / 9 / 9 |
| Trajectory length | 181 time steps |
| Stable / Unstable | 9,762 / 10,238 |
| File | `case_IEEE9BusSystem_dataset.mat` (MATLAB v7.3 = HDF5) |

## Contents

| File | Description |
| --- | --- |
| `case_IEEE9BusSystem_dataset.mat` | The dataset (MATLAB v7.3 / HDF5). |
| `INSTRUCTIONS_IEEE_DataPort.txt` | Full field-by-field reference and caveats. |
| `convert_mat_to_hdf5.py` | Export a clean, flat, portable HDF5 file. |
| `explore_dataset.py` | Print a summary or plot a single scenario. |

## Quick start

```bash
pip install numpy h5py            # matplotlib optional, for plotting

# Export a clean, flat HDF5 (all 20,000 scenarios)
python convert_mat_to_hdf5.py case_IEEE9BusSystem_dataset.mat -o clean.h5

# Summarize the dataset
python explore_dataset.py clean.h5

# Plot the rotor-angle / speed trajectory of scenario 0
python explore_dataset.py clean.h5 --plot 0
```

Read a single value directly from the raw file with h5py:

```python
import h5py, numpy as np

with h5py.File("case_IEEE9BusSystem_dataset.mat", "r") as f:
    samples = f["dataset/samples"]        # (20000, 1) object references
    smp = f[samples[0, 0]]                # dereference scenario 0
    tsi = float(np.asarray(smp["transient"]["tsi"]).flatten()[0])
    delta = np.asarray(smp["transient"]["delta"])   # (3, 181) radians
```

## File format

The `.mat` file is saved in MATLAB **v7.3** format, which *is* an HDF5
container, so it opens without MATLAB using any HDF5 library. Note that:

- scenarios are stored as an `(N, 1)` array of HDF5 **object references** (one
  MATLAB struct each) — you must dereference to reach the fields;
- numeric scalars are wrapped as `1x1` matrices;
- text fields (fault type, label text, timestamps) are MATLAB **MCOS** objects
  and are **not** readable outside MATLAB — but every text field has a numeric
  equivalent, so nothing needed for analysis is lost.

Running `convert_mat_to_hdf5.py` produces a clean file that avoids all three:

```
/                        attrs: case_name, n_samples, n_generators, n_buses, n_time
/metadata                dataset rates
/statistics              dataset counts
/scalars/<name>          each per-scenario scalar as an (N,) array
/scalars/stable          1 = stable, 0 = unstable
/trajectories/delta      (N, 3, 181)  rotor angle [rad, absolute]
/trajectories/omega      (N, 3, 181)  speed [pu]
/trajectories/time       (181,)       [s]
/powerflow/{Pg,Qg,Pd,Qd,V,theta}      (N, ...)
/generator_limits/{Pmax,Pmin,Qmax,Qmin}  (N, 3)
```

## Stability label — read this first

The authoritative binary label is the **numeric** field
`transient.label.value` (`1 = unstable`, `0 = stable`). A scenario is unstable
when the peak inter-machine angle separation exceeds `transient.label.threshold`
= **180°**. This reproduces `statistics.stable = 9762` exactly and is fully
readable in Python.

Do **not** infer the label from `sign(transient.tsi)`: `tsi > 0` gives 9,792
"stable", 30 more than the authoritative label (those 30 cases peak at ~183°,
unstable under 180° but stable under a naive 360°/TSI test). Always use
`transient.label.value` (or `/scalars/stable` in the clean file).

## Data caveats

- **`delta` is in radians and absolute** — it includes the common synchronous
  ramp. For meaningful inter-machine separation, subtract the per-time-step
  generator mean (centre of inertia) and convert to degrees:
  `sep = (delta - delta.mean(axis=0)) * 180/pi`. The precomputed
  `transient.indices.maxAngleSeparationDeg` already gives its peak.
- **`omega`** is per-unit (nominal 1.0); use `|omega - 1|`.
- **`time2LossSync`** is measured relative to the fault-**clearing** instant
  (negative = synchronism lost before clearing).
- Some engineered feature fields are `0` placeholders for this configuration —
  verify a field is populated before relying on it.

See `INSTRUCTIONS_IEEE_DataPort.txt` for the complete field-by-field reference.

## Requirements

- Python 3.9+
- `numpy`, `h5py`
- `matplotlib` (optional, only for `--plot`)

## License and citation

License: _[MIT License]_

```
Hussein Suprême, Martin de Montigny, Arnaud Zinflou, "IEEE 9-Bus Transient-Stability Dataset", IEEE DataPort, 2026.
DOI: 10.21227/d10j-5b27.
```
