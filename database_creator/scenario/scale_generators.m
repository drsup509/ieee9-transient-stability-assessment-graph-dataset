function network = scale_generators(network)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SCALE_GENERATORS
%
% OBJECTIF
% --------
% Appliquer les facteurs de génération définis dans
% network.scenario.areaScaling.
%
% Aucune génération aléatoire ici.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf(' -> Scaling generators...\n');

mpc = network.mpc;

areas = network.metadata.areas;

for k = 1:numel(areas)

    area = areas(k);

    genFactor = network.scenario.areaScaling(k).generationFactor;

    % buses in this area
    busIdx = (mpc.bus(:,7) == area);

    busNumbers = mpc.bus(busIdx,1);
    % fprintf('Bus #: %d \n', busNumbers);

    % generators connected to these buses
    genIdx = find(ismember(mpc.gen(:,1), busNumbers));
    % mpc.gen(:,1)
    % fprintf('genIdx: %d \n', genIdx)
    

    % scale Pgen (column 2)
    network.mpc.gen(genIdx,2) = network.mpc.gen(genIdx,2) * genFactor;

end

%%summary

network.scenario.totalGeneration = sum(network.mpc.gen(:,2));

network.scenario.generationVariation = ...
    network.scenario.totalGeneration / network.steadyState.totalGen0;

fprintf(' Generation variation: %.3f\n', ...
    network.scenario.generationVariation);

% fprintf('\n\n\n********============= ICI =========***********\n\n\n')
% network.gen
% 
% fprintf('\n\n\n********============= FIN ICI =========***********\n\n\n')

end