function topology= build_topology(mpc, cfg)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% BUILD_TOPOLOGY
%
% Construction de la topologie réseau indépendante des scénarios.
%
% Entrées :
% network : structure principale du projet
% mpc : réseau MATPOWER
% cfg : configuration projet
%
% Sortie :
% network.topology
%
% Cette fonction crée :
% - nodeMap : correspondance bus MATPOWER -> node interne
% - edgeMap : correspondance branch MATPOWER -> edge interne
% - informations topologiques
% - matrice d'adjacence
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('\n');
fprintf('=============================================\n');
fprintf(' Building network topology...\n');
fprintf('=============================================\n');


%% INITIALIZATION

nbus = size(mpc.bus,1);
nbranch = size(mpc.branch,1);


topology = struct();


%% METADATA

topology.metadata.caseName = cfg.project.caseName;

topology.metadata.creationDate = datestr(now);

topology.metadata.numberBuses = nbus;

topology.metadata.numberBranches = nbranch;

topology.metadata.isDirected = cfg.graph.bidirectional;



%% NODE MAP INITIALISATION

nodeMap = table();

nodeMap.nodeID = (1:nbus)';
nodeMap.busNumber = mpc.bus(:,1);

%% Node map creator

nodeMap = node_map(mpc, nodeMap);

%% Generator association

nodeMap = generator_map(mpc, nbus, nodeMap);



%% Load association

nodeMap = load_map(mpc, nbus, nodeMap);

topology.nodeMap = nodeMap;



%% EDGE MAP

edgeMap = table();

edgeMap.edgeID = (1:nbranch)';
edgeMap.branchID = (1:nbranch)';

edgeMap.fromBus = mpc.branch(:,1);
edgeMap.toBus = mpc.branch(:,2);



%% Conversion Bus -> Node

fromNode = zeros(nbranch,1);
toNode = zeros(nbranch,1);

edgeMap = conversion_bus_to_node(edgeMap, nodeMap, fromNode, toNode, nbranch);



%% Electrical parameters

edgeMap = import_electrical_param(edgeMap, mpc);

topology.edgeMap = edgeMap;



%% Adjacency matrix

A = corresponding_adjency_matrix(edgeMap, nbus, nbranch);

topology.matrices.adjacency = A;

%% Validate topology

validate_topology(topology)

%% Visualisation de la topologie

G = visualize_topology(A, topology, nodeMap);

%% Connected components

validate_topology_connection(G);


%% Summary

fprintf(' Number of buses : %d\n',nbus);

fprintf(' Number of branches : %d\n',nbranch);

fprintf(' Topology completed.\n');


end
