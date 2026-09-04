function network = scale_loads(network)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SCALE_LOADS
%
% OBJECTIF
% --------
% Appliquer les facteurs de charge définis dans
% network.scenario.areaScaling.
%
% Aucune génération aléatoire n'est effectuée ici.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf(' -> Scaling loads...\n');

areas = network.metadata.areas;

for k = 1:numel(areas)

    area = areas(k);

    % retrieve factor
    loadFactor = network.scenario.areaScaling(k).loadFactor;

    % select buses in area
    idx = find(network.mpc.bus(:,7) == area);

    % scale active + reactive loads
    % en appliquant même facteur de charge on garde le facteur de puissance
    % constant
    network.mpc.bus(idx,3) = network.mpc.bus(idx,3) * loadFactor;
    network.mpc.bus(idx,4) = network.mpc.bus(idx,4) * loadFactor;

end

%%totals for analysis

network.scenario.totalLoad = sum(network.mpc.bus(:,3));

network.scenario.loadVariation = ...
    network.scenario.totalLoad / network.steadyState.totalLoad0;

fprintf(' Load variation: %.3f\n', network.scenario.loadVariation);

% fprintf('\n\n\n********============= ICI LOADS =========***********\n\n\n')
% network.mpc.bus
% 
% fprintf('\n\n\n********============= FIN ICI LOADS =========***********\n\n\n')


end