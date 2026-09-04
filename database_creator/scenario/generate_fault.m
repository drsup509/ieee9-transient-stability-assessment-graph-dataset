function network = generate_fault(network, cfg)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GENERATE_FAULT
%
% OBJECTIF
% --------
% Générer un scénario de défaut pour l'étude de stabilité transitoire.
%
% Cette fonction est un ORCHESTRATEUR :
% elle ne réalise aucun calcul directement mais appelle une série de
% fonctions spécialisées.
%
% ETAPES
% ------
% 1) Choix du type de défaut
% 2) Choix de la localisation
% 3) Choix du timing
% 4) Choix de l'impédance
% 5) Calcul des métadonnées
%
% Cette architecture facilite l'ajout de nouveaux types de défauts
% sans modifier le reste du framework.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf(' -> Generating fault...\n');

%% ETAPE 1 : TYPE DE DEFAUT

network = choose_fault_type(network, cfg);

%% ETAPE 2 : LOCALISATION DU DEFAUT

network = choose_fault_location(network, cfg);

%% ETAPE 3 : TIMING DU DEFAUT

network = choose_fault_timing(network, cfg);

%% ETAPE 4 : IMPEDANCE DU DEFAUT

network = choose_fault_impedance(network, cfg);

%% ETAPE 5 : METADONNEES

network = compute_fault_metadata(network, cfg);

fprintf(' Fault successfully generated.\n');

end