function checkpointPath = save_checkpoint(dataset, cfg)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SAVE_CHECKPOINT
%
% OBJECTIF
% --------
% Ecrire un checkpoint du dataset en cours de generation dans un fichier
% au NOM STABLE (ecrase le precedent). Permet de reprendre un long run
% interrompu sans perdre la progression.
%
% ENTREES
% -------
% - dataset : structure du dataset en cours.
% - cfg     : configuration (dossier de sortie + nom du cas).
%
% SORTIE
% ------
% - checkpointPath : chemin absolu du checkpoint ecrit.
%
% NB : nom stable (sans horodatage) pour que load_checkpoint le retrouve.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

checkpointPath = checkpoint_path(cfg);

dataset.metadata.checkpointTime = datetime("now");

% Ecriture atomique : fichier temporaire puis renommage, pour ne pas
% corrompre le checkpoint si l'ecriture est interrompue.
tmpPath = [checkpointPath '.tmp'];
save(tmpPath, 'dataset', '-v7.3');
if exist(checkpointPath, 'file')
    delete(checkpointPath);
end
movefile(tmpPath, checkpointPath);

fprintf(' [checkpoint] %d scenario(s) -> %s\n', ...
    dataset.progress.lastScenario, checkpointPath);

end
