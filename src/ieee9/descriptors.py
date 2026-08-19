"""Quantitative dataset descriptors -> CSV + LaTeX tables.

Covers the descriptors a dataset paper is expected to report:
  * Mean / std / min / max of major features
  * Fault-location frequencies
  * Load-scaling and generation-scaling distributions
  * Trajectory duration statistics
  * Distribution of stability margins
  * Data-quality / caveats summary (convergence, violations, class balance)
"""

from __future__ import annotations

import re

import numpy as np
import pandas as pd

from . import TAB_DIR as _TAB_BASE, case_subdir

# Output directory for tables; switch to a case-specific subfolder via
# ``set_case``. Defaults to the package-level tables folder.
TAB_DIR = _TAB_BASE


def set_case(case_name) -> None:
    """Route table outputs into ``outputs/tables/<case_name>/``."""
    global TAB_DIR
    TAB_DIR = case_subdir(_TAB_BASE, case_name) if case_name else _TAB_BASE

# Features summarised in the "major features" table (label -> column).
# Only columns verified to be populated and variable in the dataset are listed.
MAJOR_FEATURES = {
    "TSI (stability index)": "tsi",
    "Fault duration [s]": "fault_duration",
    "Fault clearing time [s]": "fault_clearTime",
    "Time to loss of sync [s]": "time2LossSync",
    "Load scaling factor": "load_scale",
    "Generation scaling factor": "gen_scale",
    "Total load [MW]": "totalLoad",
    "Total generation [MW]": "totalGeneration",
    "Generator stress": "idx_stress_generator",
    "Global stress": "idx_stress_global",
    "Voltage stress": "idx_stress_voltage",
    "Voltage margin (min)": "idx_voltageMargin_min",
    "Active loss [MW]": "idx_loss_active",
    "Loss ratio [pu]": "idx_loss_pu",
    "Reactive loss [MVAr]": "idx_loss_reactive",
    "Mean bus voltage [pu]": "idx_vstat_mean",
    "Bus voltage std [pu]": "idx_vstat_std",
    "Min bus voltage [pu]": "val_minVoltage",
    "Max bus voltage [pu]": "val_maxVoltage",
    "Power-balance error": "val_powerBalanceError",
}

# Fields present in the .mat but not populated (all-zero / NaN placeholders).
# Reported as a known caveat rather than as meaningful descriptors.
EMPTY_FIELDS = [
    "indices.inertia (NaN)", "indices.kineticEnergy", "indices.shortCircuitLevel",
    "indices.maxOmegaDeviation", "indices.lineLoading", "validation.lineLoadingMax",
    "fault.criticalityIndex",
]


def _write(df: pd.DataFrame, name: str, float_fmt: str = "%.4g") -> None:
    TAB_DIR.mkdir(parents=True, exist_ok=True)
    df.to_csv(TAB_DIR / f"{name}.csv", index=True)
    try:
        (TAB_DIR / f"{name}.tex").write_text(
            df.to_latex(float_format=float_fmt, escape=True), encoding="utf-8"
        )
    except Exception as exc:  # LaTeX export is best-effort
        print(f"  (latex skip for {name}: {exc})")


def major_feature_stats(df: pd.DataFrame) -> pd.DataFrame:
    rows = {}
    for label, col in MAJOR_FEATURES.items():
        if col not in df:
            continue
        s = pd.to_numeric(df[col], errors="coerce").dropna()
        rows[label] = {
            "count": int(s.size),
            "mean": s.mean(),
            "std": s.std(),
            "min": s.min(),
            "p25": s.quantile(0.25),
            "median": s.median(),
            "p75": s.quantile(0.75),
            "max": s.max(),
        }
    out = pd.DataFrame(rows).T
    _write(out, "01_major_feature_stats")
    return out


def fault_location_frequencies(df: pd.DataFrame) -> dict:
    tables = {}

    kind = df["fault_kind"].value_counts().rename_axis("fault_kind").to_frame("count")
    kind["fraction"] = kind["count"] / kind["count"].sum()
    _write(kind, "02a_fault_kind_frequency")
    tables["kind"] = kind

    line = df["fault_line"].astype("Int64").value_counts().sort_index()
    line = line.rename_axis("fault_line").to_frame("count")
    line["fraction"] = line["count"] / line["count"].sum()
    _write(line, "02b_fault_line_frequency")
    tables["line"] = line

    # Bus pairs (line faults) and single bus (bus faults).
    pair = (
        df.assign(
            pair=df.apply(
                lambda r: (
                    f"{int(r.fault_bus_from)}-{int(r.fault_bus_to)}"
                    if np.isfinite(r.fault_bus_to)
                    else (f"bus{int(r.fault_bus_from)}" if np.isfinite(r.fault_bus_from) else "NA")
                ),
                axis=1,
            )
        )["pair"]
        .value_counts()
        .rename_axis("fault_target")
        .to_frame("count")
    )
    pair["fraction"] = pair["count"] / pair["count"].sum()
    _write(pair, "02c_fault_target_frequency")
    tables["target"] = pair

    pos = df.loc[df["fault_kind"] == "line", "fault_location"].dropna()
    pos_tab = pos.value_counts().sort_index().rename_axis("position_along_line").to_frame("count")
    _write(pos_tab, "02d_fault_position_frequency")
    tables["position"] = pos_tab

    return tables


def _dist_stats(s: pd.Series, name: str) -> pd.DataFrame:
    s = pd.to_numeric(s, errors="coerce").dropna()
    out = pd.DataFrame(
        {
            name: {
                "count": int(s.size),
                "mean": s.mean(),
                "std": s.std(),
                "min": s.min(),
                "p05": s.quantile(0.05),
                "p25": s.quantile(0.25),
                "median": s.median(),
                "p75": s.quantile(0.75),
                "p95": s.quantile(0.95),
                "max": s.max(),
            }
        }
    ).T
    return out


def scaling_distributions(df: pd.DataFrame) -> pd.DataFrame:
    parts = [
        _dist_stats(df["load_scale"], "load_scale (totalLoad/totalLoad0)"),
        _dist_stats(df["loadVariation"], "loadVariation"),
        _dist_stats(df["gen_scale"], "gen_scale (totalGen/totalGen0)"),
        _dist_stats(df["generationVariation"], "generationVariation"),
    ]
    out = pd.concat(parts)
    _write(out, "03_scaling_distributions")
    return out


def trajectory_duration_stats(df: pd.DataFrame) -> pd.DataFrame:
    parts = [
        _dist_stats(df["traj_duration"], "sim window [s]"),
        _dist_stats(df["fault_duration"], "fault duration [s]"),
        _dist_stats(df["fault_clearTime"], "fault clearing time [s]"),
        _dist_stats(df.loc[~df["stable"].astype(bool), "time2LossSync"], "time2LossSync (unstable) [s]"),
    ]
    out = pd.concat(parts)
    out["n_time_points"] = df["traj_n_points"].mode().iloc[0]
    _write(out, "04_trajectory_duration_stats")
    return out


def stability_margin_distribution(df: pd.DataFrame) -> pd.DataFrame:
    parts = [
        _dist_stats(df["tsi"], "TSI (all)"),
        _dist_stats(df.loc[df["stable"].astype(bool), "tsi"], "TSI (stable)"),
        _dist_stats(df.loc[~df["stable"].astype(bool), "tsi"], "TSI (unstable)"),
        _dist_stats(df["idx_voltageMargin_min"], "voltage margin (min)"),
        _dist_stats(df["idx_stress_global"], "global stress"),
    ]
    out = pd.concat(parts)
    _write(out, "05_stability_margin_distribution")
    return out


def data_quality_summary(df: pd.DataFrame, meta: dict) -> pd.DataFrame:
    n = len(df)
    stable = df["stable"].astype(bool)
    line_pos = df.loc[df["fault_kind"] == "line", "fault_location"].dropna().unique()
    rows = {
        "total samples": n,
        "stable count": int(stable.sum()),
        "unstable count": int((~stable).sum()),
        "stable fraction": stable.mean(),
        "unstable fraction": (~stable).mean(),
        "power-flow converged fraction": pd.to_numeric(df["val_converged"], errors="coerce").mean(),
        "transient success fraction": pd.to_numeric(df["transient_success"], errors="coerce").mean(),
        "reactive-limit violation fraction": (pd.to_numeric(df["val_reactiveLimitViolation"], errors="coerce") > 0).mean(),
        "mean |power-balance error|": pd.to_numeric(df["val_powerBalanceError"], errors="coerce").abs().mean(),
        "min bus voltage over dataset [pu]": pd.to_numeric(df["val_minVoltage"], errors="coerce").min(),
        "max bus voltage over dataset [pu]": pd.to_numeric(df["val_maxVoltage"], errors="coerce").max(),
        "unique random seeds": int(df["randomSeed"].nunique()),
        "CAVEAT: stable flag = derived (TSI>0)": f"{int(stable.sum())} vs metadata {int(meta.get('stat_stable', 0))} (diff {int(stable.sum()) - int(meta.get('stat_stable', 0))})",
        "CAVEAT: empty placeholder fields": ", ".join(EMPTY_FIELDS),
        "CAVEAT: line-fault positions sampled": ", ".join(f"{p:g}" for p in sorted(line_pos)),
        "metadata stableRate": meta.get("stableRate"),
        "metadata acceptedRate": meta.get("acceptedRate"),
        "metadata borderlineRate": meta.get("borderlineRate"),
        "metadata rejectedRate": meta.get("rejectedRate"),
        "TSI threshold [deg]": meta.get("tsiThresholdDeg"),
    }
    out = pd.DataFrame({"value": rows})
    _write(out, "06_data_quality_summary")
    return out


def _gen_indices(df: pd.DataFrame, prefix: str) -> list[int]:
    """Return the sorted generator numbers for columns like ``{prefix}<n>``."""
    pat = re.compile(rf"^{re.escape(prefix)}(\d+)$")
    nums = [int(m.group(1)) for c in df.columns if (m := pat.match(c))]
    return sorted(nums)


def _gen_limit_stats(df: pd.DataFrame, val_prefix: str, max_prefix: str,
                     min_prefix: str, label: str) -> pd.DataFrame:
    """Per-generator distribution stats + capability-limit violation counts.

    The generator count is detected from the columns present, so the table
    adapts to the network size (3 machines for IEEE 9-bus, 10 for NE 39-bus).
    For each generator ``g`` this reports the output distribution of
    ``{val_prefix}{g}`` and compares every scenario against the machine's
    upper/lower limits (``{max_prefix}{g}`` / ``{min_prefix}{g}``), counting how
    often the output exceeds the max or falls below the min.
    """
    rows: dict = {}
    for g in _gen_indices(df, val_prefix):
        vcol = f"{val_prefix}{g}"
        v = pd.to_numeric(df[vcol], errors="coerce")
        n = int(v.notna().sum())
        hi = pd.to_numeric(df[f"{max_prefix}{g}"], errors="coerce") if f"{max_prefix}{g}" in df else pd.Series(np.nan, index=df.index)
        lo = pd.to_numeric(df[f"{min_prefix}{g}"], errors="coerce") if f"{min_prefix}{g}" in df else pd.Series(np.nan, index=df.index)
        n_over = int((v > hi).sum())
        n_under = int((v < lo).sum())
        rows[f"{label}{g}"] = {
            "count": n,
            "mean": v.mean(),
            "std": v.std(),
            "min": v.min(),
            "max": v.max(),
            "limit_max": float(hi.dropna().iloc[0]) if hi.notna().any() else np.nan,
            "limit_min": float(lo.dropna().iloc[0]) if lo.notna().any() else np.nan,
            "n_over_max": n_over,
            "n_under_min": n_under,
            "frac_violation": (n_over + n_under) / n if n else np.nan,
        }
    return pd.DataFrame(rows).T


def generator_pg_stats(df: pd.DataFrame) -> pd.DataFrame:
    """Per-generator active-power output Pg [MW]: stats + Pmax/Pmin violations.

    Note: the slack machine's Pmin is 0 MW, so scenarios where it absorbs power
    (Pg < 0) are counted as lower-limit "violations". The ``frac_negative``
    column reports that absorbing share explicitly.
    """
    out = _gen_limit_stats(df, "pf_Pg", "pf_Pmax", "pf_Pmin", "Pg")
    cols = [f"pf_Pg{g}" for g in _gen_indices(df, "pf_Pg")]
    out["frac_negative"] = [
        float((pd.to_numeric(df[c], errors="coerce") < 0).mean()) for c in cols
    ]
    _write(out, "07_generator_pg_stats")
    return out


def generator_qg_stats(df: pd.DataFrame) -> pd.DataFrame:
    """Per-generator reactive-power output Qg [MVAr]: stats + Qmax/Qmin violations."""
    out = _gen_limit_stats(df, "pf_Qg", "pf_Qmax", "pf_Qmin", "Qg")
    _write(out, "08_generator_qg_stats")
    return out


def build_all_tables(df: pd.DataFrame, meta: dict) -> dict:
    return {
        "major_features": major_feature_stats(df),
        "fault_location": fault_location_frequencies(df),
        "scaling": scaling_distributions(df),
        "trajectory_duration": trajectory_duration_stats(df),
        "stability_margin": stability_margin_distribution(df),
        "data_quality": data_quality_summary(df, meta),
        "generator_pg": generator_pg_stats(df),
        "generator_qg": generator_qg_stats(df),
    }
