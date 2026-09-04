function A = corresponding_adjency_matrix(edgeMap, nbus, nbranch)
% CORRESPONDING_ADJENCY_MATRIX  Build the nbus-by-nbus adjacency matrix from the edge map.

A = zeros(nbus,nbus);

fromNode = edgeMap.fromNode;

toNode = edgeMap.toNode;


for i = 1:nbranch

    f = fromNode(i);
    t = toNode(i);

    A(f,t)=1;
    A(t,f)=1;

end

end