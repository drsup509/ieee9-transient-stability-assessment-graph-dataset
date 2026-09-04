function network = compute_indices(network, results, cfg)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COMPUTE_INDICES
%
% OBJECTIF
% --------
% Calculer les principaux indices électriques du réseau à partir des
% résultats du Power Flow.
%
% Cette fonction ne modifie jamais le réseau.
% Elle calcule uniquement des indicateurs destinés au dataset.
%
% ENTREES
% -------
% network : structure du réseau
% results : résultats MATPOWER
%
% SORTIE
% ------
% network : structure mise à jour avec les indices
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf(' -> Computing network indices...\n');
% disp(dbstack); %fonction ayant appeler la courante

%% NETWORK SIZE

nbus = size(results.bus,1);
nbranch = size(results.branch,1);
ngen = size(results.gen,1);

network.indices.numberBuses = nbus;
network.indices.numberBranches = nbranch;
network.indices.numberGenerators = ngen;

%% LOSS RATIO
%
% Mesure la proportion des pertes actives dans le réseau.
%
network = compute_loss_ratio(network, results);

%% LOAD DIVERSITY

network = compute_load_diversity(network, results, cfg);

%% VOLTAGE STATISTICS

% V = results.bus(:,8);
% 
% network.indices.minVoltage = min(V);
% network.indices.maxVoltage = max(V);
% network.indices.meanVoltage = mean(V);
% network.indices.stdVoltage = std(V);

network = compute_voltage_stats(network, results);

%% LINE LOADING
%
% Mesure le taux de chargement des lignes de transport. 
% Fait avant la % dalidation du powerflow car paramètre utilisé 
% pour validation
%

% if size(results.branch,2) >= 14
% 
%     fprintf('\nlineloading\n\n');
%     lineLoading = compute_line_loading(results);
% 
%     network.indices.lineLoading.vector = lineLoading.vector*100;
%     network.indices.lineLoading.maxLineLoading = lineLoading.maximum;
%     network.indices.lineLoading.meanLineLoading = lineLoading.mean;
%     network.indices.lineLoading.stdLineLoading = lineLoading.std;
% 
%     network.indices
%     fprintf('\nfin lineloading\n\n');
% 
% else
% 
%     % network.indices.maxLineLoading = NaN;
%     % network.indices.meanLineLoading = NaN;
%     % network.indices.stdLineLoading = NaN;
% 
%     network.indices.lineLoading.maxLineLoading = NaN;
%     network.indices.lineLoading.meanLineLoading = NaN;
%     network.indices.lineLoading.stdLineLoading = NaN;
% 
% end

% fprintf('Compute line loading\n\n')
% 
% network = compute_line_loading(network, results);
% 
% fprintf(' Fin Compute line loading\n\n')





%% STRESS INDEX
% 
% Hypothèse: ligne loading déjà calculée
% Moyenne pondérée de Line Stress, Voltage Stress et Generator Stress
% Poids définis dans config
% 

network = compute_stress_index(network, results, cfg);

%% Voltage margin
% 
% On pourrait utiliser une moyenne pondérée considérant les différentes
% marge. Ou bien on pourrait étudier des corrélations pour faire ressortir
% des tendances
% 

network = compute_voltage_margin(network, results, cfg);


%% NETWORK DENSITY
%
% Densité du graphe non orienté
%

if nbus > 1
    network.indices.networkDensity = ...
        2*nbranch / (nbus*(nbus-1));
else
    network.indices.networkDensity = NaN;
end

%% TOTAL INERTIA
%
% Somme des constantes d'inertie des générateurs
%

if isfield(network,'generators') && ...
   isfield(network.generators,'H') && ...
   ~isempty(network.generators.H)

    network.indices.inertia = sum(network.generators.H);

else

    network.indices.inertia = NaN;

end

%% SUMMARY

fprintf('\n----- SUMMARY -- Compute indice lineloading -----\n');
fprintf(' Buses : %d\n', nbus);
fprintf(' Branches : %d\n', nbranch);
fprintf(' Generators : %d\n', ngen);

fprintf(' Min Voltage : %.3f pu\n', network.indices.voltageStats.minVoltage);
fprintf(' Max Voltage : %.3f pu\n', network.indices.voltageStats.maxVoltage);

fprintf(' Loss Ratio : %.4f\n',network.indices.lossRatio.lossratio_pu);

fprintf(' Loading max: %.4f\n', network.indices.lineLoading.maxLineLoading);
fprintf(' Loading mean: %.4f\n', network.indices.lineLoading.meanLineLoading);
fprintf(' Loading std: %.4f\n', network.indices.lineLoading.stdLineLoading);
fprintf('----------------------------------\n');

fprintf(' Indices computed successfully.\n');



%% FUTURE INDICES
%
% Les indices suivants pourront être ajoutés progressivement :
%
% - Short-circuit level
% - Electrical distance
% - Network centrality
% - Generator electrical proximity
% - Inertia metrics
% - Renewable penetration
%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COMPUTE_INITIAL_INDICES
%
% OBJECTIF
% --------
% Calculer tous les indices physiques pouvant être obtenus à partir
% du régime permanent (steady-state) avant toute simulation dynamique.
%
% Ces indices enrichissent la structure network.indices et serviront à :
%
% - l'analyse exploratoire du dataset ;
% - la sélection et la validation des scénarios ;
% - la construction des features des modèles GNN ;
% - l'interprétation physique des scénarios.
%
% IMPORTANT
% ---------
% Cette fonction ne modifie pas le réseau électrique.
%
% Elle calcule uniquement des indicateurs dérivés à partir des résultats
% du Power Flow.
%
% Les indices issus de la simulation de stabilité transitoire (TSA)
% seront calculés ultérieurement dans :
%
% compute_dynamic_indices.m
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




end
