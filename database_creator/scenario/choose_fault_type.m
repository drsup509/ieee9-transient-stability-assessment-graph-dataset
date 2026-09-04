function network = choose_fault_type(network, cfg)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CHOOSE_FAULT_TYPE
%
% OBJECTIF
% --------
% Sélectionner le type de défaut à appliquer au réseau.
%
% Cette fonction est volontairement indépendante afin de pouvoir ajouter
% facilement de nouveaux types de défauts sans modifier le reste du
% framework.
%
% TYPES ENVISAGÉS
% ---------------
% 3PH : Défaut triphasé
% LG : Monophasé à la terre
% LL : Biphasé
% LLG : Biphasé à la terre
%
% Pour le moment, seul le défaut triphasé est utilisé car il est le plus
% sévère et le plus étudié dans la littérature TSA.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf(' Selecting fault type...\n');

%% AVAILABLE FAULT TYPES%
% Les types de défaut sont définis dans le fichier config.m.


faultTypes = cfg.fault.availableTypes;

probabilities = cfg.fault.typeProbability;

%% RANDOM SELECTION
% Sélection aléatoire du type de défaut selon les probabilités définies.


index = randsample(length(faultTypes), 1, true, probabilities);

network.fault.type = faultTypes(index);


%% STATUS
% Indique que le défaut est valide et prêt à être utilisé.

network.fault.status = "Generated";

fprintf(' Fault type : %s\n', network.fault.type);

end
