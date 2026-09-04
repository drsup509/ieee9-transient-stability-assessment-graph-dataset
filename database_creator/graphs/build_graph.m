function network = build_graph(network, results, cfg)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% BUILD_GRAPH
%
% Build the complete graph representation of the electrical network.
%
% This function orchestrates the construction of all graph components used
% by Graph Neural Networks (GNNs). It does not perform any electrical
% calculations; instead, it assembles previously computed information into
% a unified graph structure.
%
% Graph Components
% ----------------
% 1. Node Features
% 2. Edge Features
% 3. System Features
% 4. Edge Index
% 
% 
% Outputs
% -------
% network.graph
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('\n');
fprintf('====================================================\n');
fprintf(' Building complete graph representation...\n');
fprintf('====================================================\n');

%% Node features

network = build_node_features(network, results);

%% Edge features

network = build_edge_features(network, results);

%% System features

network = build_system_features(network);

%% Edge index

network = build_edge_index(network,cfg);

%% General metadata

network.graph.metadata.caseName = cfg.project.caseName;

network.graph.metadata.creationDate = datestr(now);

network.graph.metadata.numberNodes = ...
    size(network.graph.nodes.features,1);

network.graph.metadata.numberEdges = ...
    size(network.graph.edges.features,1);

network.graph.metadata.numberGraphEdges = ...
    size(network.graph.edgeIndex,2);

network.graph.metadata.numberNodeFeatures = ...
    size(network.graph.nodes.features,2);

network.graph.metadata.numberEdgeFeatures = ...
    size(network.graph.edges.features,2);

network.graph.metadata.numberSystemFeatures = ...
    length(network.graph.system.features);

network.graph.metadata.bidirectional = ...
    cfg.graph.bidirectional;

%% Summary

fprintf('\n');

fprintf(' Nodes : %d\n', ...
    network.graph.metadata.numberNodes);

fprintf(' Physical edges : %d\n', ...
    network.graph.metadata.numberEdges);

fprintf(' Graph edges : %d\n', ...
    network.graph.metadata.numberGraphEdges);

fprintf(' Node features : %d\n', ...
    network.graph.metadata.numberNodeFeatures);

fprintf(' Edge features : %d\n', ...
    network.graph.metadata.numberEdgeFeatures);

fprintf(' System features : %d\n', ...
    network.graph.metadata.numberSystemFeatures);

if cfg.graph.bidirectional

    fprintf(' Graph type : Bidirectional\n');

else

    fprintf(' Graph type : Directed\n');

end

fprintf('\n');

fprintf(' Graph successfully created.\n');

fprintf('====================================================\n');

validate_graph(network);

end
