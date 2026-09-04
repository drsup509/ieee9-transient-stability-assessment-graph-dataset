function network = compute_stress_index(network, results, cfg)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COMPUTE_STRESS_INDEX
%
% OBJECTIF
% --------
% Construire un indice global de stress du réseau basé sur 3 composantes :
%
% 1. Line Stress -> surcharge des lignes
% 2. Voltage Stress -> écart des tensions nominales
% 3. Generator Stress -> utilisation des capacités des générateurs
%
% Ces composantes sont combinées en un indice global pondéré :
%
% Stress = w1*Line + w2*Voltage + w3*Generator
%
% Les poids sont définis dans cfg.stress.weights
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf(' Computing stress index...\n');

%% LOAD INPUTS

% V = results.bus(:,8);
% Pd = results.bus(:,3);
% Pg = results.gen(:,2);
% Pmax = results.gen(:,9); % capacité maximale installée

define_constants;

V    = results.bus(:, VM);      % magnitude de tension (p.u.)
Pd   = results.bus(:, PD);      % puissance active demandée (MW)

Pg   = results.gen(:, PG);      % puissance active générée (MW)
Pmax = results.gen(:, PMAX);    % capacité maximale installée (MW)


%% INE STRESS

lineStress = compute_line_stress(network);

%% VOLTAGE STRESS
%

voltageStress = compute_voltage_stress(V);

%% GENERATOR STRESS
%

genStress = compute_generator_stress(Pg, Pmax);

%% GLOBAL STRESS INDEX
%

wL = cfg.stress.weights.line;
wV = cfg.stress.weights.voltage;
wG = cfg.stress.weights.generator;

% Si un composant est NaN, on l'ignore proprement
components = [lineStress, voltageStress, genStress];
weights = [wL, wV, wG];

valid = ~isnan(components);

if any(valid)

    w = weights(valid);
    c = components(valid);

    network.indices.stress.lineStress = lineStress;
    network.indices.stress.voltageStress = voltageStress;
    network.indices.stress.generatorStress = genStress;

    network.indices.stress.globalStress = sum(w .* c) / sum(w);

else

    network.indices.stress.globalStress = NaN;

end

%% SUMMARY

fprintf('   LINE STRESS         : %.3f\n', network.indices.stress.lineStress);
fprintf('   VOLTAGE STRESS     : %.3f\n', network.indices.stress.voltageStress);
fprintf('   GENERATOR STRESS     : %.3f\n', network.indices.stress.generatorStress);
fprintf('   GLOBAL STRESS    : %.3f\n',  network.indices.stress.globalStress);

fprintf(' Stress index computed.\n');

end
