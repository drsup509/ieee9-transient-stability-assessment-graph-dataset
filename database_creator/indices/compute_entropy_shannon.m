function network = compute_entropy_shannon(network, Pd, Qd)

%% 2. SHANNON ENTROPY
%
% OBJECTIF
% --------
% Mesurer le degré d'uniformité de la répartition des charges.
%
% Forte entropie
% -> charges réparties de manière uniforme.
%
% Faible entropie
% -> charges concentrées sur un petit nombre de bus. Normalisation
% permettant dMavoir une valeur comprise entre 0 et 1 (0 concentrée sur une
% seul bus et 1 parfaitement uniforme)
%
% Cette métrique est indépendante du niveau total de charge.
%
%=========================================================================

if sum(Pd) > 0

    % pP = Pd / sum(Pd);
    % 
    % pP(pP == 0) = [];
    % 
    % network.indices.loadDiversity.entropyP = ...
    %     -sum(pP .* log(pP));

    pP = Pd / sum(Pd);
    pP(pP == 0) = [];
    
    network.indices.loadDiversityP.entropyP = ...
        -sum(pP .* log(pP)) / log(length(pP));

else

    network.indices.loadDiversityP.entropyP = NaN;

end

if sum(Qd) > 0

    pQ = Qd / sum(Qd);

    pQ(pQ == 0) = [];

    network.indices.loadDiversityQ.entropyQ = ...
        -sum(pQ .* log(pQ));

else

    network.indices.loadDiversityQ.entropyQ = NaN;

end

end