function edgeMap = conversion_bus_to_node(edgeMap, nodeMap, fromNode, ...
    toNode, nbranch)
% CONVERSION_BUS_TO_NODE  Map each branch's from/to bus numbers to node indices.

for i = 1:nbranch

    fromNode(i) = find(nodeMap.busNumber == edgeMap.fromBus(i));

    toNode(i) = find(nodeMap.busNumber == edgeMap.toBus(i));

end


edgeMap.fromNode = fromNode;

edgeMap.toNode = toNode;

end