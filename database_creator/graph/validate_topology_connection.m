function validate_topology_connection(G)
% VALIDATE_TOPOLOGY_CONNECTION  Assert the network graph is a single connected component.

bins = conncomp(G);

nComponents = max(bins);

assert(nComponents == 1,...
    'Topology contains %d disconnected components.',nComponents);

fprintf(' [OK] Graph is connected.\n');

end