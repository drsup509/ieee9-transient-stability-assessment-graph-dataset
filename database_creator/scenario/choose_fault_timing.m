function network = choose_fault_timing(network, cfg)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CHOOSE_FAULT_TIMING
%
% OBJECTIF
% --------
% Définir la chronologie du défaut :
%
% - instant d'apparition
% - instant d'élimination
% - durée totale du défaut
%
% IMPORTANCE TSA
% --------------
% Le timing du défaut est un facteur critique de stabilité transitoire.
% Il influence directement :
% - l'accélération des rotors
% - la marge de stabilité
% - la CCT (Critical Clearing Time)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf(' Selecting fault timing...\n');

%% FAULT START TIME
% Dans TSA classique, le défaut est appliqué après stabilisation initiale
%

tStart = cfg.fault.startTime;

network.fault.startTime = tStart;

%% FAULT CLEARING TIME

% Temps d'élimination du défaut :
% tiré aléatoirement dans une plage réaliste
%

tClear = tStart + ...
    (cfg.fault.minClearingTime + ...
    (cfg.fault.maxClearingTime - cfg.fault.minClearingTime) * rand);

network.fault.clearTime = tClear;

%% FAULT DURATION

network.fault.duration = tClear - tStart;

%% STATUT

network.fault.status = "TimingDefined";

fprintf(' Start time : %.3f s\n', tStart);
fprintf(' Clear time : %.3f s\n', tClear);
fprintf(' Duration : %.3f s\n', network.fault.duration);

end

