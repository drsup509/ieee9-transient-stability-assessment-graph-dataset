function check = validate_dynamic_results(dyn, cfg)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% VALIDATE_DYNAMIC_RESULTS
%
% OBJECTIF
% --------
% Verifier la validite numerique des resultats de la simulation
% transitoire AVANT le calcul des indices et du label.
%
% Aucune modification de donnees : la fonction retourne un diagnostic.
%
% ENTREE
% ------
% dyn : struct de import_dynamic_results
% cfg : configuration globale
%
% SORTIE
% ------
% check.ok      : true si les resultats sont exploitables
% check.reason  : motif du rejet le cas echeant
% check.reachedStopTime : la simulation a-t-elle atteint la fenetre voulue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

check = struct('ok', true, 'reason', "", 'reachedStopTime', false);

%% 1. La simulation a-t-elle produit des donnees ?

if ~isfield(dyn, 'time') || isempty(dyn.time)
    check.ok = false;
    check.reason = "NoTimeVector";
    return;
end

if ~isfield(dyn, 'delta') || isempty(dyn.delta)
    check.ok = false;
    check.reason = "NoRotorAngle";
    return;
end

%% 2. Presence de NaN / Inf

if any(~isfinite(dyn.delta(:))) || any(~isfinite(dyn.omega(:)))
    check.ok = false;
    check.reason = "NonFiniteValues";
    return;
end

%% 3. Fenetre temporelle atteinte
%
% On tolere une petite marge (le solveur variable peut s'arreter juste
% avant StopTime).

check.reachedStopTime = dyn.time(end) >= 0.98 * cfg.transient.stopTime;

if ~check.reachedStopTime
    check.ok = false;
    check.reason = "SimulationStoppedEarly";
    return;
end

end
