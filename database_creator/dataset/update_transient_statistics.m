function stats = update_transient_statistics(stats, sample)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% UPDATE_TRANSIENT_STATISTICS
%
% OBJECTIF
% --------
% Mettre a jour les compteurs de la couche transitoire (stable / unstable /
% transientFailed) a partir de l'etiquette de stabilite d'un echantillon.
%
% ENTREES
% -------
% - stats  : structure dataset.statistics (avec champs stable/unstable/
%            transientFailed).
% - sample : echantillon courant (utilise sample.transient).
%
% SORTIE
% ------
% - stats : structure mise a jour.
%
% REGLES
% ------
% - transient absent ou success == false          -> transientFailed
% - label.status == "STABLE"                       -> stable
% - label.status == "UNSTABLE"                     -> unstable
% - toute autre valeur                             -> transientFailed
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~isfield(sample, 'transient') ...
        || ~isfield(sample.transient, 'success') ...
        || ~sample.transient.success ...
        || ~isfield(sample.transient, 'label') ...
        || ~isfield(sample.transient.label, 'status')
    stats.transientFailed = stats.transientFailed + 1;
    return;
end

switch upper(string(sample.transient.label.status))
    case "STABLE"
        stats.stable = stats.stable + 1;
    case "UNSTABLE"
        stats.unstable = stats.unstable + 1;
    otherwise
        stats.transientFailed = stats.transientFailed + 1;
end

end
