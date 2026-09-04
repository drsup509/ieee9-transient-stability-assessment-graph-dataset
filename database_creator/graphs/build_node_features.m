function network = build_node_features(network, results)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% BUILD_NODE_FEATURES
%
% Construct the node feature matrix used by the Graph Neural Network (GNN).
%
% This function assembles all node attributes already available in the
% network structure. No electrical quantities are computed here.
%
% Node feature categories
% -----------------------
%
% Topology
% 1 - Bus Type
% 2 - Base Voltage
% 3 - Generator Flag
% 4 - Load Flag
%
% Steady-State
% 5 - Active Load (Pd)
% 6 - Reactive Load (Qd)
%
% Power Flow
% 7 - Voltage Magnitude (Vm)
% 8 - Voltage Angle (Va)
% 9 - Active Generation (Pg)
% 10 - Reactive Generation (Qg)
%
% Inputs
% ------
% network : Main project structure
%
% Outputs
% -------
% network.graph.nodes.features
% network.graph.nodes.featureNames
% network.graph.nodes.featureUnits
% network.graph.nodes.featureGroups
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('\n');
fprintf('=============================================\n');
fprintf(' Building node features...\n');
fprintf('=============================================\n');

%% ------------------------------------------------------------------------
% Retrieve data
%% ------------------------------------------------------------------------

nodeMap = network.topology.nodeMap;

steadyState = network.steadyState;

% results = network.results;

nBus = height(nodeMap);

define_constants;

%% ------------------------------------------------------------------------
% Initialization
%% ------------------------------------------------------------------------

features = [];

featureNames = {};

featureUnits = {};

featureGroups = {};

%% ========================================================================
% TOPOLOGY FEATURES
%% ========================================================================

%% Bus Type

features(:,end+1) = nodeMap.busType;

featureNames{end+1} = 'BusType';
featureUnits{end+1} = '-';
featureGroups{end+1} = 'Topology';

%% Base Voltage

features(:,end+1) = nodeMap.baseKV;

featureNames{end+1} = 'BaseKV';
featureUnits{end+1} = 'kV';
featureGroups{end+1} = 'Topology';

%% Generator Flag
% 
% features(:,end+1) = double(~isnan(nodeMap.generatorID));
% 
% featureNames{end+1} = 'GeneratorFlag';
% featureUnits{end+1} = '-';
% featureGroups{end+1} = 'Topology';

%% Generator ID
% Pour les modèles de Deep Learning (GNN, PINN, etc.), les NaN sont
% problématiques et empêchent généralement l'entraînement. 
% Utiliser : 0 → aucun générateur / aucune charge, 
% 1, 2, 3, ... → identifiant associé, représentation simple et robuste.
%
% ATTENTION Pour un GNN, un identifiant numérique (GeneratorID = 1, 2, 3) 
% peut être interprété comme une grandeur ordonnée, alors qu'il
% s'agit en réalité d'une étiquette (catégorie)
%


generatorID = nodeMap.generatorID;

generatorID(isnan(generatorID)) = 0;

features(:,end+1) = generatorID;

featureNames{end+1} = 'GeneratorID';
featureUnits{end+1} = '-';
featureGroups{end+1} = 'Topology';

%% Load Flag
% 
% features(:,end+1) = double(~isnan(nodeMap.loadID));
% 
% featureNames{end+1} = 'LoadFlag';
% featureUnits{end+1} = '-';
% featureGroups{end+1} = 'Topology';

%% Load ID
%
% ATTENTION Pour un GNN, un identifiant numérique (GeneratorID = 1, 2, 3) 
% peut être interprété comme une grandeur ordonnée, alors qu'il
% s'agit en réalité d'une étiquette (catégorie)
%

loadID = nodeMap.loadID;

loadID(isnan(loadID)) = 0;

features(:,end+1) = loadID;

featureNames{end+1} = 'LoadID';
featureUnits{end+1} = '-';
featureGroups{end+1} = 'Topology';

%% ========================================================================
% STEADY-STATE FEATURES
%% ========================================================================

%% Active Load

features(:,end+1) = steadyState.Pd0;

featureNames{end+1} = 'Pd';
featureUnits{end+1} = 'MW';
featureGroups{end+1} = 'SteadyState';

%% Reactive Load

features(:,end+1) = steadyState.Qd0;

featureNames{end+1} = 'Qd';
featureUnits{end+1} = 'MVAr';
featureGroups{end+1} = 'SteadyState';

%% ========================================================================
% POWER FLOW FEATURES
%% ========================================================================

%% Voltage Magnitude

features(:,end+1) = results.bus(:, VM); %results.Vm;


featureNames{end+1} = 'Vm';
featureUnits{end+1} = 'p.u.';
featureGroups{end+1} = 'PowerFlow';

%% Voltage Angle

features(:,end+1) = results.bus(:, VA); %results.Va;

featureNames{end+1} = 'Va';
featureUnits{end+1} = 'deg';
featureGroups{end+1} = 'PowerFlow';

%% Active Generation

features(:,end+1) = results.bus(:, PG); %results.Pg;

featureNames{end+1} = 'Pg';
featureUnits{end+1} = 'MW';
featureGroups{end+1} = 'PowerFlow';

%% Reactive Generation

features(:,end+1) = results.bus(:, QG); %results.Qg;

featureNames{end+1} = 'Qg';
featureUnits{end+1} = 'MVAr';
featureGroups{end+1} = 'PowerFlow';

%% ------------------------------------------------------------------------
% Store node features
%% ------------------------------------------------------------------------

network.graph.nodes.features = features;

network.graph.nodes.featureNames = featureNames;

network.graph.nodes.featureUnits = featureUnits;

network.graph.nodes.featureGroups = featureGroups;

%% SIZE

network.graph.nodes.size = size(network.graph.nodes.features);

%% ------------------------------------------------------------------------
% Metadata
%% ------------------------------------------------------------------------

network.graph.metadata.numberNodes = nBus;

network.graph.metadata.numberNodeFeatures = size(features,2);

%% ------------------------------------------------------------------------
% Basic validation
%% ------------------------------------------------------------------------

assert(size(features,1)==nBus,...
    'Incorrect number of node features.');

assert(size(features,2)==length(featureNames),...
    'Feature names are inconsistent.');

assert(~any(isnan(features(:))),...
    'NaN values detected in node features.');

%% ------------------------------------------------------------------------
% Summary
%% ------------------------------------------------------------------------

fprintf(' Number of nodes : %d\n',nBus);
fprintf(' Number of features : %d\n',size(features,2));

fprintf('\n');

for k=1:length(featureNames)

    fprintf('%2d - %-15s (%s)\n',...
        k,...
        featureNames{k},...
        featureGroups{k});

end

fprintf('\n');

fprintf(' Node features successfully created.\n');

fprintf('=============================================\n');

end