function save_dataset(dataset, cfg)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SAVE_DATASET
%
% OBJECTIF
% --------
% Sauvegarder le dataset complet généré.
%
% SORTIES POSSIBLES
% ------------------
% - .mat (MATLAB natif)
% - structure prête export Python
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('\n========================================\n');
fprintf(' SAVING DATASET\n');
fprintf('========================================\n');


%% CREATION DU DOSSIER DE SORTIE (chemin absolu, robuste au cwd)

outputFolder = resolve_output_folder(cfg);

%% NOM DU FICHIER

timestamp = datestr(datetime("now"), 'yyyymmdd_HHMMSS');

filename = sprintf('%s_%s_%s.mat', ...
    cfg.project.caseName, ...
    "dataset", ...
    timestamp);

filepath = fullfile(outputFolder, filename);

%% METADATA FINALE

dataset.metadata.saveTime = datetime("now");
dataset.metadata.totalSamples = dataset.statistics.total;

dataset.metadata.acceptedRate = ...
    dataset.statistics.accepted / max(dataset.statistics.total,1);

dataset.metadata.borderlineRate = ...
    dataset.statistics.borderline / max(dataset.statistics.total,1);

dataset.metadata.rejectedRate = ...
    dataset.statistics.rejected / max(dataset.statistics.total,1);

% Taux de la couche transitoire (etiquettes de stabilite)
dataset.metadata.stableRate = ...
    dataset.statistics.stable / max(dataset.statistics.total,1);

dataset.metadata.unstableRate = ...
    dataset.statistics.unstable / max(dataset.statistics.total,1);

%% SAUVEGARDE .MAT

save(filepath, 'dataset', '-v7.3');

%% LOG FINAL

fprintf(' Dataset saved successfully\n');
fprintf(' File: %s\n', filepath);
fprintf(' Total samples : %d\n', dataset.statistics.total);
fprintf(' Accepted : %d (%.2f%%)\n', ...
    dataset.statistics.accepted, dataset.metadata.acceptedRate*100);
fprintf(' Borderline : %d (%.2f%%)\n', ...
    dataset.statistics.borderline, dataset.metadata.borderlineRate*100);
fprintf(' Rejected : %d (%.2f%%)\n', ...
    dataset.statistics.rejected, dataset.metadata.rejectedRate*100);

fprintf(' ---- Transient labels ----\n');
fprintf(' Stable   : %d (%.2f%%)\n', ...
    dataset.statistics.stable, dataset.metadata.stableRate*100);
fprintf(' Unstable : %d (%.2f%%)\n', ...
    dataset.statistics.unstable, dataset.metadata.unstableRate*100);
fprintf(' Tr. fail : %d\n', dataset.statistics.transientFailed);

fprintf('========================================\n\n');

end
