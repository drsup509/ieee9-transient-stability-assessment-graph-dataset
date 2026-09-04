function shardPath = generate_dataset_shard(cfg, idxStart, idxEnd, shardId)
% GENERATE_DATASET_SHARD  Run a contiguous block of scenarios on one worker.
%   Processes scenarios idxStart..idxEnd and saves a partial dataset to a
%   shard-specific .mat file, returning its path. Each scenario reseeds
%   deterministically from its global index (see initialize_scenario), so the
%   result is independent of the shard boundaries or execution order.
%
%   Designed to run inside a parfor/parpool worker. Supports per-shard
%   checkpoint/resume via cfg.dataset.resume.

%% Isolate Simulink build artifacts in a per-worker temp folder
workDir = fullfile(tempdir, sprintf('tsa_worker_%d', feature('getpid')));
if ~exist(workDir, 'dir'); mkdir(workDir); end
origDir = pwd;
cd(workDir);
cleaner = onCleanup(@() cd(origDir));

%% Activate MATPOWER on this worker (steady-state engine).
% Root is the parent of the project root (tsa_project lives inside matpower).
if exist('loadcase', 'file') ~= 2
    matpowerRoot = fileparts(cfg.project.rootPath);
    here = pwd;
    cd(matpowerRoot);
    install_matpower(1, 0, 0);
    cd(here);
end

%% Shard output file (stable name -> resume overwrites it)
outFolder = resolve_output_folder(cfg);
shardPath = fullfile(outFolder, sprintf('%s_shard%02d.mat', cfg.project.caseName, shardId));

%% Resume this shard if a partial exists
dataset = [];
resumeFrom = idxStart - 1;
if isfield(cfg.dataset, 'resume') && cfg.dataset.resume && exist(shardPath, 'file')
    loaded = load(shardPath, 'dataset');
    if isfield(loaded, 'dataset')
        dataset = loaded.dataset;
        if isfield(dataset, 'progress') && isfield(dataset.progress, 'lastScenario')
            resumeFrom = max(resumeFrom, dataset.progress.lastScenario);
        end
    end
end
if isempty(dataset)
    dataset = initialize_dataset(cfg);
end

%% One-time per-worker setup
mpc_base = loadcase(cfg.project.caseName);
opt = simulationOptions();
topology = build_topology(mpc_base, cfg);
inspect_simscape_model(cfg);

faultMap = [];
if cfg.transient.enable
    faultMap = prepare_fault_infrastructure(cfg.simulation.modelName, cfg);
end

%% Scenario loop
for i = (resumeFrom + 1):idxEnd

    fprintf('[shard %02d] scenario %d / %d\n', shardId, i, idxEnd);

    try
        network = build_network(mpc_base, cfg);
        network.topology = topology;

        network = generate_scenario(network, cfg, i);

        mpc = network.mpc;
        mpc = sanity_check_post_update(mpc);

        results = run_powerflow(mpc, opt);

        delta_Pg_slack_neg = generation_on_slack_bus(results, cfg);
        if delta_Pg_slack_neg >= 0
            mpc = redispatch_delta_mw_slack(mpc, delta_Pg_slack_neg);
            results = run_powerflow(mpc, opt);
        end

        network = compute_line_loading(network, results);
        validation = validate_powerflow(network, results, mpc, cfg);

        if cfg.dataset.saveAcceptedOnly && validation.status ~= "ACCEPTED"
            fprintf('[shard %02d] scenario %d skipped (%s)\n', shardId, i, validation.status);
            dataset.progress.lastScenario = i;
            continue;
        end

        network = compute_indices(network, results, cfg);
        network = build_graph(network, results, cfg);

        if cfg.transient.enable
            network = run_dynamic_simulation(network, faultMap, cfg);
        end

        sample = assemble_sample(network, validation, results, cfg, i);
        dataset = save_sample(dataset, sample, mpc);

    catch ME
        fprintf('[shard %02d] ERROR scenario %d: %s\n', shardId, i, ME.message);
        dataset.statistics.rejected = dataset.statistics.rejected + 1;
        dataset.statistics.total = dataset.statistics.total + 1;
    end

    dataset.progress.lastScenario = i;

    % Periodic checkpoint (atomic write).
    if isfield(cfg.dataset, 'checkpointEvery') ...
            && cfg.dataset.checkpointEvery > 0 ...
            && mod(i, cfg.dataset.checkpointEvery) == 0
        tmp = [shardPath '.tmp'];
        save(tmp, 'dataset', '-v7.3');
        if exist(shardPath, 'file'); delete(shardPath); end
        movefile(tmp, shardPath);
    end

end

%% Final shard save (atomic)
dataset.metadata.shardId = shardId;
dataset.metadata.shardRange = [idxStart, idxEnd];
tmp = [shardPath '.tmp'];
save(tmp, 'dataset', '-v7.3');
if exist(shardPath, 'file'); delete(shardPath); end
movefile(tmp, shardPath);

fprintf('[shard %02d] done -> %s (%d samples)\n', shardId, shardPath, dataset.statistics.total);

end
