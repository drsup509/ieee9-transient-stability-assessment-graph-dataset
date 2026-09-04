function faultMap = prepare_fault_infrastructure(model, cfg)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PREPARE_FAULT_INFRASTRUCTURE
%
% OBJECTIF
% --------
% Instrumenter le modele SPS EN MEMOIRE avec un bloc "Fault (Three-Phase)"
% (ee_lib) par busbar, desactive par defaut. Chaque scenario n'aura plus
% qu'a activer/parametrer le bloc du bus defaillant (apply_fault_to_model).
%
% IMPORTANT
% ---------
% - Cette fonction NE SAUVEGARDE JAMAIS le modele (.slx reste intact).
%   L'instrumentation est faite sur la copie en memoire, a chaque
%   lancement de dataset. Cela evite toute corruption du modele source
%   et le probleme de restauration OneDrive.
% - Idempotente : un busbar deja instrumente est ignore.
%
% MECANISME
% ---------
% Le busbar est un noeud triphase. On ajoute une borne libre au busbar
% (parametre n_nodes) puis on y raccorde le bloc de defaut (shunt).
%
% ENTREE
% ------
% model : nom du modele Simulink (char), deja charge en memoire
% cfg   : configuration globale (cfg.transient.fault.*)
%
% SORTIE
% ------
% faultMap : containers.Map (cle = numero de bus, valeur = chemin du bloc
%            de defaut instrumente)
%
% LICENCE
% -------
% Requiert Simscape Electrical (ee_lib).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf(' -> Preparing fault infrastructure (in-memory)...\n');

% DISPATCH BACKEND : si le modèle est SimPowerSystems (ex. NE39), déléguer
% à l'infrastructure SPS. Le chemin Simscape Electrical ci-dessous reste
% strictement inchangé (IEEE9BusSystem).
if strcmp(assert_transient_backend(model, cfg), 'sps-powerlib')
    faultMap = prepare_fault_infrastructure_sps(model, cfg);
    return;
end

% GARDE-FOU : ne pas instrumenter un modèle incompatible (ex. NE39/SPS).
% Échoue tôt et clairement si le paradigme n'est pas Simscape Electrical.
assert_transient_backend(model, cfg);

faultBlockLib = 'ee_lib/Utilities/Fault (Three-Phase)';
if ~bdIsLoaded('ee_lib')
    load_system('ee_lib');
end

busbarMap = map_bus_to_busbar(model);
busNums   = cell2mat(keys(busbarMap));

faultMap = containers.Map('KeyType', 'double', 'ValueType', 'char');

for b = busNums

    busbar = busbarMap(b);
    faultName = sprintf('TSA_Fault_Bus%d', b);
    faultPath = [model '/' faultName];

    % Idempotence : deja instrumente ?
    if getSimulinkBlockHandle(faultPath) ~= -1
        faultMap(b) = faultPath;
        continue;
    end

    %% 1. Placer le bloc de defaut
    pos = get_param(busbar, 'Position');   % [l t r b]
    x = pos(1);
    y = pos(4) + 60;
    add_block(faultBlockLib, faultPath, ...
        'Position', [x, y, x+40, y+40]);

    %% 2. Raccorder le defaut au noeud du busbar (branche shunt)
    % Le busbar est un noeud triphase : on branche le defaut sur une
    % borne deja connectee (Simscape cree automatiquement un noeud).
    % Cette methode fonctionne quel que soit le nombre de bornes.
    connPort  = i_connected_port(busbar);
    fph       = get_param(faultPath, 'PortHandles');
    faultTerm = fph.LConn(1);
    add_line(model, connPort, faultTerm, 'autorouting', 'on');

    %% 3. Configurer le bloc : desactive par defaut
    i_set_fault_defaults(faultPath, cfg);

    faultMap(b) = faultPath;
end

fprintf('    %d fault block(s) ready.\n', faultMap.Count);

end


%% ----------------------------------------------------------------------
function connPort = i_connected_port(busbar)
% Retourne le handle d'une borne DEJA connectee du busbar, sur laquelle
% on branchera le defaut (creation automatique d'un noeud par Simscape).
ph = get_param(busbar, 'PortHandles');
allPorts = [ph.LConn(:); ph.RConn(:)];
connPort = -1;
for k = 1:numel(allPorts)
    if get_param(allPorts(k), 'Line') ~= -1
        connPort = allPorts(k);
        break;
    end
end
if connPort == -1
    error('tsa:prepare_fault:noConnectedPort', ...
        'Aucune borne connectee sur le busbar %s.', get_param(busbar,'Name'));
end
end


%% ----------------------------------------------------------------------
function i_set_fault_defaults(faultPath, cfg)
% Configure le bloc de defaut a l'etat INACTIF, avec les parametres
% physiques issus de la configuration.
%
% Le bloc ee "Fault (Three-Phase)" exige une duree > 0 lorsque le defaut
% temporel est actif. Pour rendre un bloc inoffensif, on programme donc
% son declenchement TRES loin dans le futur (jamais atteint pendant la
% simulation), avec une duree positive symbolique.

set_param(faultPath, 'enable_temporal_fault', '1');   % 1 = defaut temporel active
set_param(faultPath, 'fault_type_option', num2str(cfg.transient.fault.typeOption));
set_param(faultPath, 'R_pn_fault', num2str(cfg.transient.fault.Rpn));
set_param(faultPath, 'R_ng_fault', num2str(cfg.transient.fault.Rng));

% Declenchement hors fenetre de simulation => aucun defaut applique tant
% que apply_fault_to_model ne reprogramme pas le bloc.
set_param(faultPath, 'fault_start_time', '1e9');
set_param(faultPath, 'fault_duration', '1e-3');
end
