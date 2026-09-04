function network = compute_voltage_margin(network, results, cfg)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COMPUTE_VOLTAGE_MARGIN
%
% OBJECTIF
% --------
% Calculer plusieurs indicateurs décrivant la marge de fonctionnement
% des tensions du réseau à partir des résultats du Power Flow.
%
% Les indicateurs calculés sont :
%
% 1. Minimum Voltage Margin
% -> Distance entre la plus faible tension et la limite basse.
%
% 2. Maximum Voltage Margin
% -> Distance entre la plus forte tension et la limite haute.
%
% 3. Average Voltage Deviation (AVD)
% -> Déviation moyenne des tensions par rapport à la tension nominale
% (1.0 p.u.).
%
% Ces indices permettent d'évaluer la qualité du profil de tension du
% réseau avant l'apparition d'un défaut.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf(' Computing voltage margin...\n');

%% VOLTAGES

V = results.bus(:,8); % VM dans MATPOWER

%% VOLTAGE LIMITS

Vmin = cfg.powerflow.validation.accepted.minVoltage;
Vmax = cfg.powerflow.validation.accepted.maxVoltage;


%% ================================================================
%% 1. MINIMUM VOLTAGE MARGIN
%
% Mesure la distance entre la tension minimale observée
% et la limite basse admissible.
%
% Valeur positive :
% Toutes les tensions respectent la limite.
%
% Valeur négative :
% Au moins un bus viole la limite basse.
%
%===============================================================

network.indices.voltageMargin.minimumMargin = min(V) - Vmin;

%% ================================================================
%% 2. MAXIMUM VOLTAGE MARGIN
%
% Mesure la distance entre la limite haute
% et la tension maximale observée.
%
% Valeur positive :
% Toutes les tensions respectent la limite.
%
% Valeur négative :
% Au moins un bus dépasse la limite haute.
%
%===============================================================

network.indices.voltageMargin.maximumMargin = Vmax - max(V);

%% ================================================================
%% 3. AVERAGE VOLTAGE DEVIATION
%
% Mesure l'écart moyen des tensions par rapport
% à la tension nominale (1 p.u.).
%
% Plus cette valeur est faible,
% meilleur est le profil de tension du réseau.
%
%===============================================================

network.indices.voltageMargin.averageDeviation = mean(abs(V - 1));

%% STATUS

%% SUMMARY

fprintf('   Minimum voltage margin          : %.3f\n', network.indices.voltageMargin.minimumMargin);
fprintf('   Maximum voltage margin     : %.3f\n', network.indices.voltageMargin.maximumMargin);
fprintf('   Average voltage deviation     : %.3f\n', network.indices.voltageMargin.averageDeviation);

fprintf(' Voltage margin computed.\n');

end
