function network = build_edge_index(network, cfg)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% BUILD_EDGE_INDEX
%
% Construct the graph edge index used by GNNs.
%
% This function converts the physical network topology into the graph
% representation required by modern GNN libraries such as PyTorch
% Geometric and DGL.
%
% OUTPUTS
% --------
% network.graph.edgeIndex
% network.graph.edgeMap
%
% DESCRIPTION
% -----------
%
% The physical electrical network is represented by transmission lines
% connecting buses.
%
% Example:%
% Bus 1 -------- Bus 2
%
% This physical line becomes one graph edge if the graph is directed
% (one-way), or two graph edges if the graph is bidirectional.
%
% Directed graph:
% 1 -----> 2
%
% edgeIndex =
% [1
% 2]
%
% Bidirectional graph:
%
% 1 <----> 2
%
% edgeIndex =
% [1 2
% 2 1]
%
%
% The edgeMap vector preserves the correspondence between each graph edge
% and the original transmission line.
%
% Example:
%
% Physical line #15 :
%
% Bus 1 -------- Bus 2
%
% becomes
%
% edgeIndex =
%
% [1 2
% 2 1]
%
% edgeMap =
%
% [15
% 15]
%
% This correspondence will allow interpretation of GNN predictions
% directly on the physical electrical network.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('\n');
fprintf('=============================================\n');
fprintf(' Building edge index...\n');
fprintf('=============================================\n');


%% Retrieve topology

edgeMap = network.topology.edgeMap;

fromNode = edgeMap.fromNode;

toNode = edgeMap.toNode;

edgeID = edgeMap.edgeID;

nBranch = height(edgeMap);

%% Build edge index

if cfg.graph.bidirectional

    edgeIndex = [ ...
        fromNode' toNode'
        toNode' fromNode'];

    graphEdgeMap = [ ...
        edgeID
        edgeID];

else

    edgeIndex = [ ...
        fromNode'
        toNode'];

    graphEdgeMap = edgeID;

end

%% Store graph structure

network.graph.edgeIndex = edgeIndex;

network.graph.edgeMap = graphEdgeMap;

%% Metadata

network.graph.metadata.numberGraphEdges = size(edgeIndex,2);

network.graph.metadata.bidirectional = cfg.graph.bidirectional;

%% Validation

assert(size(edgeIndex,1)==2,...
    'edgeIndex must contain exactly two rows.');

assert(size(edgeIndex,2)==length(graphEdgeMap),...
    'edgeIndex and edgeMap sizes are inconsistent.');

assert(all(edgeIndex(:)>=1),...
    'Invalid node index detected.');

%% Summary

fprintf(' Physical branches : %d\n',nBranch);

fprintf(' Graph edges : %d\n',size(edgeIndex,2));

if cfg.graph.bidirectional

    fprintf(' Graph type : Bidirectional\n');

else

    fprintf(' Graph type : Directed\n');

end

fprintf('\n');

fprintf(' Edge index successfully created.\n');

fprintf('=============================================\n');

end
