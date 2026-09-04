function network = run_dynamic_simulation(network, faultMap, cfg)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RUN_DYNAMIC_SIMULATION
%
% OBJECTIF
% --------
% Orchestrer la simulation transitoire d'UN scenario et produire le label
% de stabilite. Cette fonction ne calcule rien elle-meme : elle enchaine
% des fonctions specialisees.
%
% ETAPES
% ------
% 1) Verification de licence (Simscape Electrical)
% 2) Application du defaut au modele (apply_fault_to_model)
% 3) Configuration de la simulation (configure_simulation)
% 4) Simulation (sim)
% 5) Import des resultats (import_dynamic_results)
% 6) Validation numerique (validate_dynamic_results)
% 7) Indices dynamiques (compute_dynamic_indices)
% 8) Label de stabilite (compute_stability_label)
%
% ENTREE
% ------
% network  : structure scenario (contient network.fault)
% faultMap : containers.Map bus -> bloc de defaut (prepare_fault_infrastructure)
% cfg      : configuration globale
%
% SORTIE
% ------
% network.transient.success   : la simulation a-t-elle produit un label
% network.transient.reason     : motif d'echec le cas echeant
% network.transient.indices     : indices dynamiques (si succes)
% network.transient.label        : label de stabilite (si succes)
% network.transient.time         : Nt x 1 base temporelle [s] (si succes)
% network.transient.genNames     : 1 x nGen noms des machines (si succes)
% network.transient.delta        : Nt x nGen angle rotorique [rad] (si succes)
% network.transient.omega        : Nt x nGen vitesse rotorique [pu] (si succes)
%
% LICENCE
% -------
% Requiert Simscape Electrical (MATLAB avec licence Simscape Electrical).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf(' -> Running transient simulation...\n');

network.transient = struct('success', false, 'reason', "");

% DISPATCH BACKEND : si le modèle est SimPowerSystems (ex. NE39), déléguer
% au simulateur SPS. Le chemin Simscape Electrical ci-dessous reste
% strictement inchangé (IEEE9BusSystem).
if strcmp(assert_transient_backend(cfg.simulation.modelName, cfg), 'sps-powerlib')
    network = run_dynamic_simulation_sps(network, faultMap, cfg);
    return;
end

%% 1. LICENCE
%
% Le simulateur necessite Simscape (+ Simscape Electrical / ee_lib).
% NB : license('test','Simscape_Electrical') peut renvoyer 0 meme quand
% la licence reseau est disponible (checkout paresseux). On teste donc la
% licence Simscape de base ET la capacite a charger ee_lib.

if ~(license('test', 'Simscape') || license('test', 'Simscape_Electrical'))
    i_license_hint();
    error('tsa:transient:noLicense', ...
        ['Simscape indisponible : simulation transitoire impossible. ' ...
         'Utiliser un MATLAB avec licence Simscape Electrical.']);
end

if ~i_ee_available()
    i_license_hint();
    error('tsa:transient:noSimscapeElectrical', ...
        ['Simscape Electrical (ee_lib) indisponible : simulation ' ...
         'transitoire impossible. Utiliser un MATLAB avec licence Simscape Electrical.']);
end

model = cfg.simulation.modelName;

%% 1b. BACKEND
%
% Garde-fou : vérifier que le modèle est compatible avec le backend
% transitoire (Simscape Electrical). Échoue clairement sinon (ex. NE39/SPS).

assert_transient_backend(model, cfg);

%% 2. APPLIQUER LE DEFAUT

apply_fault_to_model(model, faultMap, network, cfg);

%% 3-4. CONFIGURER ET SIMULER

simIn = configure_simulation(model, cfg);
out   = sim(simIn);

%% 5. IMPORTER LES RESULTATS

dyn = import_dynamic_results(out, cfg);

%% 6. VALIDER

check = validate_dynamic_results(dyn, cfg);
if ~check.ok
    network.transient.success = false;
    network.transient.reason  = check.reason;
    fprintf('    Transient rejected: %s\n', check.reason);
    return;
end

%% 7-8. INDICES ET LABEL

indices = compute_dynamic_indices(dyn, cfg);
label   = compute_stability_label(indices, cfg);

network.transient.success = true;
network.transient.indices = indices;
network.transient.label   = label;
network.transient.time    = dyn.time;
network.transient.genNames = dyn.genNames;

% Series temporelles rotoriques par machine (Nt x nGen), ordonnees comme
% dyn.genNames : delta = angle electrique rotorique [rad] (absolu),
% omega = vitesse rotorique [pu]. Utiles pour l'apprentissage (features
% GNN/PINN) et le rejeu des trajectoires.
network.transient.delta = dyn.delta;
network.transient.omega = dyn.omega;

% Couche ADDITIVE (augmentation non destructive) : ces champs enrichissent
% l'enregistrement SANS modifier delta/omega/label. Ils permettent la
% trajectoire de tension V(t), la puissance electrique Pe(t) et le residu
% de l'equation d'oscillation. Ordres : V/Vangle par bus (dyn.busNumbers),
% Pe/Pm/Te par machine (dyn.genNames).
network.transient.V          = dyn.V;
network.transient.Vangle     = dyn.Vangle;
network.transient.busNumbers = dyn.busNumbers;
network.transient.busNames   = dyn.busNames;
network.transient.Pe         = dyn.Pe;
network.transient.Pm         = dyn.Pm;
network.transient.Te         = dyn.Te;

% Residu de l'equation d'oscillation classique (prior physique PINN/PIGNN),
% par machine et par pas de temps : r_i = 2 H_i domega/dt - (Pm - Pe - D_i(w-1)).
% Champ ADDITIF : calcule sur la trajectoire detaillee, donc non nul par
% construction (mesure l'ecart au modele classique). N'affecte pas le label.
try
    [swRes, swResRMS] = compute_swing_residual(dyn, cfg);
    network.transient.swingResidual    = swRes;      % Nt x nGen [pu]
    network.transient.swingResidualRMS = swResRMS;   % 1 x nGen  [pu]
catch ME
    network.transient.swingResidual    = [];
    network.transient.swingResidualRMS = zeros(1,0);
    fprintf('    [swing residual skipped: %s]\n', ME.message);
end

fprintf('    Label: %s (max sep = %.1f deg, margin = %.1f deg)\n', ...
    label.status, label.maxSeparation, label.margin);

end


%% ----------------------------------------------------------------------
function tf = i_ee_available()
% Verifie que la bibliotheque Simscape Electrical (ee_lib) est chargeable.
tf = true;
try
    if ~bdIsLoaded('ee_lib')
        load_system('ee_lib');
    end
catch
    tf = false;
end
end


%% ----------------------------------------------------------------------
function i_license_hint()
% Affiche l'etat des licences pertinentes et l'environnement MATLAB.
fprintf('\n[LICENCE] Simscape           : %d\n', license('test','Simscape'));
fprintf('[LICENCE] Simscape_Electrical: %d\n', license('test','Simscape_Electrical'));
fprintf('[LICENCE] MATLAB root        : %s\n', matlabroot);
fprintf('[LICENCE] Release            : %s\n', version('-release'));
fprintf(['[LICENCE] Correctif : lancer avec un MATLAB disposant de ' ...
    'Simscape Electrical.\n\n']);
end
