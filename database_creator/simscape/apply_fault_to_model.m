function apply_fault_to_model(model, faultMap, network, cfg)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% APPLY_FAULT_TO_MODEL
%
% OBJECTIF
% --------
% Configurer, pour un scenario donne, le bloc de defaut du bus concerne
% (timing et duree), et remettre a zero tous les autres blocs de defaut.
%
% Cette fonction ne fait que parametrer des blocs deja instrumentes par
% prepare_fault_infrastructure. Elle ne modifie pas la topologie.
%
% ENTREE
% ------
% model    : nom du modele Simulink (char)
% faultMap : containers.Map bus -> chemin du bloc de defaut
% network  : structure scenario (network.fault.*)
% cfg      : configuration globale
%
% CHOIX DE LOCALISATION
% ---------------------
% - Defaut sur BUS  : bloc du bus concerne.
% - Defaut sur LIGNE: applique au bus d'origine (from-bus) de la ligne.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 1. Reinitialiser tous les blocs de defaut (declenchement hors fenetre)
%
% Le bloc ee exige une duree > 0 : on rend un bloc inactif en programmant
% son declenchement tres loin dans le futur (jamais atteint).

busKeys = cell2mat(keys(faultMap));
for b = busKeys
    set_param(faultMap(b), 'fault_start_time', '1e9');
    set_param(faultMap(b), 'fault_duration', '1e-3');
end

%% 2. Determiner le bus defaillant
%
% BUS  : network.fault.bus(1) est le bus concerne.
% LIGNE: network.fault.bus = [fromBus toBus] ; on applique le defaut au
%        bus d'origine (from-bus), soit egalement bus(1).

faultBus = network.fault.bus(1);

if ~isKey(faultMap, faultBus)
    error('tsa:apply_fault:noBlock', ...
        'Aucun bloc de defaut instrumente pour le bus %d.', faultBus);
end

%% 3. Activer et parametrer le bloc du bus defaillant
%
% Le TYPE de defaut et l'IMPEDANCE proviennent du scenario (choose_fault_*)
% et sont propages au bloc ee :
%   - type      -> fault_type_option (via la table de correspondance config)
%   - impedance -> R_pn_fault / R_ng_fault (plancher minResistance car le
%                  bloc exige des resistances strictement positives).

faultPath = faultMap(faultBus);

faultOption = map_fault_type_to_option(network.fault.type, cfg);

Rfault = max(network.fault.impedance.R, cfg.transient.fault.minResistance);

set_param(faultPath, 'fault_type_option', num2str(faultOption));
set_param(faultPath, 'R_pn_fault', num2str(Rfault));
set_param(faultPath, 'R_ng_fault', num2str(Rfault));
set_param(faultPath, 'fault_start_time', num2str(network.fault.startTime));
set_param(faultPath, 'fault_duration', num2str(network.fault.duration));

end
