function network = generate_area_scaling(network, cfg)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GENERATE_AREA_SCALING
%
% OBJECTIF
% --------
% Générer les facteurs de variation des charges et de la génération
% pour chaque zone du réseau.
%
% Cette fonction ne modifie PAS le réseau.
% Elle crée uniquement la description du scénario.
%
% ENTREES
% -------
% network : structure du réseau
% cfg : configuration
%
% SORTIE
% ------
% network.scenario.areaScaling
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf(' -> Generating area scaling...\n');

%% INITIALISATION

areas = network.metadata.areas;

nAreas = numel(areas);

network.scenario.areaScaling = struct([]);

%% GENERATE SCALING FACTORS

for k = 1:nAreas

    area = areas(k);

    % Load scaling

    loadFactor = ...
        cfg.scenario.loadScaling.min + ...
        rand() * ...
        (cfg.scenario.loadScaling.max - ...
         cfg.scenario.loadScaling.min);

    % Generation scaling

    generationFactor = ...
        cfg.scenario.generatorScaling.min + ...
        rand() * ...
        (cfg.scenario.generatorScaling.max - ...
         cfg.scenario.generatorScaling.min);

    % Store scenario description

    network.scenario.areaScaling(k).area = area;

    network.scenario.areaScaling(k).loadFactor = loadFactor;

    network.scenario.areaScaling(k).generationFactor = generationFactor;

end

fprintf(' %d area(s) detected.\n', nAreas);

end
