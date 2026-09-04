function network = choose_fault_location(network, cfg)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CHOOSE_FAULT_LOCATION
%
% OBJECTIF
% --------
% Déterminer où le défaut électrique se produit dans le réseau :
%
% - Sur un bus
% - Sur une ligne
%
%
% SORTIE
% ------
% network.fault.locationType : "BUS" ou "LINE"
% network.fault.bus : index du bus si applicable
% network.fault.line : index de la ligne si applicable
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf(' Selecting fault location...\n');


%% EXTRACTION TOPOLOGIE

nBus = size(network.steadyState.Pd0, 1);

%% PROBABILITE SIMPLE (V1)
% Pour l'instant :
% 70% défaut sur ligne
% 30% défaut sur bus
%
% Plus tard possibilité: pondération par criticité (flux, congestion,
% etc.). À déménager dans la config
%


% pLine = 0.7;
pLine = cfg.fault.probaLinevsBus;

%% LIGNES ELIGIBLES A UN DEFAUT DE LIGNE (hors transformateurs)
%
% Un transformateur n'a pas de point milieu physique : un defaut "au
% milieu de la ligne" n'a pas de sens pour lui. On EXCLUT donc les
% transformateurs du tirage de defaut de ligne ; leurs bornes restent
% eligibles aux defauts de BUS via le tirage de bus ci-dessous.
%
% Convention MATPOWER (matrice branch) : colonne 9 = rapport de
% transformation (TAP, 0 pour une ligne), colonne 10 = dephasage (SHIFT).
% Une branche est un transformateur si TAP ~= 0 ou SHIFT ~= 0.
branch  = network.mpc.branch;
isXfmr  = (branch(:,9) ~= 0) | (branch(:,10) ~= 0);
lineElig = find(~isXfmr);

%% CHOIX TYPE DE LOCALISATION

if (rand < pLine) && ~isempty(lineElig)
    %% DEFAUT SUR LIGNE (transformateurs exclus)

    network.fault.locationType = "LINE";

    lineIndex = lineElig(randi(numel(lineElig)));

    network.fault.line = lineIndex;

    fromBus = branch(lineIndex,1);
    toBus = branch(lineIndex,2);

    % position par défaut (milieu de ligne)
    network.fault.location = 0.5;

    % bus associés (utile pour Simulink)
    network.fault.bus = [fromBus toBus];

else

    %% DEFAUT SUR BUS

    network.fault.locationType = "BUS";

    busIndex = randi(nBus);

    network.fault.bus = busIndex;

    network.fault.line = [];

    % pas de position sur ligne
    network.fault.location = 0;

end

%% STATUS

network.scenario.fault.status = "LocationDefined";

fprintf(' Location type : %s\n', network.fault.locationType);

end