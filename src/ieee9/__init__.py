"""IEEE 9-bus transient-stability dataset analysis package.

Pure-Python (h5py) reader + descriptor/figure pipeline for
``case_IEEE9BusSystem_dataset.mat`` (MATLAB v7.3 / HDF5).
"""

from pathlib import Path

# Project root = parent of this package's parent (…/src/ieee9 -> project root).
ROOT = Path(__file__).resolve().parents[2]
MAT_FILE = ROOT / "case_IEEE9BusSystem_dataset.mat"
DATA_DIR = ROOT / "data"
OUT_DIR = ROOT / "outputs"
FIG_DIR = OUT_DIR / "figures"
TAB_DIR = OUT_DIR / "tables"
FLAT_PARQUET = DATA_DIR / f"{MAT_FILE.stem}_flat.parquet"

__all__ = [
    "ROOT",
    "MAT_FILE",
    "DATA_DIR",
    "OUT_DIR",
    "FIG_DIR",
    "TAB_DIR",
    "FLAT_PARQUET",
    "sanitize_case",
    "case_subdir",
]


def sanitize_case(name) -> str:
    """Turn a case name into a filesystem-safe folder name."""
    return "".join(
        c if (c.isalnum() or c in "-_") else "_" for c in str(name)
    ).strip("_") or "case"


def case_subdir(base: Path, case_name) -> Path:
    """Return ``base/<sanitized case name>`` (not created)."""
    return base / sanitize_case(case_name)
