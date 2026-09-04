function busbarMap = map_bus_to_busbar(model)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MAP_BUS_TO_BUSBAR
%
% OBJECTIF
% --------
% Construire la correspondance entre le numero de bus MATPOWER et le bloc
% Busbar correspondant dans le modele Simscape.
%
% La correspondance repose sur la convention de nommage des busbars du
% modele SPS : "Bus<N> ..." (ex: "Bus1 16.5kV"). Le numero <N> est
% suppose egal au numero de bus MATPOWER (verifie pour IEEE9BusSystem).
%
% ENTREE
% ------
% model : nom du modele Simulink (char)
%
% SORTIE
% ------
% busbarMap : containers.Map (cle = numero de bus, valeur = chemin bloc)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

busbarMap = containers.Map('KeyType', 'double', 'ValueType', 'char');

bb = find_system(model, 'LookUnderMasks', 'on', 'FollowLinks', 'on', ...
    'MaskType', 'Busbar');

for k = 1:numel(bb)
    name = get_param(bb{k}, 'Name');
    tok = regexp(name, 'Bus\s*(\d+)', 'tokens', 'once');
    if isempty(tok)
        continue;
    end
    busNum = str2double(tok{1});
    busbarMap(busNum) = bb{k};
end

end
