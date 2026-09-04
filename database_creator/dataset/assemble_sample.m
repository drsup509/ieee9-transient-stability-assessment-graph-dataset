function sample = assemble_sample(network, validation, results, cfg, scenarioID)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ASSEMBLE_SAMPLE
%
% OBJECTIF
% --------
% Construire un échantillon unique et standardisé pour le dataset.
%
% Cette fonction ne calcule rien.
% Elle organise uniquement les données déjà produites.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf(' -> Assembling dataset sample...\n');

%% INITIALISATION

sample = struct();

sample.metadata.caseName = cfg.project.caseName;
sample.metadata.timestamp = datetime("now");
sample.metadata.scenarioID = scenarioID;

%% NETWORK FEATURES (GNN INPUT)

% sample.network.nodeFeatures = network.graph.nodeFeatures;
% sample.network.edgeFeatures = network.graph.edgeFeatures;
% sample.network.edgeIndex = network.graph.edgeIndex;
% 
% if isfield(network.graph,'adjacency')
%     sample.network.adjacency = network.graph.adjacency;
% end

%% FAULT INFORMATION

sample.fault  = network.fault;

%% POWER FLOW STATE

sample.powerFlow.V = results.bus(:,8);
sample.powerFlow.theta = results.bus(:,9);

sample.powerFlow.Pd = results.bus(:,3);
sample.powerFlow.Qd = results.bus(:,4);

sample.powerFlow.Pg = results.gen(:,2);
sample.powerFlow.Qg = results.gen(:,3);

%% SCENARIO DESCRIPTION
%
% On conserve les perturbations appliquées au réseau
%

if isfield(network,'scenario')
    sample.scenario = network.scenario;
else
    sample.scenario = struct();
end

%% INDICES

sample.indices = network.indices;

%% GRAPH

sample.graph = network.graph;

%% VALIDATION LABEL

sample.validation.status = validation.status;
sample.validation.reason = validation.reason;
sample.validation.converged = validation.converged;

sample.validation.minVoltage = validation.minVoltage;
sample.validation.maxVoltage = validation.maxVoltage;

sample.validation.lineLoadingMax = validation.lineLoadingMax;

sample.validation.reactiveLimitViolation = validation.reactiveLimitViolation;

sample.validation.powerBalanceError = validation.powerBalanceError;

%% TRANSIENT STABILITY LABEL
%
% Champ DISTINCT de sample.validation :
%   - sample.validation.status      : qualite du regime PERMANENT (ACCEPTED/...)
%   - sample.transient.label.status : stabilite TRANSITOIRE (STABLE/UNSTABLE)
%
% Rempli uniquement si la simulation dynamique a ete executee
% (cfg.transient.enable == true) et a reussi.

if isfield(network, 'transient')
    sample.transient = network.transient;
else
    sample.transient = struct('success', false, ...
                              'reason', 'transient layer disabled');
end

% Grandeurs post-simulation calculees DIRECTEMENT pendant la generation
% (memes fonctions et memes champs que augment_dataset_postsim, stockage
% identique). Renvoient NaN si les donnees dynamiques sont absentes.
%   .time2LossSync : temps de perte de synchronisme / temps d'elimination
%   .tsi           : indice de stabilite transitoire continu (seuil 360)
sample.transient.time2LossSync = compute_time_to_loss_sync(sample);
sample.transient.tsi           = compute_tsi(sample);

%% FINAL CHECKS (LIGHT SAFETY)

% if isempty(sample.network.nodeFeatures)
%     warning('Empty node features detected');
% end

if isempty(sample.validation.status)
    error('Invalid sample: missing validation status');
end

%% DONE

fprintf(' Sample assembled successfully (ID: %d)\n', scenarioID);

end
