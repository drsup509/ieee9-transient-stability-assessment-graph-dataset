function dataset = generate_dataset(cfg)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GENERATE_DATASET
%
% OBJECTIF
% --------
% Orchestrer toute la chaîne de génération de dataset :
%
% build_network
% generate_scenario
% update_mpc
% run_powerflow
% validate_powerflow
% extract_powerflow
% compute_indices
% assemble_sample
% save_sample
%
% puis sauvegarde finale du dataset.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('\n========================================\n');
fprintf(' DATASET GENERATION START\n');
fprintf(' Case : %s\n', cfg.project.caseName);
fprintf(' Scenarios : %d\n', cfg.dataset.numberScenarios);
fprintf('========================================\n\n');


%% INITIALISATION DATASET
%
% Reprise sur checkpoint : si un checkpoint existe et que cfg.dataset.resume
% est actif, on reprend le dataset partiel et on saute les scenarios deja
% traites (graine deterministe par scenario -> pas de recalcul).

startIndex = 0;
dataset = [];

if isfield(cfg.dataset, 'resume') && cfg.dataset.resume
    [dataset, startIndex] = load_checkpoint(cfg);
end

if isempty(dataset)
    dataset = initialize_dataset(cfg);
    startIndex = 0;
end


%% LOAD BASE CASE

mpc_base = loadcase(cfg.project.caseName);

opt = simulationOptions();

%% TOPOLOGY/GRAPH 
% 
% Topologie fixe - Régime permanent
%

topology = build_topology(mpc_base, cfg);

%% SIMSCAPE  
%
% Extraire modèle sps
%

simScape = inspect_simscape_model(cfg);

%% TRANSIENT INFRASTRUCTURE
%
% Instrumentation UNIQUE du modèle Simscape (en mémoire) : ajout d'un bloc
% de défaut par jeu de barres. Réalisé une seule fois avant la boucle.
% Activé uniquement si cfg.transient.enable == true.
% Nécessite un MATLAB avec licence Simscape / Simscape Electrical.

faultMap = [];
if cfg.transient.enable
    faultMap = prepare_fault_infrastructure(cfg.simulation.modelName, cfg);
end


%% LOOP SCENARIOS

for i = (startIndex + 1):cfg.dataset.numberScenarios

    fprintf('\n----------------------------------------\n');
    fprintf(' Scenario %d / %d\n', i, cfg.dataset.numberScenarios);
    fprintf('----------------------------------------\n');

    try

        %% ================= BUILD NETWORK ================= %%
        network = build_network(mpc_base, cfg);

        %ajout de la topologie à network
        network.topology  = topology;

        %% ================= SCENARIO ================= %%
        network = generate_scenario(network, cfg, i);        

        %% ================= UPDATE MPC ================= %%
        % mpc = update_mpc(mpc_base, network);
        
        mpc = network.mpc; %scénario mis à jour après scaling
        mpc = sanity_check_post_update(mpc);

        %% ================= POWER FLOW ================= %%        
        
        results = run_powerflow(mpc, opt);
        % results.gen

        delta_Pg_slack_neg = generation_on_slack_bus(results, cfg);

        if delta_Pg_slack_neg >= 0

            mpc = redispatch_delta_mw_slack(mpc, delta_Pg_slack_neg);  

            % fprintf('\n==============  Recalcul PF  ===================\n');
            results = run_powerflow(mpc, opt);
            % results.gen
            % 
            % fprintf('\n========================================\n');

        end

        %% ================= COMPUTE LINE LOADING ================= %
        %
        % Non ajouté avec les autres indices car cette valeur sert à
        % valider le powerflow

        network = compute_line_loading(network, results);

        % %%% verification si nan dans lineloading
        % fprintf('*****************   Véréfication LineLoading \n\n*****************')
        % 
        % sum(isnan(network.indices.lineLoading.vector));
        % find(isnan(network.indices.lineLoading.vector));
        % find(network.topology.edgeMap.rateA==0);
        % 
        % define_constants;
        % % size(network.indices.lineLoading.vector)
        % % size(network.topology.edgeMap.rateA)
        % % size(results.branch(:, PF))
        % % sum(network.topology.edgeMap.rateA==0)
        % % network.topology.edgeMap.rateA(1:20)
        % network.indices.lineLoading.vector
        % 
        % fprintf('*****************   Fin Véréfication LineLoading \n\n*****************')

        %% ================= VALIDATION ================= %%
        validation = validate_powerflow(network, results, mpc, cfg);

        %% ================= SKIP RULE ================= %%
        if cfg.dataset.saveAcceptedOnly && validation.status ~= "ACCEPTED"
            fprintf(' Skipped (status: %s)\n', validation.status);
            continue;
        end

        %% ================= FEATURE EXTRACTION ================= %%

        % network = extract_powerflow(network, results, mpc);
        % 
        % fprintf('\n NODES FEATURES \n\n');
        % network.graph.nodeFeatures
        % fprintf('\n FIN NODES FEATURES \n\n');

        %% ================= INDICES ================= %%

        network = compute_indices(network, results, cfg);

        % network = compute_load_diversity(network, cfg);


        %% ================= GRAPH ================= %%

        network = build_graph(network, results, cfg);
     
        %% ================= TRANSIENT SIMULATION ================= %%
        %
        % Simulation dynamique Simscape + label de stabilité transitoire.
        % Activée uniquement si cfg.transient.enable == true.
        % (MATLAB avec licence Simscape requise.)

        if cfg.transient.enable
            network = run_dynamic_simulation(network, faultMap, cfg);
        end

        %% ================= ASSEMBLE SAMPLE ================= %%

        sample = assemble_sample(network, validation, results, cfg, i);

        % network.simscape.blocks

        %% ================= SAVE SAMPLE ================= %%

        % dataset = save_sample(dataset, sample);

        dataset = save_sample(dataset, sample, mpc); %mpc reéseau scaled

    catch ME

        fprintf(' ERROR in scenario %d: %s\n', i, ME.message);

        dataset.statistics.rejected = dataset.statistics.rejected + 1;
        dataset.statistics.total = dataset.statistics.total + 1;

    end

    %% ================= PROGRESS + CHECKPOINT ================= %%
    %
    % Marquer le scenario comme traite (succes OU erreur) puis, tous les
    % cfg.dataset.checkpointEvery scenarios, ecrire un checkpoint de secours.

    dataset.progress.lastScenario = i;

    if isfield(cfg.dataset, 'checkpointEvery') ...
            && cfg.dataset.checkpointEvery > 0 ...
            && mod(i, cfg.dataset.checkpointEvery) == 0
        save_checkpoint(dataset, cfg);
    end

end


%% FINAL SAVE

save_dataset(dataset, cfg);

%% END

fprintf('\n========================================\n');
fprintf(' DATASET GENERATION COMPLETED\n');
fprintf('========================================\n');

fprintf('Total : %d\n', dataset.statistics.total);
fprintf('Accepted : %d\n', dataset.statistics.accepted);
fprintf('Borderline : %d\n', dataset.statistics.borderline);
fprintf('Rejected : %d\n', dataset.statistics.rejected);

end