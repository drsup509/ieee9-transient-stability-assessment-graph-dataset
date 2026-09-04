function label = compute_stability_label(indices, cfg)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COMPUTE_STABILITY_LABEL
%
% OBJECTIF
% --------
% Attribuer le label de stabilite transitoire (STABLE / UNSTABLE) a un
% scenario, a partir des indices dynamiques.
%
% Le critere est entierement pilote par la configuration
% (cfg.label.angleSeparationThresholdDeg), afin de pouvoir changer la
% definition sans modifier cette fonction.
%
% IMPORTANT
% ---------
% Ce label est DISTINCT du statut de faisabilite regime permanent
% (validate_powerflow -> ACCEPTED/BORDERLINE/REJECTED). Les deux ne
% doivent jamais etre confondus.
%
% ENTREE
% ------
% indices : struct de compute_dynamic_indices
% cfg     : configuration globale
%
% SORTIE
% ------
% label.status   : "STABLE" | "UNSTABLE"
% label.value    : 0 (stable) | 1 (unstable)   -> cible d'apprentissage
% label.margin   : marge angulaire = seuil - separationMax [deg]
% label.criterion: description textuelle du critere applique
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

label = struct();

threshold = cfg.label.angleSeparationThresholdDeg;
maxSep    = indices.maxAngleSeparationDeg;

if maxSep > threshold
    label.status = "UNSTABLE";
    label.value  = 1;
else
    label.status = "STABLE";
    label.value  = 0;
end

label.margin        = threshold - maxSep;   % >0 : marge de stabilite
label.maxSeparation = maxSep;
label.threshold     = threshold;
label.criterion     = sprintf( ...
    'max rotor-angle separation > %g deg => UNSTABLE', threshold);

end
