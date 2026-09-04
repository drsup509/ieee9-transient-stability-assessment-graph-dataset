function faultMap = prepare_fault_infrastructure_sps(model, cfg)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PREPARE_FAULT_INFRASTRUCTURE_SPS
%
% OBJECTIF
% --------
% Analogue SimPowerSystems (powerlib) de prepare_fault_infrastructure.
% Instrumente le modele SPS EN MEMOIRE avec :
%   1) un bloc "Three-Phase Fault" (powerlib) shunt par bus, desactive ;
%   2) le logging des signaux rotoriques (angle d_theta, vitesse w) de
%      chaque machine, via les Goto globaux "d_theta{n}" / "w{n}".
%
% IMPORTANT
% ---------
% - Ne SAUVEGARDE JAMAIS le modele (.slx intact). Instrumentation sur la
%   copie en memoire, refaite a chaque lancement de dataset.
% - Idempotente : un bus deja instrumente est ignore.
%
% MECANISME DE DEFAUT
% -------------------
% Le bloc "Three-Phase Fault" possede 3 bornes physiques (A,B,C). On les
% raccorde aux 3 bornes du noeud triphase du bus (branche shunt). Sur SPS
% base Simscape (R2024a), le raccordement a une borne deja connectee cree
% automatiquement un noeud.
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
% Requiert SimPowerSystems / Simscape Electrical.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf(' -> Preparing SPS fault infrastructure (in-memory)...\n');

% Garde-fou : ne pas instrumenter un modele incompatible.
assert_transient_backend(model, cfg);

if ~bdIsLoaded(model)
    load_system(model);
end
if ~bdIsLoaded('powerlib')
    load_system('powerlib');
end

faultLib = 'powerlib/Elements/Three-Phase Fault';

nodeMap = map_bus_to_sps_node(model);
busNums = cell2mat(keys(nodeMap));

faultMap = containers.Map('KeyType', 'double', 'ValueType', 'char');

for b = busNums

    busPath   = nodeMap(b);
    faultName = sprintf('TSA_Fault_Bus%d', b);
    faultPath = [model '/' faultName];

    % Idempotence.
    if getSimulinkBlockHandle(faultPath) ~= -1
        faultMap(b) = faultPath;
        continue;
    end

    %% 1. Placer le bloc de defaut sous le bus
    pos = get_param(busPath, 'Position');   % [l t r b]
    x = pos(1);
    y = pos(4) + 80;
    add_block(faultLib, faultPath, 'Position', [x, y, x+40, y+70]);

    %% 2. Raccorder les 3 bornes du defaut aux 3 bornes du bus (shunt)
    busPH   = get_param(busPath, 'PortHandles');
    faultPH = get_param(faultPath, 'PortHandles');
    for i = 1:3
        busPort = i_pick_connected(busPH.RConn(i), busPH.LConn(i));
        add_line(model, busPort, faultPH.LConn(i), 'autorouting', 'on');
    end

    %% 3. Configurer le bloc : desactive par defaut
    i_set_sps_fault_defaults(faultPath, cfg);

    faultMap(b) = faultPath;
end

%% 4. Instrumenter les signaux rotoriques (angle / vitesse) pour lecture
nGen = i_instrument_machine_signals(model);

%% 5. Neutraliser l'arret automatique sur perte de synchronisme
%
% Le modele NE39 contient un bloc "Stop simulation if loss of synchronism"
% qui interrompt la simulation avant StopTime lorsqu'une machine decroche.
% Or c'est precisement le cas INSTABLE que l'on veut simuler jusqu'au bout
% (sinon validate_dynamic_results rejette le scenario en "StoppedEarly" et
% le label UNSTABLE est perdu). On desactive donc ces blocs pour toujours
% simuler la fenetre complete, comme le backend ee.
nStop = i_disable_stop_blocks(model);

fprintf('    %d SPS fault block(s) ready, %d machine(s) logged, %d stop block(s) disabled.\n', ...
    faultMap.Count, nGen, nStop);

end


%% ----------------------------------------------------------------------
function port = i_pick_connected(portA, portB)
% Retourne la premiere borne deja connectee (sur laquelle on branchera le
% defaut, creant un noeud). Repli sur portA si aucune n'est connectee.
if get_param(portA, 'Line') ~= -1
    port = portA;
elseif get_param(portB, 'Line') ~= -1
    port = portB;
else
    port = portA;
end
end


%% ----------------------------------------------------------------------
function i_set_sps_fault_defaults(faultPath, cfg)
% Configure le bloc "Three-Phase Fault" a l'etat INACTIF : toutes les
% phases coupees et fenetre de commutation hors simulation.
set_param(faultPath, 'FaultA', 'off', 'FaultB', 'off', 'FaultC', 'off');
set_param(faultPath, 'GroundFault', 'off');
set_param(faultPath, 'SwitchTimes', '[1e9 1e9+1]');
set_param(faultPath, 'FaultResistance',  num2str(cfg.transient.fault.Rpn));
set_param(faultPath, 'GroundResistance', num2str(cfg.transient.fault.Rng));
end


%% ----------------------------------------------------------------------
function nGen = i_instrument_machine_signals(model)
% Active le logging (logsout) des signaux rotoriques de chaque machine.
% Les modeles SPS exposent, par machine n, des Goto globaux :
%   d_theta{n} : deviation d'angle rotorique [rad]
%   w{n}       : vitesse rotorique [pu]
% On logue le signal SOURCE alimentant chaque Goto sous un nom
% deterministe (tsa_dtheta_{n}, tsa_omega_{n}), evitant tout probleme
% d'ordre de multiplexage.
gotos = find_system(model, 'LookUnderMasks', 'all', 'FollowLinks', 'on', ...
    'BlockType', 'Goto');
nGen = 0;
for k = 1:numel(gotos)
    tag = get_param(gotos{k}, 'GotoTag');

    td = regexp(tag, '^d_theta(\d+)$', 'tokens', 'once');
    if ~isempty(td)
        n = str2double(td{1});
        i_log_goto_source(gotos{k}, sprintf('tsa_dtheta_%d', n));
        nGen = max(nGen, n);
        continue;
    end

    tw = regexp(tag, '^w(\d+)$', 'tokens', 'once');
    if ~isempty(tw)
        n = str2double(tw{1});
        i_log_goto_source(gotos{k}, sprintf('tsa_omega_%d', n));
    end
end
end


%% ----------------------------------------------------------------------
function i_log_goto_source(gotoBlk, logName)
% Active le logging du signal alimentant un bloc Goto, sous un nom donne.
ph = get_param(gotoBlk, 'PortHandles');
if isempty(ph.Inport)
    return;
end
lineH = get_param(ph.Inport(1), 'Line');
if lineH == -1
    return;
end
srcPort = get_param(lineH, 'SrcPortHandle');
if srcPort == -1
    return;
end
set_param(srcPort, 'DataLogging', 'on');
set_param(srcPort, 'DataLoggingNameMode', 'Custom');
set_param(srcPort, 'DataLoggingName', logName);
end


%% ----------------------------------------------------------------------
function nStop = i_disable_stop_blocks(model)
% Commente (desactive) tous les blocs "Stop Simulation" du modele afin de
% toujours simuler la fenetre complete, meme en cas de decrochage.
stops = find_system(model, 'LookUnderMasks', 'all', 'FollowLinks', 'on', ...
    'BlockType', 'Stop');
nStop = 0;
for k = 1:numel(stops)
    try
        set_param(stops{k}, 'Commented', 'on');
        nStop = nStop + 1;
    catch
        % Bloc protege / lie : ignore silencieusement.
    end
end
end
