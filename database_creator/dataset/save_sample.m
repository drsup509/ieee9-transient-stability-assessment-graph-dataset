function dataset = save_sample(dataset, sample, mpc)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SAVE_SAMPLE
%
% OBJECTIF
% --------
% Ajouter un échantillon au dataset et mettre à jour les statistiques.
%
% RESPONSABILITES
% ----------------
% - Stocker le sample
% - Mettre à jour les compteurs (accepted/borderline/rejected)
% - Maintenir la cohérence du dataset
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% AJOUT DU SAMPLE

sample.mpc = mpc;

dataset.samples{end+1} = sample;

dataset.statistics.total = dataset.statistics.total + 1;

%% MISE À JOUR DES STATISTIQUES

status = string(sample.validation.status);

switch status

    case "ACCEPTED"
        dataset.statistics.accepted = dataset.statistics.accepted + 1;

    case "BORDERLINE"
        dataset.statistics.borderline = dataset.statistics.borderline + 1;

    case "REJECTED"
        dataset.statistics.rejected = dataset.statistics.rejected + 1;

    otherwise
        warning('Unknown validation status: %s', status);

end

%% MISE À JOUR DES STATISTIQUES TRANSITOIRES (stable / unstable)

dataset.statistics = update_transient_statistics(dataset.statistics, sample);


%% TRACKING RAPIDE

if dataset.statistics.total == 1
    dataset.statistics.startTime = datetime("now");
end

dataset.statistics.lastUpdate = datetime("now");

%% FEEDBACK CONSOLE

fprintf(' Sample saved | Total: %d | A:%d B:%d R:%d | STA:%d UNS:%d Tfail:%d\n', ...
    dataset.statistics.total, ...
    dataset.statistics.accepted, ...
    dataset.statistics.borderline, ...
    dataset.statistics.rejected, ...
    dataset.statistics.stable, ...
    dataset.statistics.unstable, ...
    dataset.statistics.transientFailed);

end
