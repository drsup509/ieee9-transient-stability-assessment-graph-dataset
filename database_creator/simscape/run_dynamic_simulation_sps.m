function network = run_dynamic_simulation_sps(network, faultMap, cfg)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RUN_DYNAMIC_SIMULATION_SPS
%
% OBJECTIF
% --------
% Analogue SimPowerSystems de run_dynamic_simulation. Orchestre la
% simulation transitoire d'UN scenario sur un modele SPS (phasor) et
% produit le MEME champ network.transient que le backend ee (contrat
% identique : les fonctions en aval - indices, label, augmentation - sont
% partagees et inchangees).
%
% ETAPES
% ------
% 1) Verification de licence
% 2) Application du defaut (apply_fault_to_model_sps)
% 3) Configuration (configure_simulation_sps)
% 4) Simulation (sim)
% 5) Import des resultats (import_dynamic_results_sps)
% 6) Validation (validate_dynamic_results, partagee)
% 7) Indices dynamiques (compute_dynamic_indices, partagee)
% 8) Label de stabilite (compute_stability_label, partagee)
%
% ENTREE
% ------
% network  : structure scenario (contient network.fault)
% faultMap : containers.Map bus -> bloc de defaut (prepare..._sps)
% cfg      : configuration globale
%
% SORTIE
% ------
% network.transient : identique en structure au backend ee.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf(' -> Running SPS transient simulation...\n');

network.transient = struct('success', false, 'reason', "");

model = cfg.simulation.modelName;

%% 1. LICENCE / BACKEND
assert_transient_backend(model, cfg);

if ~(license('test', 'Simscape') || license('test', 'Simscape_Electrical') ...
        || license('test', 'Power_System_Blocks'))
    error('tsa:transient:noLicense', ...
        ['SimPowerSystems / Simscape indisponible : simulation ' ...
         'transitoire impossible. Utiliser un MATLAB avec licence Simscape Electrical.']);
end

%% 2. APPLIQUER LE DEFAUT
apply_fault_to_model_sps(model, faultMap, network, cfg);

%% 3-4. CONFIGURER ET SIMULER
simIn = configure_simulation_sps(model, cfg);
out   = sim(simIn);

%% 5. IMPORTER LES RESULTATS
dyn = import_dynamic_results_sps(out, cfg);

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

network.transient.success  = true;
network.transient.indices  = indices;
network.transient.label    = label;
network.transient.time     = dyn.time;
network.transient.genNames = dyn.genNames;
network.transient.delta    = dyn.delta;
network.transient.omega    = dyn.omega;

fprintf('    Label: %s (max sep = %.1f deg, margin = %.1f deg)\n', ...
    label.status, label.maxSeparation, label.margin);

end
