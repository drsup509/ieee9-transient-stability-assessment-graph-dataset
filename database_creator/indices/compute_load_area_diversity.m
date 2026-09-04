function network = compute_load_area_diversity(network, Pd, Qd)

%% AREA DIVERSITY
%
% OBJECTIF
% --------
% Mesurer la dispersion des charges entre les différentes zones du réseau.
%
% Indice utilisé :
%     CV = std(P_area) / mean(P_area)
%
% où P_area est la charge totale agrégée dans chaque area.
%
% Si une seule area est présente, l'indice n'est pas défini et vaut
% NaN.Pour faicliter apprentisage GNN plus tar, je mets 0 comme valeur
% comme si les charges sont homog;ènes vu que c'est une seule area
%
% CV proche de 0 -> les charges sont réparties de façon homogène entre les areas.
% CV élevé -> les charges sont concentrées dans certaines areas.
% CV ≈ 1 -> la dispersion est du même ordre de grandeur que la moyenne, 
% ce qui indique déjà un déséquilibre important.
% 
% Cette métrique sera particulièrement utile pour :
%
% - l'étude des échanges inter-zones ;
% - les analyses TSA ;
% - les modèles GNN sur de grands réseaux.
%
%=========================================================================

if isfield(network.metadata,'areas')

    fprintf('\n\n AREAS \n\n');

    areaID = network.metadata.areas(:);

    uniqueAreas = unique(areaID);

    % L'indice de diversité inter-area nécessite au moins 2 areas
    if numel(uniqueAreas) < 2

        network.indices.loadDiversityP.areaCVP = 0; %NaN remplace par 0
        network.indices.loadDiversityQ.areaCVQ = 0; %NaN remplace par 0

    else

        areaP = zeros(numel(uniqueAreas),1);
        areaQ = zeros(numel(uniqueAreas),1);

        for k = 1:numel(uniqueAreas)

            idx = (areaID == uniqueAreas(k));

            areaP(k) = sum(Pd(idx));
            areaQ(k) = sum(Qd(idx));

        end

        % Coefficient de variation des charges actives
        if mean(areaP) > 0
            network.indices.loadDiversityP.areaCVP = ...
                std(areaP) / mean(areaP);
        else
            network.indices.loadDiversityP.areaCVP = 0; %NaN remplace par 0
        end

        % Coefficient de variation des charges réactives
        if mean(areaQ) > 0
            network.indices.loadDiversityQ.areaCVQ = ...
                std(areaQ) / mean(areaQ);
        else
            network.indices.loadDiversityQ.areaCVQ = 0; %NaN remplace par 0
        end

    end

else

    network.indices.loadDiversityP.areaCVP = 0; %NaN remplace par 0
    network.indices.loadDiversityQ.areaCVQ = 0; %NaN remplace par 0

end

end