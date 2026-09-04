function network = compute_load_diversity(network, results, cfg)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COMPUTE_LOAD_DIVERSITY
%
% OBJECTIF
% --------
% Calculer plusieurs indicateurs complémentaires décrivant la
% diversité spatiale des charges du réseau.
%
% Les indices calculés sont :
%
% 1. Coefficient de variation (CV)
% -> mesure la dispersion des charges entre les bus.
%
% 2. Entropie de Shannon
% -> mesure le degré d'uniformité de la répartition des charges.
%
% 3. Diversité par zones (Area Diversity)
% -> mesure la dispersion des charges entre les différentes zones
% géographiques du réseau.
%
% Ces indices serviront :
%
% - à l'analyse exploratoire du dataset ;
% - à la validation des scénarios ;
% - comme futures features globales des modèles GNN ;
% - à l'interprétation physique des scénarios.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf(' Computing load diversity...\n');

define_constants;

%% LOADS

Pd     = results.bus(:, PD);
Qd     = results.bus(:, QD);
% areaID = results.bus(:, BUS_AREA);

%% =======================================================================
%% COEFFICIENT OF VARIATION (CV)

network = compute_coefficient_variation (network, Pd, Qd);

%% =======================================================================
%%% SHANNON ENTROPY

network = compute_entropy_shannon(network, Pd, Qd);

%% =======================================================================
%% AREA DIVERSITY

network = compute_load_area_diversity(network, Pd, Qd);

%% STATUS

% network.indices.loadDiversity.status = "Complete";

%% SUMMARY

fprintf('   CV(P)          : %.3f\n', network.indices.loadDiversityP.cvP);
fprintf('   Entropy(P)     : %.3f\n', network.indices.loadDiversityP.entropyP);
fprintf('   Area CV(P)     : %.3f\n', network.indices.loadDiversityP.areaCVP);




fprintf(' Load diversity computed.\n');

end
