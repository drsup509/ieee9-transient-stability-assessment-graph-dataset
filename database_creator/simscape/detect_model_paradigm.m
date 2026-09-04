function info = detect_model_paradigm(model)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DETECT_MODEL_PARADIGM
%
% OBJECTIF
% --------
% Identifier le paradigme électrique Simulink d'un modèle, afin que la
% couche transitoire choisisse (ou refuse) le bon backend.
%
% Fonction à responsabilité unique : elle INSPECTE seulement, ne modifie
% ni ne simule rien.
%
% PARADIGMES RECONNUS
% -------------------
% 'simscape-ee'  : Simscape Electrical (ee_lib). Marqueurs : blocs Busbar
%                  et/ou Solver Configuration.
% 'sps-powerlib' : SimPowerSystems classique (powerlib). Marqueurs : bloc
%                  powergui et/ou "Load Flow Bus".
% 'unknown'      : aucun marqueur reconnu.
%
% ENTREE
% ------
% model : nom du modèle Simulink (char), déjà chargé en mémoire.
%
% SORTIE
% ------
% info.paradigm : 'simscape-ee' | 'sps-powerlib' | 'unknown'
% info.counts   : struct des comptages de blocs marqueurs
% info.modelName: nom du modèle inspecté
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~bdIsLoaded(model)
    error('tsa:detect_model_paradigm:notLoaded', ...
        'Le modèle "%s" doit être chargé avant détection.', model);
end

% Inspection silencieuse : find_system peut émettre des avertissements de
% liens de bibliothèque sans intérêt pour la détection.
ws = warning('off', 'all');
cleanup = onCleanup(@() warning(ws));

count = @(mtq) numel(find_system(model, ...
    'LookUnderMasks','all', 'FollowLinks','on', 'MaskType', mtq));

counts = struct();
counts.busbar       = count('Busbar');                 % ee
counts.solverConfig = count('Solver Configuration');   % ee
counts.eeFault      = count('Fault (Three-Phase)');    % ee
counts.powergui     = count('powergui');               % SPS
counts.loadFlowBus  = count('Load Flow Bus');          % SPS
counts.spsMachine   = count('Synchronous Machine');    % SPS

isEE  = (counts.busbar > 0) || (counts.solverConfig > 0);
isSPS = (counts.powergui > 0) || (counts.loadFlowBus > 0);

if isEE && ~isSPS
    paradigm = 'simscape-ee';
elseif isSPS && ~isEE
    paradigm = 'sps-powerlib';
elseif isEE && isSPS
    % Modèle hybride : on privilégie le marqueur le plus structurant (ee).
    paradigm = 'simscape-ee';
else
    paradigm = 'unknown';
end

info = struct();
info.paradigm  = paradigm;
info.counts    = counts;
info.modelName = model;

end
