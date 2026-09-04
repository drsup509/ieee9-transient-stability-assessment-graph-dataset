function t2loss = compute_time_to_loss_sync(sample)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COMPUTE_TIME_TO_LOSS_SYNC  (post-traitement)
%
% OBJECTIF
% --------
% Calculer le temps de perte de synchronisme d'un scenario, MESURE A
% PARTIR DU TEMPS D'ELIMINATION DU DEFAUT (fault.clearTime).
%
% CONVENTION (demandee)
% ---------------------
%   t2loss = 0          -> scenario STABLE (le seuil n'est jamais franchi)
%   t2loss < 0          -> synchronisme perdu AVANT l'elimination du defaut
%   t2loss > 0          -> synchronisme perdu APRES l'elimination du defaut
%   t2loss = temps(premier franchissement du seuil) - fault.clearTime
%
% Le seuil est celui du label (sample.transient.label.threshold, defaut
% 180 deg) et la separation est referee au COI (cf. compute_coi_separation).
%
% ENTREE
% ------
% sample : un echantillon dataset.samples{k}
%
% SORTIE
% ------
% t2loss : scalaire [s]. NaN si les donnees dynamiques sont absentes.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

t2loss = NaN;

if ~isfield(sample,'transient')
    return;
end
tr = sample.transient;

if ~isfield(tr,'time') || isempty(tr.time)
    return;
end

sepDeg = compute_coi_separation(tr);
if isempty(sepDeg)
    return;
end

t = tr.time(:);

% Seuil de stabilite (coherent avec le label deja calcule)
thr = 180;
if isfield(tr,'label') && isfield(tr.label,'threshold') ...
        && ~isempty(tr.label.threshold)
    thr = tr.label.threshold;
end

% Temps d'elimination du defaut
clearTime = NaN;
if isfield(sample,'fault') && isfield(sample.fault,'clearTime')
    clearTime = sample.fault.clearTime;
end

idx = find(sepDeg > thr, 1, 'first');

if isempty(idx)
    % STABLE : le seuil n'est jamais franchi.
    t2loss = 0;
    return;
end

if isnan(clearTime)
    % Sans temps d'elimination, on ne peut pas referer : NaN.
    t2loss = NaN;
    return;
end

t2loss = t(idx) - clearTime;

end
