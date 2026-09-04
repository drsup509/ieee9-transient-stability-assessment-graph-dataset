function network = build_edge_features(network, results)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% BUILD_EDGE_FEATURES
%
% Construct the edge feature matrix used by the Graph Neural Network (GNN).
%
% This function assembles all transmission line attributes already available
% in the project. No electrical quantities are computed here.
%
% Edge feature categories
% -----------------------
%
% Topology
% 1 - Resistance (R)
% 2 - Reactance (X)
% 3 - Line Charging Susceptance (B)
% 4 - Tap Ratio
% 5 - Phase Shift
% 6 - Thermal Rating (RateA)
% 7 - Line Status
%
% Power Flow
% 8 - Active Power From Bus (Pf)
% 9 - Reactive Power From Bus (Qf)
% 10 - Active Power To Bus (Pt)
% 11 - Reactive Power To Bus (Qt)
%
% Computed Indices
% 12 - Line Loading
%
% Inputs
% ------
% network : Main project structure
%
% Outputs
% -------
% network.graph.edges.features
% network.graph.edges.featureNames
% network.graph.edges.featureUnits
% network.graph.edges.featureGroups
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('\n');
fprintf('=============================================\n');
fprintf(' Building edge features...\n');
fprintf('=============================================\n');

%% ------------------------------------------------------------------------
% Retrieve data
%% ------------------------------------------------------------------------

define_constants;

edgeMap = network.topology.edgeMap;

% results = network.results;

indices = network.indices;

nBranch = height(edgeMap);

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

features(:,end+1) = edgeMap.R;
featureNames{end+1} = 'R';
featureUnits{end+1} = 'p.u.';
featureGroups{end+1} = 'Topology';

features(:,end+1) = edgeMap.X;
featureNames{end+1} = 'X';
featureUnits{end+1} = 'p.u.';
featureGroups{end+1} = 'Topology';

features(:,end+1) = edgeMap.B;
featureNames{end+1} = 'B';
featureUnits{end+1} = 'p.u.';
featureGroups{end+1} = 'Topology';

features(:,end+1) = edgeMap.tap;
featureNames{end+1} = 'Tap';
featureUnits{end+1} = '-';
featureGroups{end+1} = 'Topology';

features(:,end+1) = edgeMap.shift;
featureNames{end+1} = 'Shift';
featureUnits{end+1} = 'deg';
featureGroups{end+1} = 'Topology';

features(:,end+1) = edgeMap.rateA;
featureNames{end+1} = 'RateA';
featureUnits{end+1} = 'MVA';
featureGroups{end+1} = 'Topology';

features(:,end+1) = edgeMap.status;
featureNames{end+1} = 'Status';
featureUnits{end+1} = '-';
featureGroups{end+1} = 'Topology';

%% ========================================================================
% POWER FLOW FEATURES
%% ========================================================================

features(:,end+1) = results.branch(:, PF); %.Pf;
featureNames{end+1} = 'Pf';
featureUnits{end+1} = 'MW';
featureGroups{end+1} = 'PowerFlow';

features(:,end+1) = results.branch(:, QF); %Qf;
featureNames{end+1} = 'Qf';
featureUnits{end+1} = 'MVAr';
featureGroups{end+1} = 'PowerFlow';

features(:,end+1) = results.branch(:, PT); %Pt;
featureNames{end+1} = 'Pt';
featureUnits{end+1} = 'MW';
featureGroups{end+1} = 'PowerFlow';

features(:,end+1) = results.branch(:, QT); %Qt;
featureNames{end+1} = 'Qt';
featureUnits{end+1} = 'MVAr';
featureGroups{end+1} = 'PowerFlow';

%% ========================================================================
% COMPUTED FEATURES
%% ========================================================================
%
% Réflexions à avoir si rate A n'est pas fourni par exemple pour IEEE118

% features(:,end+1) = indices.lineLoading; 
features(:,end+1) = indices.lineLoading.vector; %percentage

featureNames{end+1} = 'Loading';
featureUnits{end+1} = '%';
featureGroups{end+1} = 'Indices';

%% ------------------------------------------------------------------------
% Store edge features
%% ------------------------------------------------------------------------

network.graph.edges.features = features;

network.graph.edges.featureNames = featureNames;

network.graph.edges.featureUnits = featureUnits;

network.graph.edges.featureGroups = featureGroups;

%% SIZE

network.graph.edges.size = size(network.graph.edges.features);

%% ------------------------------------------------------------------------
% Metadata
%% ------------------------------------------------------------------------

network.graph.metadata.numberEdges = nBranch;

network.graph.metadata.numberEdgeFeatures = size(features,2);

%% ------------------------------------------------------------------------
% Basic validation
%% ------------------------------------------------------------------------

assert(size(features,1)==nBranch,...
    'Incorrect number of edge features.');

assert(size(features,2)==length(featureNames),...
    'Feature names are inconsistent.');

assert(~any(isnan(features(:))),...
    'NaN values detected in edge features.');

%% ------------------------------------------------------------------------
% Summary
%% ------------------------------------------------------------------------

fprintf(' Number of edges : %d\n',nBranch);
fprintf(' Number of features : %d\n',size(features,2));

fprintf('\n');

for k=1:length(featureNames)

    fprintf('%2d - %-15s (%s)\n',...
        k,...
        featureNames{k},...
        featureGroups{k});

end

fprintf('\n');
fprintf(' Edge features successfully created.\n');
fprintf('=============================================\n');

end