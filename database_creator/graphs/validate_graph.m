function validate_graph(network)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% VALIDATE_GRAPH
%
% Validate the graph representation used by the Graph Neural Network.
%
% This function performs a complete integrity check of the graph structure
% after build_graph().
%
% Validation includes:
%
% 1 - Graph structure
% 2 - Node features
% 3 - Edge features
% 4 - System features
% 5 - Edge index
% 6 - Metadata consistency
%
% No modification is performed.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('\n');
fprintf('====================================================\n');
fprintf(' Validating graph representation...\n');
fprintf('====================================================\n');

%% Retrieve graph

graph = network.graph;

%% Structure validation

requiredFields = {'nodes','edges','system','edgeIndex','edgeMap','metadata'};

for k = 1:length(requiredFields)

    assert(isfield(graph,requiredFields{k}),...
        ['Missing graph field : ',requiredFields{k}]);

end

fprintf(' Graph structure .............. PASS\n');

%% Node Features

nodeFeatures = graph.nodes.features;

assert(~isempty(nodeFeatures),...
    'Node feature matrix is empty.');

assert(~any(isnan(nodeFeatures(:))),...
    'NaN detected in node features.');

assert(~any(isinf(nodeFeatures(:))),...
    'Inf detected in node features.');

assert(size(nodeFeatures,1)==graph.metadata.numberNodes,...
    'Incorrect number of node features.');

fprintf(' Node features ............... PASS\n');

%% Edge Features

edgeFeatures = graph.edges.features;

assert(~isempty(edgeFeatures),...
    'Edge feature matrix is empty.');

assert(~any(isnan(edgeFeatures(:))),...
    'NaN detected in edge features.');

assert(~any(isinf(edgeFeatures(:))),...
    'Inf detected in edge features.');

assert(size(edgeFeatures,1)==graph.metadata.numberEdges,...
    'Incorrect number of edge features.');

fprintf(' Edge features ............... PASS\n');

%% System Features


systemFeatures = graph.system.features;

assert(~isempty(systemFeatures),...
    'System feature vector is empty.');

assert(~any(isnan(systemFeatures(:))),...
    'NaN detected in system features.');

assert(~any(isinf(systemFeatures(:))),...
    'Inf detected in system features.');

assert(length(systemFeatures)==graph.metadata.numberSystemFeatures,...
    'Incorrect number of system features.');

fprintf(' System features ............. PASS\n');

%% Edge Index

edgeIndex = graph.edgeIndex;

edgeMap = graph.edgeMap;

assert(size(edgeIndex,1)==2,...
    'edgeIndex must have two rows.');

assert(size(edgeIndex,2)==length(edgeMap),...
    'edgeIndex and edgeMap are inconsistent.');

assert(min(edgeIndex(:))>=1,...
    'Invalid node index.');

assert(max(edgeIndex(:))<=graph.metadata.numberNodes,...
    'Node index exceeds graph size.');

fprintf(' Edge index ................. PASS\n');

%% Edge map consistency

assert(all(graph.edgeMap>=1),...
    'Invalid edge identifier detected.');

assert(max(graph.edgeMap)<=graph.metadata.numberEdges,...
    'Edge map exceeds physical branch number.');

fprintf(' Edge mapping ............... PASS\n');



%% Bidirectional consistency

if graph.metadata.bidirectional

    assert(size(edgeIndex,2)==2*graph.metadata.numberEdges,...
        'Incorrect number of graph edges.');

else

    assert(size(edgeIndex,2)==graph.metadata.numberEdges,...
        'Incorrect number of graph edges.');

end

fprintf(' Graph consistency ........... PASS\n');

%% Summary

fprintf('\n');

fprintf(' Nodes : %d\n',graph.metadata.numberNodes);

fprintf(' Physical edges : %d\n',graph.metadata.numberEdges);

fprintf(' Graph edges : %d\n',graph.metadata.numberGraphEdges);

fprintf(' Node features : %d\n',graph.metadata.numberNodeFeatures);

fprintf(' Edge features : %d\n',graph.metadata.numberEdgeFeatures);

fprintf(' System features : %d\n',graph.metadata.numberSystemFeatures);

fprintf('\n');


%% Graph Statistics

fprintf('\n');
fprintf('---------------- GRAPH STATISTICS ----------------\n');

fprintf('\n');

fprintf('Node Features\n');
fprintf('-------------\n');

fprintf(' Matrix size : %d x %d\n',...
    size(graph.nodes.features,1),...
    size(graph.nodes.features,2));

fprintf(' Number of features : %d\n',...
    graph.metadata.numberNodeFeatures);

fprintf('\n');

fprintf('Edge Features\n');
fprintf('-------------\n');

fprintf(' Matrix size : %d x %d\n',...
    size(graph.edges.features,1),...
    size(graph.edges.features,2));

fprintf(' Number of features : %d\n',...
    graph.metadata.numberEdgeFeatures);

fprintf('\n');

fprintf('System Features\n');
fprintf('---------------\n');

fprintf(' Vector size : %d x %d\n',...
    size(graph.system.features,1),...
    size(graph.system.features,2));

fprintf(' Number of features : %d\n',...
    graph.metadata.numberSystemFeatures);

fprintf('\n');

fprintf('Edge Index\n');
fprintf('----------\n');

fprintf(' Matrix size : %d x %d\n',...
    size(graph.edgeIndex,1),...
    size(graph.edgeIndex,2));

fprintf(' Physical branches : %d\n',...
    graph.metadata.numberEdges);

fprintf(' Graph edges : %d\n',...
    graph.metadata.numberGraphEdges);

fprintf('\n');

fprintf('Bidirectional graph : %d\n',...
    graph.metadata.bidirectional);

fprintf('--------------------------------------------------\n');


fprintf('\n');
fprintf('====================================================\n');
fprintf(' GRAPH VALIDATION SUCCESSFULLY COMPLETED\n');
fprintf('====================================================\n');

end