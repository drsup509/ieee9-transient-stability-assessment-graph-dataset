function network = build_system_features(network)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% BUILD_SYSTEM_FEATURES
%
% Construct the system-level feature vector used by the Graph Neural
% Network (GNN).
%
% This function assembles all global electrical indicators already
% computed for the current operating scenario.
%
% No calculations are performed here.
%
% Current System Features
% -----------------------
%
% 1 - Load Diversity Index
% 2 - Global Stress Index
% 3 - Voltage Margin
% 4 - Loss Ratio
%
% Inputs
% ------
% network : Main project structure
%
% Outputs
% -------
% network.graph.system.features
% network.graph.system.featureNames
% network.graph.system.featureUnits
% network.graph.system.featureGroups
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('\n');
fprintf('=============================================\n');
fprintf(' Building system features...\n');
fprintf('=============================================\n');

%% ------------------------------------------------------------------------
% Retrieve indices
%% ------------------------------------------------------------------------

indices = network.indices;

%% ------------------------------------------------------------------------
% Initialization
%% ------------------------------------------------------------------------

features = [];

featureNames = {};

featureUnits = {};

featureGroups = {};

%% ========================================================================
% SYSTEM INDICES
%% ========================================================================

%% Load Diversity

% features(end+1) = indices.loadDiversity.global;
features(end+1) = indices.loadDiversityP.areaCVP;

featureNames{end+1} = 'LoadDiversityArea';
featureUnits{end+1} = '-';
featureGroups{end+1} = 'Indices';

%% Global Stress Index

features(end+1) = indices.stress.globalStress;

featureNames{end+1} = 'StressIndex';
featureUnits{end+1} = '-';
featureGroups{end+1} = 'Indices';

%% Voltage Margin

features(end+1) = indices.voltageMargin.minimumMargin;

featureNames{end+1} = 'VoltageMargin';
featureUnits{end+1} = 'p.u.';
featureGroups{end+1} = 'Indices';

%% Loss Ratio

features(end+1) = indices.lossRatio.lossratio_pu*100;

featureNames{end+1} = 'LossRatio';
featureUnits{end+1} = '%';
featureGroups{end+1} = 'Indices';

%% ------------------------------------------------------------------------
% Store
%% ------------------------------------------------------------------------

network.graph.system.features = features;

network.graph.system.featureNames = featureNames;

network.graph.system.featureUnits = featureUnits;

network.graph.system.featureGroups = featureGroups;

%% ------------------------------------------------------------------------
% Metadata
%% ------------------------------------------------------------------------

network.graph.metadata.numberSystemFeatures = length(features);

%% SIZE

network.graph.system.size = size(network.graph.system.features);

%% ------------------------------------------------------------------------
% Validation
%% ------------------------------------------------------------------------

assert(~any(isnan(features)), ...
    'NaN detected in system features.');

assert(length(featureNames)==length(features), ...
    'Feature names are inconsistent.');

%% ------------------------------------------------------------------------
% Summary
%% ------------------------------------------------------------------------

fprintf(' Number of system features : %d\n',length(features));

fprintf('\n');

for k = 1:length(featureNames)

    fprintf('%2d - %-18s (%s)\n', ...
        k,...
        featureNames{k},...
        featureGroups{k});

end

fprintf('\n');

fprintf(' System features successfully created.\n');
fprintf('=============================================\n');

end
