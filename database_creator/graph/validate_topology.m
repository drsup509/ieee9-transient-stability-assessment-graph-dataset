function validate_topology(topology)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% VALIDATE_TOPOLOGY
%
% Validate the consistency of the network topology.
%
% Inputs:
% topology : topology structure created by build_topology()
%
% This function verifies:
% - uniqueness of node IDs
% - uniqueness of bus numbers
% - uniqueness of edge IDs
% - uniqueness of branch IDs
% - validity of node references
% - symmetry of adjacency matrix
% - absence of isolated buses
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('\n');
fprintf('=============================================\n');
fprintf(' Validating network topology...\n');
fprintf('=============================================\n');

nodeMap = topology.nodeMap;
edgeMap = topology.edgeMap;
A = topology.matrices.adjacency;

nbus = height(nodeMap);
nbranch = height(edgeMap);

%% ------------------------------------------------------------------------
% Node IDs
%% ------------------------------------------------------------------------

assert(length(unique(nodeMap.nodeID)) == nbus,...
    'Duplicate node IDs detected.');

fprintf(' [OK] Node IDs are unique.\n');

%% ------------------------------------------------------------------------
% Bus numbers
%% ------------------------------------------------------------------------

assert(length(unique(nodeMap.busNumber)) == nbus,...
    'Duplicate bus numbers detected.');

fprintf(' [OK] Bus numbers are unique.\n');

%% ------------------------------------------------------------------------
% Edge IDs
%% ------------------------------------------------------------------------

assert(length(unique(edgeMap.edgeID)) == nbranch,...
    'Duplicate edge IDs detected.');

fprintf(' [OK] Edge IDs are unique.\n');

%% ------------------------------------------------------------------------
% Branch IDs
%% ------------------------------------------------------------------------

assert(length(unique(edgeMap.branchID)) == nbranch,...
    'Duplicate branch IDs detected.');

fprintf(' [OK] Branch IDs are unique.\n');

%% ------------------------------------------------------------------------
% Node references
%% ------------------------------------------------------------------------

assert(all(edgeMap.fromNode>=1 & edgeMap.fromNode<=nbus),...
    'Invalid fromNode indices.');

assert(all(edgeMap.toNode>=1 & edgeMap.toNode<=nbus),...
    'Invalid toNode indices.');

fprintf(' [OK] Node references are valid.\n');

%% ------------------------------------------------------------------------
% Adjacency matrix symmetry
%% ------------------------------------------------------------------------

assert(issymmetric(A),...
    'Adjacency matrix is not symmetric.');

fprintf(' [OK] Adjacency matrix is symmetric.\n');

%% ------------------------------------------------------------------------
% Isolated buses
%% ------------------------------------------------------------------------

degree = sum(A,2);

isolated = find(degree==0);

assert(isempty(isolated),...
    'Isolated buses detected.');

fprintf(' [OK] No isolated buses detected.\n');

%% ------------------------------------------------------------------------
% Summary
%% ------------------------------------------------------------------------

fprintf('\n');
fprintf('Topology summary\n');
fprintf('-----------------------------\n');
fprintf(' Number of buses : %d\n',nbus);
fprintf(' Number of branches : %d\n',nbranch);
fprintf(' Number of generators : %d\n',sum(~isnan(nodeMap.generatorID)));
fprintf(' Number of loads : %d\n',sum(~isnan(nodeMap.loadID)));

fprintf('\n');
fprintf('Topology validation PASSED.\n');
fprintf('=============================================\n');

end
