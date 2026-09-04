function apply_fault_to_model_sps(model, faultMap, network, cfg)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% APPLY_FAULT_TO_MODEL_SPS
%
% OBJECTIF
% --------
% Analogue SimPowerSystems de apply_fault_to_model. Pour un scenario
% donne, active et parametre le bloc "Three-Phase Fault" du bus concerne,
% et desactive tous les autres.
%
% Ne modifie que des blocs deja instrumentes par
% prepare_fault_infrastructure_sps. Ne touche pas a la topologie.
%
% ENTREE
% ------
% model    : nom du modele Simulink (char)
% faultMap : containers.Map bus -> chemin du bloc de defaut
% network  : structure scenario (network.fault.*)
% cfg      : configuration globale
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 1. Desactiver tous les blocs de defaut
busKeys = cell2mat(keys(faultMap));
for b = busKeys
    fp = faultMap(b);
    set_param(fp, 'FaultA', 'off', 'FaultB', 'off', 'FaultC', 'off');
    set_param(fp, 'GroundFault', 'off');
    set_param(fp, 'SwitchTimes', '[1e9 1e9+1]');
end

%% 2. Determiner le bus defaillant
%
% BUS  : network.fault.bus(1) est le bus concerne.
% LIGNE: network.fault.bus = [fromBus toBus] ; defaut applique au from-bus.
faultBus = network.fault.bus(1);

if ~isKey(faultMap, faultBus)
    error('tsa:apply_fault_sps:noBlock', ...
        'Aucun bloc de defaut SPS instrumente pour le bus %d.', faultBus);
end

%% 3. Activer et parametrer le bloc du bus defaillant
faultPath = faultMap(faultBus);

[fa, fb, fc, fg] = i_phase_selection(network.fault.type);

Rfault = max(network.fault.impedance.R, cfg.transient.fault.minResistance);

t0 = network.fault.startTime;
t1 = t0 + network.fault.duration;

set_param(faultPath, 'FaultA', fa, 'FaultB', fb, 'FaultC', fc);
set_param(faultPath, 'GroundFault', fg);
set_param(faultPath, 'SwitchTimes', sprintf('[%.6g %.6g]', t0, t1));
set_param(faultPath, 'FaultResistance',  num2str(Rfault));
set_param(faultPath, 'GroundResistance', num2str(max(Rfault, 1e-3)));

end


%% ----------------------------------------------------------------------
function [fa, fb, fc, fg] = i_phase_selection(faultType)
% Traduit le type de defaut du scenario en selection de phases du bloc
% "Three-Phase Fault" (FaultA/B/C, GroundFault).
%   3PH  : triphase non relie a la terre
%   3PHG : triphase a la terre (le plus severe)
%   LG   : monophase-terre (phase A)
%   LL   : biphase (A-B)
%   LLG  : biphase-terre (A-B-g)
switch upper(char(faultType))
    case '3PH'
        fa = 'on';  fb = 'on';  fc = 'on';  fg = 'off';
    case '3PHG'
        fa = 'on';  fb = 'on';  fc = 'on';  fg = 'on';
    case 'LG'
        fa = 'on';  fb = 'off'; fc = 'off'; fg = 'on';
    case 'LL'
        fa = 'on';  fb = 'on';  fc = 'off'; fg = 'off';
    case 'LLG'
        fa = 'on';  fb = 'on';  fc = 'off'; fg = 'on';
    otherwise
        % Repli : triphase a la terre (defaut dimensionnant).
        fa = 'on';  fb = 'on';  fc = 'on';  fg = 'on';
end
end
