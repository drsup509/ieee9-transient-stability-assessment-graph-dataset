"""Figures (300 dpi PNG + vector PDF) for each dataset descriptor."""

from __future__ import annotations

import numpy as np
import pandas as pd
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt

from . import FIG_DIR as _FIG_BASE, case_subdir

# Output directory for figures; switch to a case-specific subfolder via
# ``set_case``. Defaults to the package-level figures folder.
FIG_DIR = _FIG_BASE


def set_case(case_name) -> None:
    """Route figure outputs into ``outputs/figures/<case_name>/``."""
    global FIG_DIR
    FIG_DIR = case_subdir(_FIG_BASE, case_name) if case_name else _FIG_BASE

plt.rcParams.update({
    "figure.dpi": 120,
    "savefig.dpi": 300,
    "font.size": 14,
    "axes.grid": True,
    "grid.alpha": 0.3,
    "axes.axisbelow": True,
})

STABLE_C = "#2c7fb8"
UNSTABLE_C = "#d95f0e"

# Classical first-swing stability limit. This is the dataset's actual decision
# boundary: a scenario is labelled unstable when the peak inter-machine angle
# separation exceeds this value (transient.label.threshold = 180 deg). It is the
# same criterion used for the ``stable`` column, so on the physics panels every
# stable point lies below this line and every unstable point above it.
FIRST_SWING_LIMIT_DEG = 180.0


def _save(fig, name: str) -> None:
    FIG_DIR.mkdir(parents=True, exist_ok=True)
    fig.tight_layout()
    fig.savefig(FIG_DIR / f"{name}.png", bbox_inches="tight")
    fig.savefig(FIG_DIR / f"{name}.pdf", bbox_inches="tight")
    plt.close(fig)


def _save_pdf_svg(fig, name: str) -> None:
    FIG_DIR.mkdir(parents=True, exist_ok=True)
    fig.tight_layout()
    fig.savefig(FIG_DIR / f"{name}.pdf", bbox_inches="tight")
    fig.savefig(FIG_DIR / f"{name}.svg", bbox_inches="tight")
    plt.close(fig)


def fig_major_features(df: pd.DataFrame) -> None:
    cols = [
        ("tsi", "TSI"), ("fault_duration", "Fault duration [s]"),
        ("load_scale", "Load scale"), ("gen_scale", "Generation scale"),
        ("idx_stress_generator", "Generator stress"), ("idx_stress_global", "Global stress"),
        ("idx_loss_active", "Active loss [MW]"), ("idx_loss_pu", "Loss ratio [pu]"),
        ("idx_voltageMargin_min", "Voltage margin (min)"), ("val_minVoltage", "Min voltage [pu]"),
        ("idx_vstat_mean", "Mean voltage [pu]"), ("val_powerBalanceError", "Power-balance error"),
    ]
    cols = [(c, l) for c, l in cols if c in df]
    ncol = 3
    nrow = int(np.ceil(len(cols) / ncol))
    fig, axes = plt.subplots(nrow, ncol, figsize=(11, 2.6 * nrow))
    for ax, (c, lbl) in zip(axes.flat, cols):
        s = pd.to_numeric(df[c], errors="coerce").dropna()
        ax.hist(s, bins=40, color="#4a4a4a", alpha=0.85)
        ax.set_title(lbl, fontsize=9)
        ax.axvline(s.mean(), color="crimson", lw=1.2, ls="--")
    for ax in axes.flat[len(cols):]:
        ax.axis("off")
    fig.suptitle("Distributions of major dataset features (dashed = mean)", y=1.01)
    _save(fig, "fig01_major_features")


def fig_fault_location(df: pd.DataFrame) -> None:
    fig, axes = plt.subplots(2, 2, figsize=(11, 8))

    # (a) kind
    k = df["fault_kind"].value_counts()
    axes[0, 0].bar(k.index, k.values, color=["#2c7fb8", "#d95f0e"])
    axes[0, 0].set_title("(a) Fault kind")
    axes[0, 0].set_ylabel("count")

    # (b) per line
    line = df.loc[df["fault_kind"] == "line", "fault_line"].astype(int).value_counts().sort_index()
    axes[0, 1].bar(line.index.astype(str), line.values, color="#4a4a4a")
    axes[0, 1].set_title("(b) Line faults per line index")
    axes[0, 1].set_xlabel("line index")
    axes[0, 1].set_ylabel("count")

    # (c) target (bus pair / bus)
    def _tgt(r):
        if np.isfinite(r.fault_bus_to):
            return f"{int(r.fault_bus_from)}-{int(r.fault_bus_to)}"
        if np.isfinite(r.fault_bus_from):
            return f"bus{int(r.fault_bus_from)}"
        return "NA"

    tgt = df.apply(_tgt, axis=1).value_counts().sort_values(ascending=False)
    axes[1, 0].barh(tgt.index[::-1], tgt.values[::-1], color="#4a4a4a")
    axes[1, 0].set_title("(c) Fault target frequency")
    axes[1, 0].set_xlabel("count")

    # (d) position along line
    pos = df.loc[df["fault_kind"] == "line", "fault_location"].dropna()
    axes[1, 1].hist(pos, bins=20, color="#2c7fb8")
    axes[1, 1].set_title("(d) Fault position along line")
    axes[1, 1].set_xlabel("normalized position (0=from, 1=to)")
    axes[1, 1].set_ylabel("count")

    fig.suptitle("Fault-location frequencies", y=1.01)
    _save(fig, "fig02_fault_location")


def fig_scaling(df: pd.DataFrame) -> None:
    stable = df["stable"].astype(bool)
    fig, axes = plt.subplots(2, 2, figsize=(11, 8))

    axes[0, 0].hist([df.loc[stable, "load_scale"], df.loc[~stable, "load_scale"]],
                    bins=40, stacked=True, color=[STABLE_C, UNSTABLE_C],
                    label=["stable", "unstable"])
    axes[0, 0].set_title("(a) Load scaling")
    axes[0, 0].set_xlabel("totalLoad / totalLoad0")
    axes[0, 0].legend()

    axes[0, 1].hist([df.loc[stable, "gen_scale"], df.loc[~stable, "gen_scale"]],
                    bins=40, stacked=True, color=[STABLE_C, UNSTABLE_C],
                    label=["stable", "unstable"])
    axes[0, 1].set_title("(b) Generation scaling")
    axes[0, 1].set_xlabel("totalGen / totalGen0")
    axes[0, 1].legend()

    hb = axes[1, 0].hexbin(df["load_scale"], df["gen_scale"], gridsize=35, cmap="viridis", mincnt=1)
    axes[1, 0].set_title("(c) Load vs generation scaling")
    axes[1, 0].set_xlabel("load scale")
    axes[1, 0].set_ylabel("generation scale")
    fig.colorbar(hb, ax=axes[1, 0], label="count")

    axes[1, 1].scatter(df.loc[stable, "load_scale"], df.loc[stable, "gen_scale"],
                       s=4, alpha=0.3, color=STABLE_C, label="stable")
    axes[1, 1].scatter(df.loc[~stable, "load_scale"], df.loc[~stable, "gen_scale"],
                       s=4, alpha=0.3, color=UNSTABLE_C, label="unstable")
    axes[1, 1].set_title("(d) Scaling by stability outcome")
    axes[1, 1].set_xlabel("load scale")
    axes[1, 1].set_ylabel("generation scale")
    axes[1, 1].legend()

    fig.suptitle("Load- and generation-scaling distributions", y=1.01)
    _save(fig, "fig03_scaling_distributions")


def fig_trajectory_duration(df: pd.DataFrame) -> None:
    stable = df["stable"].astype(bool)
    fig, axes = plt.subplots(1, 3, figsize=(13, 3.6))

    axes[0].hist(df["fault_duration"].dropna(), bins=40, color="#4a4a4a")
    axes[0].set_title("Fault duration")
    axes[0].set_xlabel("[s]")

    axes[1].hist(df["fault_clearTime"].dropna(), bins=40, color="#4a4a4a")
    axes[1].set_title("Fault clearing time")
    axes[1].set_xlabel("[s]")

    t2 = df.loc[~stable, "time2LossSync"].dropna()
    axes[2].hist(t2, bins=40, color=UNSTABLE_C)
    axes[2].set_title("Time to loss of synchronism (unstable)")
    axes[2].set_xlabel("[s]")

    win = df["traj_duration"].mode().iloc[0]
    npts = int(df["traj_n_points"].mode().iloc[0])
    fig.suptitle(f"Trajectory duration statistics  (fixed sim window = {win:g} s, {npts} points)", y=1.03)
    _save(fig, "fig04_trajectory_duration")


def fig_stability_margin(df: pd.DataFrame) -> None:
    stable = df["stable"].astype(bool)
    fig, axes = plt.subplots(1, 2, figsize=(11, 4))

    axes[0].hist([df.loc[stable, "tsi"], df.loc[~stable, "tsi"]],
                 bins=50, stacked=True, color=[STABLE_C, UNSTABLE_C],
                 label=["stable (TSI>0)", "unstable (TSI<=0)"])
    axes[0].axvline(0, color="k", lw=1.2, ls="--")
    axes[0].set_title("(a) Transient Stability Index (TSI)")
    axes[0].set_xlabel("TSI")
    axes[0].set_ylabel("count")
    axes[0].legend()

    vm = pd.to_numeric(df["idx_voltageMargin_min"], errors="coerce").dropna()
    axes[1].hist(vm, bins=50, color="#31a354")
    axes[1].set_title("(b) Voltage margin (minimum)")
    axes[1].set_xlabel("voltage margin [pu]")
    axes[1].set_ylabel("count")

    fig.suptitle("Distribution of stability margins", y=1.02)
    _save(fig, "fig05_stability_margins")


def fig_data_quality(df: pd.DataFrame) -> None:
    stable = df["stable"].astype(bool)
    fig, axes = plt.subplots(1, 2, figsize=(11, 4))

    counts = [int(stable.sum()), int((~stable).sum())]
    axes[0].bar(["stable", "unstable"], counts, color=[STABLE_C, UNSTABLE_C])
    for i, c in enumerate(counts):
        axes[0].text(i, c, f"{c}\n({c/len(df)*100:.1f}%)", ha="center", va="bottom", fontsize=9)
    axes[0].set_title("(a) Class balance")
    axes[0].set_ylabel("count")

    # correlation heatmap of core features
    feats = ["tsi", "load_scale", "gen_scale", "fault_duration", "idx_stress_generator",
             "idx_stress_global", "idx_loss_active", "idx_voltageMargin_min", "idx_vstat_std"]
    feats = [c for c in feats if c in df]
    corr = df[feats].apply(pd.to_numeric, errors="coerce").corr()
    im = axes[1].imshow(corr, cmap="RdBu_r", vmin=-1, vmax=1)
    axes[1].set_xticks(range(len(feats)))
    axes[1].set_xticklabels([f.replace("idx_", "") for f in feats], rotation=90, fontsize=8)
    axes[1].set_yticks(range(len(feats)))
    axes[1].set_yticklabels([f.replace("idx_", "") for f in feats], fontsize=8)
    axes[1].set_title("(b) Feature correlation")
    axes[1].grid(False)
    fig.colorbar(im, ax=axes[1], label="Pearson r")

    fig.suptitle("Data-quality overview", y=1.02)
    _save(fig, "fig06_data_quality")


def build_all_figures(df: pd.DataFrame, meta: dict | None = None) -> None:
    fig_major_features(df)
    fig_fault_location(df)
    fig_scaling(df)
    fig_trajectory_duration(df)
    fig_stability_margin(df)
    fig_data_quality(df)
    fig_scaling_loss_margin(df)
    fig_outcome_time2loss(df)
    fig_scaling_loss_stab(df)
    fig_screening_and_faultrate(df, meta)
    fig_generator_pg(df)
    fig_physics_panels(df, meta)


def fig_scaling_loss_margin(df: pd.DataFrame) -> None:
    """2x2: load scale, generation scale, loss ratio, voltage margin (min & max)."""
    fig, axes = plt.subplots(2, 2, figsize=(11, 8))

    axes[0, 0].hist(pd.to_numeric(df["load_scale"], errors="coerce").dropna(),
                    bins=40, color=STABLE_C)
    axes[0, 0].set_title("(a) Load scale")
    axes[0, 0].set_xlabel("totalLoad / totalLoad0")
    axes[0, 0].set_ylabel("count")

    axes[0, 1].hist(pd.to_numeric(df["gen_scale"], errors="coerce").dropna(),
                    bins=40, color=STABLE_C)
    axes[0, 1].set_title("(b) Generation scale")
    axes[0, 1].set_xlabel("totalGen / totalGen0")
    axes[0, 1].set_ylabel("count")

    axes[1, 0].hist(pd.to_numeric(df["idx_loss_pu"], errors="coerce").dropna(),
                    bins=40, color="#756bb1")
    axes[1, 0].set_title("(c) Loss ratio")
    axes[1, 0].set_xlabel("loss ratio [pu]")
    axes[1, 0].set_ylabel("count")

    vmin = pd.to_numeric(df["idx_voltageMargin_min"], errors="coerce").dropna()
    vmax = pd.to_numeric(df["idx_voltageMargin_max"], errors="coerce").dropna()
    axes[1, 1].hist(vmin, bins=40, color="#31a354", alpha=0.85, label="minimum margin")
    if vmax.round(6).nunique() == 1:
        # Maximum margin is a constant placeholder in the dataset; show as a line.
        axes[1, 1].axvline(vmax.iloc[0], color="#d95f0e", lw=2, ls="--",
                           label=f"maximum margin = {vmax.iloc[0]:.3g} (constant)")
    else:
        axes[1, 1].hist(vmax, bins=40, color="#d95f0e", alpha=0.75, label="maximum margin")
    axes[1, 1].set_title("(d) Voltage margin (min & max)")
    axes[1, 1].set_xlabel("voltage margin [pu]")
    axes[1, 1].set_ylabel("count")
    axes[1, 1].legend()

    fig.suptitle("Scaling, loss ratio and voltage-margin distributions", y=1.01)
    _save_pdf_svg(fig, "fig07_scaling_loss_margin")


def fig_outcome_time2loss(df: pd.DataFrame) -> None:
    """1x2: scaling by stability outcome, time to loss of synchronism."""
    stable = df["stable"].astype(bool)
    fig, axes = plt.subplots(1, 2, figsize=(11, 4))

    axes[0].scatter(df.loc[stable, "load_scale"], df.loc[stable, "gen_scale"],
                    s=4, alpha=0.3, color=STABLE_C, label="stable")
    axes[0].scatter(df.loc[~stable, "load_scale"], df.loc[~stable, "gen_scale"],
                    s=4, alpha=0.3, color=UNSTABLE_C, label="unstable")
    axes[0].set_title("(a) Scaling by stability outcome")
    axes[0].set_xlabel("load scale")
    axes[0].set_ylabel("generation scale")
    axes[0].legend()

    t2 = df.loc[~stable, "time2LossSync"].dropna()
    axes[1].hist(t2, bins=40, color=UNSTABLE_C)
    axes[1].set_title("(b) Time to loss of synchronism (unstable)")
    axes[1].set_xlabel("[s]")
    axes[1].set_ylabel("count")

    _save_pdf_svg(fig, "fig08_outcome_time2loss")


def fig_scaling_loss_stab(df: pd.DataFrame) -> None:
    """2x2: load scale, loss ratio, generation scale, scaling by stability outcome."""
    fig, axes = plt.subplots(2, 2, figsize=(11, 8))

    axes[0, 0].hist(pd.to_numeric(df["load_scale"], errors="coerce").dropna(),
                    bins=40, color=STABLE_C)
    axes[0, 0].set_title("(a)") # Load scale
    axes[0, 0].set_xlabel("totalLoad / totalLoad0")
    axes[0, 0].set_ylabel("count")

    axes[1, 0].hist(pd.to_numeric(df["gen_scale"], errors="coerce").dropna(),
                    bins=40, color=STABLE_C)
    axes[1, 0].set_title("(b)") # Generation scale
    axes[1, 0].set_xlabel("totalGen / totalGen0")
    axes[1, 0].set_ylabel("count")

    axes[0, 1].hist(pd.to_numeric(df["idx_loss_pu"], errors="coerce").dropna(),
                    bins=40, color="#756bb1")
    axes[0, 1].set_title("(c)") # Loss ratio
    axes[0, 1].set_xlabel("loss ratio [pu]")
    axes[0, 1].set_ylabel("count")

    stable = df["stable"].astype(bool)
    axes[1,1].scatter(df.loc[stable, "load_scale"], df.loc[stable, "gen_scale"],
                        s=4, alpha=0.3, color=STABLE_C, label="stable")
    axes[1,1].scatter(df.loc[~stable, "load_scale"], df.loc[~stable, "gen_scale"],
                        s=4, alpha=0.3, color=UNSTABLE_C, label="unstable")
    axes[1,1].set_title("(d)") # Scaling by stability outcome
    axes[1,1].set_xlabel("load scale")
    axes[1,1].set_ylabel("generation scale")
    axes[1,1].legend()

    # fig.suptitle("Scaling, loss ratio and stability outcome", y=1.01)
    _save_pdf_svg(fig, "fig09_scaling_loss_stab")


# Colours matching the attached reference figure.
STABLE_G = "#2e9e3a"
UNSTABLE_R = "#c0392b"


def fig_screening_and_faultrate(df: pd.DataFrame, meta: dict | None = None) -> None:
    """Composition cross-checks (reference FIGURE 3 style).

    (a) Steady-state screening status grouped by the transient stability label
        (stable / unstable). When ``meta`` is provided and the case has rejected
        scenarios, a third REJECTED bar is added from the dataset metadata. This
        count is authoritative (the reconstructed per-row ``screening_status``
        only yields accepted/borderline), and rejected scenarios carry NO
        stable/unstable label, so no split is drawn for them.
    (b) Per-fault-location unstable rate. The fault locations shown are the
        REAL ones present in the dataset (derived from the data, not assumed),
        so this adapts to the network: BUS1..BUS9 / LINE1..LINE9 for the IEEE
        9-bus case, and the full set of buses and lines actually faulted for
        the NE 39-bus case. A light overlay reports the sample count per
        location so rates backed by few samples are visible.
    """
    import re

    stable = df["stable"].astype(bool)
    status = df["screening_status"].astype(str)

    n_rejected = int(meta.get("stat_rejected", 0)) if meta else 0

    # --- fault-location order: derived from the data, BUS then LINE by index ---
    def _loc_key(lbl: str):
        m = re.match(r"([A-Za-z]+)(\d+)$", lbl)
        if not m:
            return (2, lbl, 0)  # unknown labels last, alphabetical
        kind, num = m.group(1).upper(), int(m.group(2))
        return (0 if kind == "BUS" else 1 if kind == "LINE" else 2, kind, num)

    present = df["fault_location_label"].astype(str)
    present = present[present != "NA"]
    order = sorted(present.unique(), key=_loc_key)
    n_loc = len(order)

    grp = (
        df.assign(unstable=~stable, _lbl=df["fault_location_label"].astype(str))
        .groupby("_lbl")["unstable"]
    )
    rate = (grp.mean().reindex(order) * 100.0)
    counts = grp.size().reindex(order).fillna(0)

    # --- figure size scales with the number of real fault locations ---
    width_b = max(8.0, 0.24 * n_loc)
    fig = plt.figure(figsize=(max(8.0, width_b), 10))
    ax_a = fig.add_subplot(2, 1, 1)
    ax_b = fig.add_subplot(2, 1, 2)

    # --- (a) grouped bars: screening status x stability label ---
    groups = ["accepted", "borderline"]
    stable_counts = [int(((status == g) & stable).sum()) for g in groups]
    unstable_counts = [int(((status == g) & ~stable).sum()) for g in groups]
    x = np.arange(len(groups))
    w = 0.38
    b_s = ax_a.bar(x - w / 2, stable_counts, w, color=STABLE_G, label="STABLE")
    b_u = ax_a.bar(x + w / 2, unstable_counts, w, color=UNSTABLE_R, label="UNSTABLE")

    xticks = list(x)
    xticklabels = [g.upper() for g in groups]

    # Optional REJECTED group (from metadata; no stability label available).
    if n_rejected > 0:
        xr = len(groups)
        b_r = ax_a.bar(xr, n_rejected, w, color="#7f7f7f",
                       label="REJECTED (no label)")
        xticks.append(xr)
        xticklabels.append("REJECTED")
        ax_a.annotate(
            "rejected: from metadata;\nno stable/unstable status",
            xy=(xr, n_rejected), xytext=(0, 22), textcoords="offset points",
            ha="center", va="bottom", fontsize=7, color="#555555",
        )

    ax_a.set_xticks(xticks)
    ax_a.set_xticklabels(xticklabels)
    ax_a.set_ylabel("Scenario count")
    ax_a.set_title("(a)")
    ax_a.legend(loc="upper center", bbox_to_anchor=(0.5, 1.28),
                ncol=3 if n_rejected > 0 else 2, frameon=False, fontsize=9)

    # --- (b) per-fault-location unstable rate (real locations) ---
    xb = np.arange(n_loc)
    ax_b.bar(xb, rate.values, color=UNSTABLE_R, zorder=3)
    ax_b.set_xticks(xb)
    tick_fs = 9 if n_loc <= 20 else 7 if n_loc <= 50 else 5
    ax_b.set_xticklabels(order, rotation=90, ha="center", fontsize=tick_fs)
    ax_b.set_ylim(0, 100)
    ax_b.set_ylabel("Unstable [%]")
    ax_b.set_title(f"(b)") # b) unstable rate per fault location ({n_loc} locations)
    ax_b.set_xlim(-0.6, n_loc - 0.4)

    # sample-count overlay on a secondary axis (context for the rates)
    ax_c = ax_b.twinx()
    ax_c.plot(xb, counts.values, color="#333333", lw=0.9, marker=".",
              ms=3, alpha=0.6, zorder=4, label="samples")
    ax_c.set_ylabel("Samples per location", color="#333333")
    ax_c.tick_params(axis="y", labelcolor="#333333")
    ax_c.set_ylim(0, max(1.0, float(counts.max()) * 1.15))
    ax_c.grid(False)

    _save_pdf_svg(fig, "fig10_screening_faultrate")


def fig_generator_pg(df: pd.DataFrame) -> None:
    """Distribution of per-generator active power output Pg [MW].

    Adapts to the network size: the generator count is read from the columns
    present (3 for IEEE 9-bus, 10 for NE 39-bus), and the figure width and
    colours scale accordingly.
    """
    import re

    cols = sorted(
        [c for c in df.columns if re.fullmatch(r"pf_Pg\d+", c)],
        key=lambda c: int(c[5:]),
    )
    if not cols:
        return
    n = len(cols)
    cmap = plt.get_cmap("tab10" if n <= 10 else "tab20")
    colors = [cmap(i % cmap.N) for i in range(n)]

    # Width grows with generator count so the box plot stays readable.
    width = max(12.0, 1.0 * n + 4.0)
    fig, axes = plt.subplots(1, 2, figsize=(width, 4.4))

    # (a) overlaid histograms
    for c, col in zip(cols, colors):
        s = pd.to_numeric(df[c], errors="coerce").dropna()
        axes[0].hist(s, bins=50, alpha=0.55, color=col,
                     label=f"{c.replace('pf_', '')} (mean {s.mean():.0f})")
    axes[0].axvline(0, color="k", lw=0.8, ls=":")
    axes[0].set_title("(a) Per-generator $P_g$ distribution")
    axes[0].set_xlabel("$P_g$ [MW]")
    axes[0].set_ylabel("count")
    axes[0].legend(fontsize=8, ncol=1 if n <= 5 else 2)

    # (b) box plot for a compact five-number summary
    data = [pd.to_numeric(df[c], errors="coerce").dropna().values for c in cols]
    bp = axes[1].boxplot(data, tick_labels=[c.replace("pf_", "") for c in cols],
                         showmeans=True, patch_artist=True)
    for patch, col in zip(bp["boxes"], colors):
        patch.set_facecolor(col)
        patch.set_alpha(0.6)
    axes[1].axhline(0, color="k", lw=0.8, ls=":")
    axes[1].set_title("(b) $P_g$ spread by generator")
    axes[1].set_ylabel("$P_g$ [MW]")
    if n > 6:
        axes[1].tick_params(axis="x", labelrotation=45, labelsize=9)

    fig.suptitle("Generator active-power output $P_g$ across all scenarios", y=1.02)
    _save_pdf_svg(fig, "fig12_generator_pg")


def fig_physics_panels(df: pd.DataFrame, meta: dict | None = None) -> None:
    """Paper figure: transient-physics descriptors of the dataset.

    Panels
    ------
    (a) peak inter-machine rotor-angle separation ``delta_max`` [deg]
    (b) peak generator speed deviation ``|omega - 1|`` [pu]
    (c) fault-clearing duration [s]
    (d) ``delta_max`` vs. fault-clearing duration, coloured by TSI -- a joint
        view of the three quantities, with the 180-deg first-swing limit
        overlaid.
    """
    stable = df["stable"].astype(bool)
    dmax = pd.to_numeric(df.get("delta_max_deg"), errors="coerce")
    wdev = pd.to_numeric(df.get("omega_max_dev"), errors="coerce")
    clr = pd.to_numeric(df.get("fault_duration"), errors="coerce")
    tsi = pd.to_numeric(df.get("tsi"), errors="coerce")

    limit = FIRST_SWING_LIMIT_DEG

    fig, axes = plt.subplots(2, 2, figsize=(12, 9))

    # (a) delta_max distribution, split by outcome
    ax = axes[0, 0]
    if dmax.dropna().size:
        ax.hist([dmax[stable].dropna(), dmax[~stable].dropna()], bins=50,
                stacked=True, color=[STABLE_C, UNSTABLE_C],
                label=["stable", "unstable"])
        ax.axvline(limit, color="k", lw=1.2, ls="--",
                   label=f"stability limit = {limit:g}\u00b0")
    ax.set_title(r"(a)") # (a) Peak rotor-angle separation $\delta_\mathrm{max}$
    ax.set_xlabel(r"$\delta_\mathrm{max}$ [deg]")
    ax.set_ylabel("count")
    ax.legend(fontsize=10)

    # (b) |omega - 1| distribution, split by outcome
    ax = axes[0, 1]
    if wdev.dropna().size:
        ax.hist([wdev[stable].dropna(), wdev[~stable].dropna()], bins=50,
                stacked=True, color=[STABLE_C, UNSTABLE_C],
                label=["stable", "unstable"])
    ax.set_title(r"(b)") #(b) Peak speed deviation $|\omega - 1|$
    ax.set_xlabel(r"$|\omega - 1|_\mathrm{max}$ [pu]")
    ax.set_ylabel("count")
    ax.legend(fontsize=10)

    # (c) fault-clearing duration distribution, split by outcome
    ax = axes[1, 0]
    if clr.dropna().size:
        ax.hist([clr[stable].dropna(), clr[~stable].dropna()], bins=50,
                stacked=True, color=[STABLE_C, UNSTABLE_C],
                label=["stable", "unstable"])
    ax.set_title(r"(c)") # (c) Fault-clearing duration
    ax.set_xlabel("fault-clearing duration [s]")
    ax.set_ylabel("count")
    ax.legend(fontsize=10)

    # (d) joint view: delta_max vs clearing duration, colour = TSI
    ax = axes[1, 1]
    m = clr.notna() & dmax.notna() & tsi.notna()
    if m.any():
        vmax = float(np.nanpercentile(np.abs(tsi[m]), 98)) or 1.0
        sc = ax.scatter(clr[m], dmax[m], c=tsi[m], cmap="RdYlBu",
                        vmin=-vmax, vmax=vmax, s=8, alpha=0.6, edgecolors="none")
        cb = fig.colorbar(sc, ax=ax)
        cb.set_label("TSI")
        ax.axhline(limit, color="k", lw=1.2, ls="--",
                   label=f"stability limit = {limit:g}\u00b0")
        ax.legend(fontsize=10)
    ax.set_title(r"(d)") # (d) $\delta_\mathrm{max}$ vs. clearing duration (colour = TSI)
    ax.set_xlabel("fault-clearing duration [s]")
    ax.set_ylabel(r"$\delta_\mathrm{max}$ [deg]")

    # fig.suptitle("Transient-physics descriptors of the dataset", y=1.01)
    _save_pdf_svg(fig, "fig13_physics_panels")

