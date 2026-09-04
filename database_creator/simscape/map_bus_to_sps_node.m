function nodeMap = map_bus_to_sps_node(model)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MAP_BUS_TO_SPS_NODE
%
% OBJECTIF
% --------
% Construire la correspondance entre le numero de bus MATPOWER et le
% sous-systeme "noeud triphase" correspondant dans un modele
% SimPowerSystems (powerlib), analogue SPS de map_bus_to_busbar.
%
% CONVENTION (NE39)
% -----------------
% Chaque bus est un sous-systeme de premier niveau nomme d'apres son
% numero (ex. "NE39bus2_PQ/16"), de type "Three-Phase VI Measurement",
% expose 3 bornes physiques LConn (A,B,C) et 3 bornes RConn (A,B,C).
% Le numero du sous-systeme est suppose egal au numero de bus MATPOWER.
%
% ENTREE
% ------
% model : nom du modele Simulink (char), deja charge en memoire
%
% SORTIE
% ------
% nodeMap : containers.Map (cle = numero de bus, valeur = chemin du bloc)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

nodeMap = containers.Map('KeyType', 'double', 'ValueType', 'char');

tl = find_system(model, 'SearchDepth', 1, 'BlockType', 'SubSystem');

for k = 1:numel(tl)
    name = get_param(tl{k}, 'Name');

    % Nom = entier pur (numero de bus). Rejette tout sous-systeme nomme.
    if isempty(regexp(name, '^\s*\d+\s*$', 'once'))
        continue;
    end

    % Doit exposer au moins 3 bornes physiques par cote (noeud triphase).
    ph = get_param(tl{k}, 'PortHandles');
    if numel(ph.RConn) < 3
        continue;
    end

    busNum = str2double(strtrim(name));
    nodeMap(busNum) = tl{k};
end

end
