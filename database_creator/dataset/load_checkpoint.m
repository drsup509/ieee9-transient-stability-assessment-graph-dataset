function [dataset, startIndex] = load_checkpoint(cfg)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LOAD_CHECKPOINT
%
% OBJECTIF
% --------
% Charger, s'il existe, le checkpoint d'un dataset pour reprendre un run
% interrompu. Ne recalcule rien : renvoie le dataset partiel et l'indice
% du dernier scenario deja traite.
%
% ENTREE
% ------
% - cfg : configuration (dossier de sortie + nom du cas).
%
% SORTIES
% -------
% - dataset    : dataset partiel charge, ou [] si aucun checkpoint.
% - startIndex : indice du dernier scenario traite (0 si aucun checkpoint).
%                La boucle reprend a startIndex+1.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

dataset = [];
startIndex = 0;

cpPath = checkpoint_path(cfg);

if ~exist(cpPath, 'file')
    return;
end

loaded = load(cpPath, 'dataset');

if ~isfield(loaded, 'dataset')
    warning('tsa:load_checkpoint:invalid', ...
        'Checkpoint "%s" invalide (pas de champ dataset). Ignore.', cpPath);
    return;
end

dataset = loaded.dataset;

if isfield(dataset, 'progress') && isfield(dataset.progress, 'lastScenario')
    startIndex = dataset.progress.lastScenario;
else
    % Compatibilite : deduire l'avancement du compteur total.
    startIndex = dataset.statistics.total;
end

fprintf(' [checkpoint] Reprise depuis le scenario %d (%s)\n', ...
    startIndex, cpPath);

end
