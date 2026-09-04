function network = initialize_scenario(network, scenarioID, cfg)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INITIALIZE_SCENARIO
%
% OBJECTIF
% --------
% Initialiser la structure décrivant un scénario.
%
% Cette fonction ne génère aucune perturbation. Elle prépare simplement
% la structure qui sera complétée par les autres fonctions :
% - generate_area_scaling
% - scale_loads
% - scale_generators
% - choose_fault
% - compute_fault_metadata
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf(' -> Initializing scenario...\n');

% %% RESET SCENARIO STRUCTURE
% 
% network.scenario = struct();

%% IDENTIFICATION

network.scenario.id = scenarioID;


%% RANDOM SEED
%
% Graine DETERMINISTE derivee du numero de scenario et de la graine de base
% (cfg.project.randomSeed). Garantit la reproductibilite scenario par
% scenario et la reprise sur checkpoint sans recalcul.

seed = derive_scenario_seed(cfg, scenarioID);

rng(seed);

network.scenario.randomSeed = seed;

%% AREA SCALING

network.scenario.areaScaling = struct([]);

%% LOAD INFORMATION

% network.scenario.totalLoad0 = [];
% network.scenario.totalLoad = [];
% network.scenario.loadVariation = [];

network.scenario.totalLoad0 = network.steadyState.totalLoad0;
network.scenario.totalLoad = [];

network.scenario.loadVariation = [];


%% GENERATION INFORMATION
% network.scenario.totalGeneration0 = [];
% network.scenario.totalGeneration = [];
% network.scenario.generationVariation = [];

network.scenario.totalGeneration0 = network.steadyState.totalGen0;

network.scenario.totalGeneration = [];

network.scenario.generationVariation = [];


%% FAULT

network.scenario.fault = struct();

%% SUMMARY

network.scenario.summary = struct();


%% METADATA

network.scenario.metadata.creationTime = datetime("now");

fprintf(' Scenario %d initialized.\n', scenarioID);

end