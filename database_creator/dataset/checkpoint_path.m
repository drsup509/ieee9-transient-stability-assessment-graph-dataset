function cpPath = checkpoint_path(cfg)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CHECKPOINT_PATH
%
% OBJECTIF
% --------
% Retourner le chemin absolu (nom STABLE, sans horodatage) du fichier de
% checkpoint d'un dataset, pour un cas donne. Utilise par save_checkpoint
% et load_checkpoint afin qu'ils pointent vers le meme fichier.
%
% ENTREE
% ------
% - cfg : configuration (dossier de sortie + nom du cas).
%
% SORTIE
% ------
% - cpPath : chemin absolu du checkpoint.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

folder = resolve_output_folder(cfg);
fileName = sprintf('%s_checkpoint.mat', cfg.project.caseName);
cpPath = fullfile(folder, fileName);

end
