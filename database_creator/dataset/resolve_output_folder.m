function absFolder = resolve_output_folder(cfg)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RESOLVE_OUTPUT_FOLDER
%
% OBJECTIF
% --------
% Retourner un chemin ABSOLU pour le dossier de sortie du dataset et le
% creer si besoin, independamment du repertoire courant (cwd).
%
% ENTREE
% ------
% - cfg : configuration (utilise cfg.dataset.outputFolder et
%         cfg.project.rootPath).
%
% SORTIE
% ------
% - absFolder : chemin absolu (char) du dossier de sortie, garanti existant.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

outputFolder = char(cfg.dataset.outputFolder);

% Un chemin est absolu s'il commence par une lettre de lecteur (C:\) ou un
% separateur (\\serveur, /). Sinon on l'ancre a la racine du projet.
isAbsolute = ~isempty(regexp(outputFolder, '^([A-Za-z]:[\\/]|[\\/])', 'once'));

if isAbsolute
    absFolder = outputFolder;
else
    absFolder = fullfile(cfg.project.rootPath, outputFolder);
end

if ~exist(absFolder, 'dir')
    mkdir(absFolder);
end

end
