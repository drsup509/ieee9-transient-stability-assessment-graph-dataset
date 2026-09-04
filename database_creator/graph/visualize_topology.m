function G = visualize_topology(A, topology, nodeMap)
% VISUALIZE_TOPOLOGY  Plot the network topology from its adjacency matrix and node map.

fprintf(' Generating topology graph...\n');

G = graph(A);

figure('Name','Network Topology','Color','w');

tiledlayout(1,2,'TileSpacing','compact','Padding','compact');

% Tuile 1
nexttile;
imagesc(topology.matrices.adjacency);
axis tight;
xlabel('Bus Index');
ylabel('Bus Index');
% colorbar;
title('Adjacency Matrix');

% Tuile 2
nexttile;
plot(G,...
    'Layout','force',...
    'NodeLabel',nodeMap.busNumber,...
    'LineWidth',1.5,...
    'MarkerSize',7);

title('Network Topology');

fprintf(' [OK] Graph visualization completed.\n');

end