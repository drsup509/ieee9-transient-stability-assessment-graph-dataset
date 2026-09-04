function network = compute_coefficient_variation (network, Pd, Qd)

%% COEFFICIENT OF VARIATION (CV)
%
% OBJECTIF
% --------
% Mesurer la dispersion des charges entre les différents bus.
%
% Faible CV
% -> charges relativement homogènes.
%
% Fort CV
% -> charges très dispersées.
%
% Si la charge moyenne est nulle, l'indice est non défini. 
% 
% Faire attention si on modélise des RED comme des charges négatives,
% condition supplémentaire à ajouter.
%
%=========================================================================

if mean(Pd) > 0
    network.indices.loadDiversityP.cvP = std(Pd) / mean(Pd);
else
    network.indices.loadDiversityP.cvP = NaN;
end

if mean(Qd) > 0
    network.indices.loadDiversityQ.cvQ = std(Qd) / mean(Qd);
else
    network.indices.loadDiversityQ.cvQ = NaN;
end

end