function datasetPath = generate_dataset_parallel(nWorkers, freshStart)
% GENERATE_DATASET_PARALLEL  Run the full scenario sweep across local workers.
%   Splits cfg.dataset.numberScenarios into nWorkers contiguous shards, runs
%   them in parallel (each shard = generate_dataset_shard), then merges the
%   shard partials in index order and saves one final dataset.
%
%   nWorkers (optional)   : number of parallel workers. Default = half the
%                           physical cores. Capped to the pool maximum.
%   freshStart (optional) : true  -> delete existing shard files first and
%                                    start a clean run (no resume).
%                           false -> resume from per-shard checkpoints if a
%                                    previous run was interrupted (default).
%
%   To run a different sweep, edit config.m only:
%     - cfg.dataset.numberScenarios : how many scenarios (e.g. 100000)
%     - cfg.project.randomSeed      : change for a different (non-overlapping)
%                                     set of scenarios
%   Seeds derive deterministically from the scenario index, so shard
%   boundaries and worker count never change the results, and resume is safe.

if nargin < 2 || isempty(freshStart)
    freshStart = false;
end

% Add project folders to path (do NOT call startup here: it runs
% "clear all", which would wipe this function's input arguments).
projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(projectRoot));

cfg = config();

% Activate MATPOWER on the client (root = parent of the project root).
if exist('loadcase', 'file') ~= 2
    here = pwd;
    cd(fileparts(cfg.project.rootPath));
    install_matpower(1, 0, 0);
    cd(here);
end

%% Log everything to the dataset folder (log name ends with the case name)
outFolder = resolve_output_folder(cfg);
logPath = fullfile(outFolder, sprintf('run_%s_%s.log', ...
    datestr(now, 'yyyymmdd_HHMMSS'), cfg.project.caseName));
diary(logPath);
diary on;
cleanupDiary = onCleanup(@() diary('off'));  %#ok<NASGU>
fprintf(' Log file  : %s\n', logPath);

%% Worker count (default: half the physical cores)
cluster = parcluster('local');
if nargin < 1 || isempty(nWorkers)
    nWorkers = max(1, floor(cluster.NumWorkers / 2));
end
nWorkers = min(nWorkers, cluster.NumWorkers);

N = cfg.dataset.numberScenarios;
nWorkers = min(nWorkers, N);

%% Fresh start vs. resume
% freshStart: remove existing shard files so the sweep starts clean.
% Otherwise resume from per-shard checkpoints after an interruption.
if freshStart
    old = dir(fullfile(outFolder, sprintf('%s_shard*.mat*', cfg.project.caseName)));
    for k = 1:numel(old)
        delete(fullfile(old(k).folder, old(k).name));
    end
    fprintf(' Fresh start: removed %d old shard file(s).\n', numel(old));
    cfg.dataset.resume = false;
else
    cfg.dataset.resume = true;
end

fprintf('\n========================================\n');
fprintf(' PARALLEL DATASET GENERATION\n');
fprintf(' Case      : %s\n', cfg.project.caseName);
fprintf(' Scenarios : %d\n', N);
fprintf(' Workers   : %d\n', nWorkers);
fprintf('========================================\n\n');

%% Contiguous, non-overlapping shard ranges over 1..N
edges  = round(linspace(0, N, nWorkers + 1));
ranges = [edges(1:end-1) + 1; edges(2:end)]';   % [start end] per shard

%% Parallel pool (workers inherit the client path explicitly)
clientPath = path;
pool = parpool('local', nWorkers);
spmd
    addpath(clientPath);
end

%% Run shards
shardPaths = cell(nWorkers, 1);
parfor s = 1:nWorkers
    shardPaths{s} = generate_dataset_shard(cfg, ranges(s,1), ranges(s,2), s);
end
delete(pool);

%% Merge shard partials in index order
dataset = initialize_dataset(cfg);
for s = 1:nWorkers
    L = load(shardPaths{s}, 'dataset');
    d = L.dataset;
    dataset.samples = [dataset.samples, d.samples];
    dataset.statistics.total          = dataset.statistics.total          + d.statistics.total;
    dataset.statistics.accepted       = dataset.statistics.accepted       + d.statistics.accepted;
    dataset.statistics.borderline     = dataset.statistics.borderline     + d.statistics.borderline;
    dataset.statistics.rejected       = dataset.statistics.rejected       + d.statistics.rejected;
    dataset.statistics.stable         = dataset.statistics.stable         + d.statistics.stable;
    dataset.statistics.unstable       = dataset.statistics.unstable       + d.statistics.unstable;
    dataset.statistics.transientFailed= dataset.statistics.transientFailed+ d.statistics.transientFailed;
end
dataset.progress.lastScenario = N;

%% Final save
save_dataset(dataset, cfg);
datasetPath = resolve_output_folder(cfg);

fprintf('\n========================================\n');
fprintf(' PARALLEL GENERATION COMPLETED\n');
fprintf(' Merged samples : %d\n', numel(dataset.samples));
fprintf('========================================\n');

end
