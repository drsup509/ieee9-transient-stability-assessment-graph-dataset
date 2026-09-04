function results = run_powerflow(mpc, opt)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RUN_POWERFLOW
%
% OBJECTIF
% --------
% Exécuter un calcul de Power Flow avec MATPOWER.
%
% Cette fonction est volontairement limitée au lancement du solveur.
% Toute validation physique des résultats est réalisée dans
% validate_powerflow.m.
%
% ENTREES
% -------
% mpc : Structure MATPOWER mise à jour avec le scénario généré.
%
% opt : Structure contenant les options de simulation.
%
% SORTIE
% ------
% results : Structure retournée par MATPOWER.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf(' -> Running MATPOWER Power Flow...\n');


%% MATPOWER OPTIONS
% Construction des options du solveur MATPOWER.
%

mpopt = mpoption( ...
    'verbose', opt.matpower.verbose, ...
    'out.all', 0, ...
    'pf.tol', opt.matpower.tolerance, ...
    'pf.nr.max_it', opt.matpower.maxIteration);


%% POWER FLOW
% Exécution du calcul.
%

results = runpf(mpc, mpopt);

%% INFORMATION

if results.success
    fprintf(' Power Flow converged successfully.\n');
else
    fprintf(' Power Flow did NOT converge.\n');
end

end

