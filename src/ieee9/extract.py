"""Extract the 10,000 per-sample structs from the MAT v7.3 file into a tidy table.

Design notes / documented caveats
----------------------------------
* The file is MATLAB v7.3 (HDF5). Numeric fields read cleanly via h5py.
* Categorical/string fields (``fault.type``, ``fault.locationType``,
  ``transient.label``, ``validation.status``) are stored as MATLAB MCOS
  objects in ``#subsystem#`` and are NOT reliably decodable in pure Python
  (each sample owns fresh, sample-local object IDs). We therefore do NOT read
  those strings; instead we *infer* the physically meaningful ones from
  numeric fields:
    - ``fault_kind`` = 'line' if ``fault.line`` > 0 else 'bus'
    - stability label ``stable`` = ``transient.label.value`` == 0, i.e. peak
      angle separation <= ``transient.label.threshold`` (180 deg). This is the
      dataset's authoritative label and reproduces ``statistics.stable`` (9762)
      exactly. (Using ``tsi`` > 0 is a 360-deg criterion and mislabels 30
      marginal cases at ~183 deg; it is not used.)
  Both inferences were validated against the dataset metadata
  (stableRate = 0.4881). This is recorded as a known caveat.
"""

from __future__ import annotations

import numpy as np
import pandas as pd
import h5py

from pathlib import Path

from . import MAT_FILE, DATA_DIR


def _num(node, key):
    """Return a flat float array for a numeric field, or empty array if absent/opaque."""
    if key not in node:
        return np.array([], dtype=float)
    a = np.asarray(node[key])
    # MCOS object references arrive as uint32 tuples with a magic first word.
    if a.dtype == np.uint32 and a.size == 6:
        return np.array([], dtype=float)
    try:
        return a.astype(float).flatten()
    except (ValueError, TypeError):
        return np.array([], dtype=float)


def _scalar(node, key):
    a = _num(node, key)
    return float(a[0]) if a.size else np.nan


def _nested(node, path):
    """Read a scalar leaf from a nested struct via 'group/leaf' path."""
    cur = node
    for part in path.split("/"):
        if part not in cur:
            return np.nan
        cur = cur[part]
    a = np.asarray(cur)
    try:
        v = a.astype(float).flatten()
        return float(v[0]) if v.size else np.nan
    except (ValueError, TypeError):
        return np.nan


def _agg(node, key):
    """Return (sum, mean, min, max) aggregates of a numeric array field."""
    a = _num(node, key)
    if not a.size:
        return (np.nan, np.nan, np.nan, np.nan)
    return (float(a.sum()), float(a.mean()), float(a.min()), float(a.max()))


def _sample_row(smp) -> dict:
    row: dict = {}

    # --- fault (location) ---
    ft = smp["fault"]
    line = _scalar(ft, "line")
    bus = _num(ft, "bus")
    row["fault_line"] = line
    row["fault_kind"] = "line" if (np.isfinite(line) and line > 0) else "bus"
    row["fault_bus_from"] = float(bus[0]) if bus.size >= 1 else np.nan
    row["fault_bus_to"] = float(bus[1]) if bus.size >= 2 else np.nan
    row["fault_location"] = _scalar(ft, "location")
    row["fault_duration"] = _scalar(ft, "duration")
    row["fault_clearTime"] = _scalar(ft, "clearTime")
    row["fault_startTime"] = _scalar(ft, "startTime")
    row["fault_criticalityIndex"] = _scalar(ft, "criticalityIndex")
    row["fault_globalLoadMean"] = _scalar(ft, "globalLoadMean")
    row["fault_globalVoltageMean"] = _scalar(ft, "globalVoltageMean")
    row["fault_globalVoltageStd"] = _scalar(ft, "globalVoltageStd")
    row["fault_localLoadLevel"] = _scalar(ft, "localLoadLevel")
    row["fault_localVoltage"] = _scalar(ft, "localVoltage")
    row["fault_genElecDistance"] = _scalar(ft, "generatorElectricalDistance")

    # --- scenario (load / generation scaling) ---
    sc = smp["scenario"]
    row["loadVariation"] = _scalar(sc, "loadVariation")
    row["generationVariation"] = _scalar(sc, "generationVariation")
    tL = _scalar(sc, "totalLoad")
    tL0 = _scalar(sc, "totalLoad0")
    tG = _scalar(sc, "totalGeneration")
    tG0 = _scalar(sc, "totalGeneration0")
    row["totalLoad"] = tL
    row["totalLoad0"] = tL0
    row["totalGeneration"] = tG
    row["totalGeneration0"] = tG0
    row["load_scale"] = tL / tL0 if tL0 not in (0, np.nan) and np.isfinite(tL0) else np.nan
    row["gen_scale"] = tG / tG0 if tG0 not in (0, np.nan) and np.isfinite(tG0) else np.nan
    row["scenario_id"] = _scalar(sc, "id")
    row["randomSeed"] = _scalar(sc, "randomSeed")

    # --- transient (stability margin + trajectory duration) ---
    tr = smp["transient"]
    tsi = _scalar(tr, "tsi")
    row["tsi"] = tsi
    # Authoritative binary label: the dataset marks a scenario UNSTABLE when the
    # peak inter-machine angle separation exceeds transient.label.threshold
    # (= 180 deg for every sample), encoded numerically in transient.label.value
    # (1 = unstable, 0 = stable). stable = (value == 0) reproduces the dataset's
    # official statistics.stable (9762) exactly. Do NOT use tsi > 0, which is a
    # 360-deg criterion and mislabels the 30 marginal cases at ~183 deg.
    label_value = _nested(tr, "label/value")
    row["label_value"] = label_value
    row["label_threshold_deg"] = _nested(tr, "label/threshold")
    row["stable"] = (label_value == 0) if np.isfinite(label_value) else np.nan
    row["time2LossSync"] = _scalar(tr, "time2LossSync")
    row["transient_success"] = _scalar(tr, "success")
    t = _num(tr, "time")
    row["traj_duration"] = float(t.max() - t.min()) if t.size else np.nan
    row["traj_n_points"] = int(t.size)
    # rotor-angle span at end of window = max separation (deg)
    delta = _num(tr, "delta")
    if delta.size:
        d = np.asarray(tr["delta"]).astype(float)
        row["delta_max_separation"] = float(d.max() - d.min())
    else:
        row["delta_max_separation"] = np.nan
    # Pre-computed physics indices (peak inter-machine separation and speed
    # deviation); these are the physically meaningful values used for the paper.
    row["delta_max_deg"] = _nested(tr, "indices/maxAngleSeparationDeg")
    row["omega_max_dev"] = _nested(tr, "indices/maxSpeedDeviation")

    # --- indices (engineered features) ---
    # Only fields verified to be populated and variable across the dataset are
    # kept. Placeholder/empty fields in the .mat (inertia=NaN, kineticEnergy,
    # shortCircuitLevel, maxOmegaDeviation, lineLoading, criticalityIndex) and
    # constant topology metrics are intentionally omitted.
    ind = smp["indices"]
    row["idx_stress_generator"] = _nested(ind, "stress/generatorStress")
    row["idx_stress_global"] = _nested(ind, "stress/globalStress")
    row["idx_stress_voltage"] = _nested(ind, "stress/voltageStress")
    row["idx_voltageMargin_min"] = _nested(ind, "voltageMargin/minimumMargin")
    row["idx_voltageMargin_max"] = _nested(ind, "voltageMargin/maximumMargin")
    row["idx_voltageMargin_avg"] = _nested(ind, "voltageMargin/averageDeviation")
    row["idx_vstat_min"] = _nested(ind, "voltageStats/minVoltage")
    row["idx_vstat_mean"] = _nested(ind, "voltageStats/meanVoltage")
    row["idx_vstat_std"] = _nested(ind, "voltageStats/stdVoltage")
    row["idx_loss_active"] = _nested(ind, "lossRatio/activeLoss")
    row["idx_loss_pu"] = _nested(ind, "lossRatio/lossratio_pu")
    row["idx_loss_reactive"] = _nested(ind, "lossRatio/reactiveLoss")
    row["idx_networkDensity"] = _scalar(ind, "networkDensity")
    row["idx_numberBuses"] = _scalar(ind, "numberBuses")
    row["idx_numberGenerators"] = _scalar(ind, "numberGenerators")

    # --- validation (data quality) ---
    va = smp["validation"]
    row["val_converged"] = _scalar(va, "converged")
    row["val_minVoltage"] = _scalar(va, "minVoltage")
    row["val_maxVoltage"] = _scalar(va, "maxVoltage")
    row["val_lineLoadingMax"] = _scalar(va, "lineLoadingMax")
    row["val_powerBalanceError"] = _scalar(va, "powerBalanceError")
    row["val_reactiveLimitViolation"] = _scalar(va, "reactiveLimitViolation")

    # Steady-state screening status. The authoritative flag lives in the
    # un-decodable MCOS field ``validation.status``; we reconstruct it from the
    # minimum bus voltage. The threshold 0.94 pu reproduces the dataset's
    # accepted/borderline counts (758 / 9242) exactly.
    minv = row["val_minVoltage"]
    row["screening_status"] = (
        "accepted" if (np.isfinite(minv) and minv >= 0.94) else "borderline"
    )

    # Fault-location label: BUS<n> for bus faults, LINE<n> for line faults.
    if row["fault_kind"] == "line" and np.isfinite(line):
        row["fault_location_label"] = f"LINE{int(line)}"
    elif np.isfinite(row["fault_bus_from"]):
        row["fault_location_label"] = f"BUS{int(row['fault_bus_from'])}"
    else:
        row["fault_location_label"] = "NA"

    # --- power flow aggregates ---
    pf = smp["powerFlow"]
    row["pf_totalPg"], row["pf_meanPg"], _, _ = _agg(pf, "Pg")
    row["pf_totalPd"], row["pf_meanPd"], _, _ = _agg(pf, "Pd")
    row["pf_totalQg"], _, _, _ = _agg(pf, "Qg")
    row["pf_totalQd"], _, _, _ = _agg(pf, "Qd")
    _, row["pf_meanV"], row["pf_minV"], row["pf_maxV"] = _agg(pf, "V")

    # Per-generator active power output Pg [MW]. The generator count is read
    # from the data (IEEE 9-bus: 3 machines; NE 39-bus: 10), so the table
    # adapts to whatever network the .mat describes.
    pg = _num(pf, "Pg")
    qg = _num(pf, "Qg")
    n_gen = int(pg.size)
    for g in range(n_gen):
        row[f"pf_Pg{g + 1}"] = float(pg[g])

    # Per-generator reactive power output Qg [MVAr].
    for g in range(n_gen):
        row[f"pf_Qg{g + 1}"] = float(qg[g]) if qg.size > g else np.nan

    # Generator capability limits from the MATPOWER case matrix ``mpc.gen``.
    # Stored transposed (HDF5) as (nColumns=21, nGen); MATPOWER gen columns
    # (1-indexed): 4=QMAX, 5=QMIN, 9=PMAX, 10=PMIN. Read per sample and per
    # generator so it scales with the network size; used downstream to flag
    # limit violations.
    try:
        gm = np.asarray(smp["mpc"]["gen"]).astype(float)
    except (KeyError, ValueError, TypeError):
        gm = None
    for g in range(n_gen):
        if gm is not None and gm.ndim == 2 and gm.shape[0] > 9 and gm.shape[1] > g:
            row[f"pf_Qmax{g + 1}"] = float(gm[3, g])
            row[f"pf_Qmin{g + 1}"] = float(gm[4, g])
            row[f"pf_Pmax{g + 1}"] = float(gm[8, g])
            row[f"pf_Pmin{g + 1}"] = float(gm[9, g])
        else:
            row[f"pf_Qmax{g + 1}"] = np.nan
            row[f"pf_Qmin{g + 1}"] = np.nan
            row[f"pf_Pmax{g + 1}"] = np.nan
            row[f"pf_Pmin{g + 1}"] = np.nan

    return row


def extract(force: bool = False, mat_file=None) -> pd.DataFrame:
    """Read all samples into a DataFrame and cache to parquet. Returns the DataFrame.

    Parameters
    ----------
    force : bool
        If True, always re-read the .mat and overwrite the parquet cache.
        If False (default), reuse the cached parquet when it exists AND is
        newer than the .mat; a stale cache (older .mat was replaced) triggers
        an automatic re-extraction.
    mat_file : str | Path | None
        Path to the source .mat file. Defaults to the package-level MAT_FILE
        (``case_IEEE9BusSystem_dataset.mat`` at the project root).
    """
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    src = Path(mat_file) if mat_file is not None else MAT_FILE

    if not src.exists():
        raise FileNotFoundError(f"Dataset not found: {src}")

    # Cache path mirrors the source dataset name: <dataset>_flat.parquet.
    # (Different datasets therefore get their own cache instead of colliding.)
    parquet = DATA_DIR / f"{src.stem}_flat.parquet"

    # Reuse the cache only if it exists and is at least as new as the source.
    if parquet.exists() and not force:
        cache_is_fresh = parquet.stat().st_mtime >= src.stat().st_mtime
        if cache_is_fresh:
            return pd.read_parquet(parquet)
        print(f"Cache is older than {src.name}; re-extracting.")

    rows = []
    with h5py.File(src, "r") as f:
        samples = f["dataset/samples"]
        n = samples.shape[0]
        for i in range(n):
            smp = f[samples[i, 0]]
            rows.append(_sample_row(smp))
            if (i + 1) % 1000 == 0:
                print(f"  extracted {i + 1}/{n}")

    df = pd.DataFrame(rows)
    df.to_parquet(parquet, index=False)
    print(f"Wrote {len(df)} rows -> {parquet}")
    return df


if __name__ == "__main__":
    extract(force=True)
