function backend = assert_transient_backend(model, cfg)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ASSERT_TRANSIENT_BACKEND
%
% OBJECTIF
% --------
% Vérifier que le modèle fourni est compatible avec le backend transitoire
% demandé. Échoue TÔT et CLAIREMENT si le modèle n'est pas pris en charge,
% plutôt que de laisser la simulation échouer obscurément plus loin.
%
% Fonction à responsabilité unique : détecte le paradigme (via
% detect_model_paradigm) et applique la politique de compatibilité.
%
% POLITIQUE
% ---------
% - cfg.transient.backend = 'auto'         -> backend = paradigme détecté
%                                             ('simscape-ee' ou 'sps-powerlib').
% - cfg.transient.backend = 'simscape-ee'  -> impose ee ; erreur si modèle SPS.
% - cfg.transient.backend = 'sps-powerlib' -> impose SPS ; erreur si modèle ee.
%
% Les deux backends sont désormais pris en charge par la couche transitoire.
%
% ENTREE
% ------
% model : nom du modèle Simulink (char), déjà chargé.
% cfg   : configuration globale (cfg.transient.backend).
%
% SORTIE
% ------
% backend : identifiant du backend validé ('simscape-ee' | 'sps-powerlib').
%
% ERREURS
% -------
% tsa:transient:unsupportedModel  : modèle SPS demandé en ee (ou l'inverse).
% tsa:transient:unknownParadigm   : aucun marqueur électrique reconnu.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

requested = 'auto';
if isfield(cfg, 'transient') && isfield(cfg.transient, 'backend')
    requested = char(cfg.transient.backend);
end

info = detect_model_paradigm(model);

% Backend explicitement forcé sur SPS/powerlib : exiger un modèle SPS.
if strcmp(requested, 'sps-powerlib')
    if ~strcmp(info.paradigm, 'sps-powerlib')
        error('tsa:transient:unsupportedModel', ...
            ['Backend ''sps-powerlib'' demandé mais le modèle "%s" ' ...
             'n''est pas SimPowerSystems (paradigme détecté : %s).'], ...
            model, info.paradigm);
    end
    backend = 'sps-powerlib';
    return;
end

% Backend explicitement forcé sur ee : exiger un modèle Simscape Electrical.
if strcmp(requested, 'simscape-ee')
    if ~strcmp(info.paradigm, 'simscape-ee')
        error('tsa:transient:unsupportedModel', ...
            i_sps_message(model, info));
    end
    backend = 'simscape-ee';
    return;
end

% 'auto' : le backend suit le paradigme détecté.
switch info.paradigm

    case 'simscape-ee'
        backend = 'simscape-ee';

    case 'sps-powerlib'
        backend = 'sps-powerlib';

    otherwise
        error('tsa:transient:unknownParadigm', ...
            ['Modèle "%s" : paradigme électrique non reconnu ' ...
             '(ni Simscape Electrical, ni SimPowerSystems). ' ...
             'Marqueurs trouvés -> Busbar:%d, SolverConfig:%d, ' ...
             'powergui:%d, LoadFlowBus:%d.'], ...
            model, info.counts.busbar, info.counts.solverConfig, ...
            info.counts.powergui, info.counts.loadFlowBus);
end

end


%% ----------------------------------------------------------------------
function msg = i_sps_message(model, info)
% Message d'erreur explicite pour un modèle SimPowerSystems (ex. NE39).
msg = sprintf([ ...
    'Modèle "%s" détecté comme SimPowerSystems classique (powerlib) : ' ...
    'powergui=%d, LoadFlowBus=%d, Synchronous Machine (SPS)=%d.\n' ...
    'La couche transitoire actuelle ne prend en charge que les modèles ' ...
    'Simscape Electrical (ee_lib), comme IEEE9BusSystem (Busbar + Fault ' ...
    '(Three-Phase) + Solver Configuration + Simscape logging).\n' ...
    'Un backend SPS séparé (bloc powerlib Three-Phase Fault, lecture des ' ...
    'angles/vitesses via le bus de mesure ''m'' des machines) est requis ' ...
    'et n''est pas encore implémenté.\n' ...
    'Action : utiliser un modèle Simscape Electrical, ou implémenter le ' ...
    'backend ''sps-powerlib''.'], ...
    model, info.counts.powergui, info.counts.loadFlowBus, info.counts.spsMachine);
end
