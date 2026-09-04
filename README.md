# IEEE 9-Bus Transient Stability Scenario / Dataset Generator

MATLAB pipeline database_creator/ that generates labelled transient-stability-assessment (TSA)
scenarios for the **IEEE 9-bus system**. 


For each scenario it:

1. builds a randomized operating point (correlated load + generation scaling),
2. solves the steady-state power flow with **MATPOWER**,
3. applies a fault and runs a **Simscape Electrical** dynamic simulation,
4. extracts generator trajectories (rotor angle, speed, `Pe`, `Pm`, `Te`) and
   bus voltages, assigns a stable / unstable label, and builds a graph sample,
5. assembles everything into one dataset file.

This repository is the strict-minimal code needed to reproduce the generation
pipeline. It does **not** include the generated `.mat` datasets or the MATPOWER
distribution (both are separate — see below).

---

## Requirements

- **MATLAB** (R2023b or newer recommended)
- **Simscape** / **Simscape Electrical** — required for the dynamic layer
- **MATPOWER 8.0** — required for the power flow (install separately, see below)
- **Parallel Computing Toolbox** — optional, only for `generate_dataset_parallel`

## Setup

1. **Install MATPOWER 8.0** (https://matpower.org) somewhere on your machine and
   add it to the MATLAB path. The simplest way is to run MATPOWER's own
   installer once:

   ```matlab
   cd <path-to-matpower>
   install_matpower(1, 1, 1)   % adds MATPOWER to the path and saves it
   ```

   After this, `exist('loadcase','file')` must return `2`.

2. **Clone / download this repository**, then from its root run:

   ```matlab
   startup    % adds all repo folders to the path, checks MATPOWER + Simscape
   ```

## Running

**Serial** (single process):

```matlab
cfg = config();                 % all settings live in config/config.m
dataset = generate_dataset(cfg);
```

**Parallel** (splits the sweep across local workers, then merges):

```matlab
% nWorkers optional (default = half the physical cores)
% freshStart = true starts a clean run; false resumes shard checkpoints
generate_dataset_parallel(4, true);
```

> The parallel launcher reads `config()` itself and adds the repo to the path.
> Make sure MATPOWER is already on the path (step 1) before running it.

Outputs are written to the `datasets/` folder (created automatically).

## Configuration

Everything is centralized in [config/config.m](config/config.m). Change the
config file only — the framework functions just consume it. Key knobs:

| Setting | Meaning |
| --- | --- |
| `cfg.dataset.numberScenarios` | number of scenarios to generate (default 20000) |
| `cfg.project.randomSeed` | global RNG seed → reproducibility / non-overlapping sets |
| `cfg.dataset.checkpointEvery` | checkpoint frequency for long runs |
| `cfg.dataset.resume` | resume an interrupted run from checkpoints |
| `cfg.dataset.saveAcceptedOnly` | keep only accepted samples |
| `cfg.transient.enable` | enable/disable the Simscape dynamic layer |

Scenario seeds derive deterministically from the scenario index, so the worker
count and shard boundaries never change the results, and resume is safe.

## Repository layout

```
config/     configuration + generator/machine data
scenario/   randomized operating-point & fault generation
powerflow/  MATPOWER power flow, validation, indices
network/    network model assembly
graph/      topology extraction
graphs/     graph sample (node/edge features, adjacency)
indices/    stress / diversity / voltage feature indices
simscape/   dynamic simulation, fault application, result import
post_sim/   post-simulation metrics (TSI, CoI separation, time-to-loss-sync)
labels/     stability labelling
dataset/    dataset assembly, checkpointing, saving
scripts/    entry points (generate_dataset, *_parallel, *_shard)
test_case/  MATPOWER case file (case_IEEE9BusSystem.m)
model/      Simscape Electrical model (IEEE9BusSystem.slx)
```

## Output

Each sample records metadata, the fault definition, the steady-state power flow,
scenario scaling, feature indices, the graph representation, validation flags,
and the transient results — including per-generator `Pe`, `Pm`, `Te`, rotor
angle and speed trajectories, and per-bus voltage magnitude / angle.

## Citation

If you use this code or the associated dataset, please cite:

Descriptor:
> Suprême, Hussein, Martin de Montigny, and Arnaud Zinflou. "A Benchmark Graph Dataset 
> for Transient Stability Assessment of the IEEE 9-Bus System: 20,000 Scenarios with Full 
> Generator Trajectories." arXiv preprint arXiv:2608.18318 (2026).

Database:
> H. Suprême, M. De Montigny, and A. Zinflou, *A 20,000-Scenario Graph Dataset
> with Full Generator Trajectories for Transient Stability Assessment of the
> IEEE 9-Bus System*, IEEE DataPort, 2026. DOI: 10.21227/d10j-5b27.


## License

See [LICENSE](LICENSE). MATPOWER is distributed separately under its own
(BSD-3-Clause) license and is **not** included in this repository.
