function tsi = compute_tsi(sample)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COMPUTE_TSI  (post-traitement)
%
% OBJECTIF
% --------
% Calculer l'indice de stabilite transitoire (Transient Stability Index)
% de la litterature TSA, forme continue :
%
%       TSI = 100 * (360 - dmax) / (360 + dmax)      [sans unite]
%
% ou dmax est la separation angulaire inter-machines MAXIMALE [deg].
%   TSI > 0  <=>  dmax < 360 deg  (stable au sens du critere 360)
%   TSI < 0  <=>  dmax > 360 deg  (instable au sens du critere 360)
%
% ATTENTION : le SIGNE de TSI repose sur le seuil de 360 deg, DIFFERENT
% du label binaire de ce dataset (seuil 180 deg). TSI est fourni comme
% grandeur continue de reference / cible de regression, pas comme label.
%
% dmax est lu en priorite depuis les champs deja calcules (coherence avec
% le label), avec repli sur une reconstruction a partir des angles.
%
% ENTREE
% ------
% sample : un echantillon dataset.samples{k}
%
% SORTIE
% ------
% tsi : scalaire. NaN si dmax indisponible.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tsi  = NaN;
dmax = NaN;

if ~isfield(sample,'transient')
    return;
end
tr = sample.transient;

% 1) Source privilegiee : valeur deja stockee (coherente avec le label)
if isfield(tr,'label') && isfield(tr.label,'maxSeparation') ...
        && ~isempty(tr.label.maxSeparation)
    dmax = tr.label.maxSeparation;
elseif isfield(tr,'indices') && isfield(tr.indices,'maxAngleSeparationDeg') ...
        && ~isempty(tr.indices.maxAngleSeparationDeg)
    dmax = tr.indices.maxAngleSeparationDeg;
else
    % 2) Repli : reconstruction depuis les angles rotoriques
    sepDeg = compute_coi_separation(tr);
    if ~isempty(sepDeg)
        dmax = max(sepDeg);
    end
end

if isnan(dmax)
    return;
end

tsi = 100 * (360 - dmax) / (360 + dmax);

end
