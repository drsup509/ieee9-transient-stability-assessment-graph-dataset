function dataset = initialize_dataset(cfg)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INITIALIZE_DATASET
%
% OBJECTIF
% --------
% Initialiser la structure du dataset avant la génération des scénarios.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('Initializing dataset...\n');


%% METADATA

dataset.metadata.creationDate = datetime("now");
dataset.metadata.caseName = cfg.project.caseName;
dataset.metadata.numberRequested = cfg.dataset.numberScenarios;

%% SAMPLES

dataset.samples = {};

%% STATISTICS

dataset.statistics.total = 0;
dataset.statistics.accepted = 0;
dataset.statistics.borderline = 0;
dataset.statistics.rejected = 0;

% Compteurs de la couche transitoire (etiquettes de stabilite)
dataset.statistics.stable = 0;
dataset.statistics.unstable = 0;
dataset.statistics.transientFailed = 0;

dataset.statistics.startTime = datetime("now");

%% PROGRESS (reprise sur checkpoint)

dataset.progress.lastScenario = 0;   % indice du dernier scenario traite

fprintf('Dataset initialized successfully.\n');

end
