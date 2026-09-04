function dyn = import_dynamic_results(out, cfg)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% IMPORT_DYNAMIC_RESULTS
%
% OBJECTIF
% --------
% Extraire, depuis la sortie de simulation Simscape (Simscape logging),
% les series temporelles rotoriques necessaires a l'analyse de stabilite :
% angle electrique rotorique et vitesse rotorique, par generateur.
%
% Cette fonction ne fait AUCUN calcul d'indice : elle normalise seulement
% les donnees brutes dans une structure exploitable.
%
% DETECTION DES GENERATEURS
% -------------------------
% Un sous-systeme generateur est detecte de facon robuste (independante
% du nom) par la presence des noeuds de mesure "Rotor_electrical_angle"
% et "Rotor_velocity" (convention du modele SPS).
%
% ENTREE
% ------
% out : Simulink.SimulationOutput (contient le log Simscape 'simlog')
% cfg : configuration globale
%
% SORTIE
% ------
% dyn.time     : Nt x 1     temps [s]
% dyn.delta    : Nt x nGen  angle electrique rotorique [rad] (absolu)
% dyn.omega    : Nt x nGen  vitesse rotorique [pu]
% dyn.genNames : 1 x nGen   noms des sous-systemes generateurs
% dyn.nGen     : nombre de generateurs
% dyn.success  : true si au moins un generateur a ete extrait
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

dyn = struct('time', [], 'delta', [], 'omega', [], ...
    'genNames', strings(1,0), 'nGen', 0, 'success', false);

% Champs ADDITIFS (couche augmentee, non requis par le label). Restent vides
% si l'extraction etendue echoue : le pipeline de label n'en depend jamais.
dyn.V          = [];              % Nt x nBus  tension de bus (module) [pu]
dyn.Vangle     = [];              % Nt x nBus  tension de bus (phase)  [rad]
dyn.busNumbers = zeros(1,0);      % 1 x nBus   numeros de bus
dyn.busNames   = strings(1,0);    % 1 x nBus   ids des noeuds de bus
dyn.Pe         = [];              % Nt x nGen  puissance electrique [pu] = Te.*w
dyn.Pm         = [];              % Nt x nGen  puissance mecanique  [pu]
dyn.Te         = [];              % Nt x nGen  couple electromagnetique [pu]

%% Recuperer le log Simscape

logName = 'simlog';
if isfield(cfg, 'transient') && isfield(cfg.transient, 'simscapeLogName')
    logName = cfg.transient.simscapeLogName;
end

if ~ismember(logName, out.who)
    return;   % pas de log -> echec silencieux, gere par validate_dynamic_results
end

simlog = out.get(logName);

%% Parcourir les sous-systemes de premier niveau

ids = simlog.childIds;

timeRef  = [];
deltaCols = {};
omegaCols = {};
names    = strings(1,0);

% Colonnes ADDITIVES par generateur (alignees sur `names`).
peCols = {};
pmCols = {};
teCols = {};

for k = 1:numel(ids)

    node = simlog.child(ids{k});

    if ~(node.hasChild('Rotor_electrical_angle') && node.hasChild('Rotor_velocity'))
        continue;   % pas un sous-systeme generateur
    end

    angleSeries = node.child('Rotor_electrical_angle').child('pu_output').series;
    speedSeries = node.child('Rotor_velocity').child('pu_output').series;

    % time() et values() sont des METHODES de simscape.logging.Series :
    % on les evalue sans argument avant tout indexage.
    t     = angleSeries.time;
    delta = angleSeries.values;   % [rad], angle absolu accumule
    omega = speedSeries.values;   % [pu]
    t = t(:); delta = delta(:); omega = omega(:);

    if isempty(timeRef)
        timeRef = t;
    elseif numel(t) ~= numel(timeRef)
        % Reechantillonnage defensif sur la base temporelle de reference
        delta = interp1(t, delta, timeRef, 'linear', 'extrap');
        omega = interp1(t, omega, timeRef, 'linear', 'extrap');
    end

    deltaCols{end+1} = delta(:); %#ok<AGROW>
    omegaCols{end+1} = omega(:); %#ok<AGROW>
    names(end+1)     = string(ids{k}); %#ok<AGROW>

    % --- Extraction ADDITIVE (Pe, Pm, Te) pour ce generateur -----------
    % Ne jamais faire echouer l'extraction du label : en cas de probleme,
    % on stocke des colonnes NaN de la bonne taille et on continue.
    [peK, pmK, teK] = i_extract_gen_power(node, timeRef);
    peCols{end+1} = peK; %#ok<AGROW>
    pmCols{end+1} = pmK; %#ok<AGROW>
    teCols{end+1} = teK; %#ok<AGROW>
end

if isempty(deltaCols)
    return;
end

%% Assemblage matriciel (Nt x nGen)

dyn.time     = timeRef;
dyn.delta    = [deltaCols{:}];
dyn.omega    = [omegaCols{:}];
dyn.genNames = names;
dyn.nGen     = numel(names);
dyn.success  = true;

% Grandeurs ADDITIVES par generateur (Nt x nGen), memes colonnes que genNames.
dyn.Pe = [peCols{:}];
dyn.Pm = [pmCols{:}];
dyn.Te = [teCols{:}];

% Tensions de bus V(t) : balayage separe des noeuds portant un enfant 'Vt'.
[dyn.V, dyn.Vangle, dyn.busNumbers, dyn.busNames] = ...
    i_extract_bus_voltage(simlog, ids, timeRef);

end


%% ----------------------------------------------------------------------
function [pe, pm, te] = i_extract_gen_power(genNode, timeRef)
% Extrait la puissance electrique (Pe), mecanique (Pm) et le couple
% electromagnetique (Te) d'un sous-systeme generateur, alignes sur timeRef.
%   Pe = pu_torque .* pu_velocity   [pu]   (puissance electrique machine)
%   Pm = Governor.../Mechanical_Power/Pm_pu [pu]
%   Te = pu_torque                  [pu]
% Chemins confirmes empiriquement (probe_simlog_signals). En cas d'absence,
% renvoie des colonnes NaN : les champs additifs sont non critiques.
Nt = numel(timeRef);
pe = nan(Nt,1); pm = nan(Nt,1); te = nan(Nt,1);

% Noeud machine : enfant portant 'pu_torque' ET 'pu_velocity'.
machineNode = [];
kids = {};
try; kids = genNode.childIds; catch; end
for j = 1:numel(kids)
    try
        c = genNode.child(kids{j});
        if c.hasChild('pu_torque') && c.hasChild('pu_velocity')
            machineNode = c; break;
        end
    catch
    end
end

if ~isempty(machineNode)
    try
        teRaw = i_series_on(machineNode.child('pu_torque'), timeRef);
        wRaw  = i_series_on(machineNode.child('pu_velocity'), timeRef);
        te = teRaw;
        pe = teRaw .* wRaw;   % puissance electrique = couple * vitesse [pu]
    catch
    end
end

% Puissance mecanique : Governor_and_Prime_Mover/Mechanical_Power/Pm_pu.
try
    govNode = [];
    for j = 1:numel(kids)
        c = genNode.child(kids{j});
        if c.hasChild('Mechanical_Power'); govNode = c; break; end
    end
    if ~isempty(govNode)
        pm = i_series_on(govNode.child('Mechanical_Power').child('Pm_pu'), timeRef);
    end
catch
end
end


%% ----------------------------------------------------------------------
function [V, Vang, busNums, busNames] = i_extract_bus_voltage(simlog, ids, timeRef)
% Balaye les noeuds de premier niveau et extrait la tension de bus (module
% 'Vt' et phase 'ph') de ceux qui portent un enfant 'Vt'. Le numero de bus
% est lu au debut de l'id (ex. 'Bus7_230kV' -> 7). Ordonne par numero.
Nt = numel(timeRef);
Vcols = {}; Acols = {}; nums = []; nms = strings(1,0);

for k = 1:numel(ids)
    node = simlog.child(ids{k});
    hasVt = false;
    try; hasVt = node.hasChild('Vt'); catch; end
    if ~hasVt; continue; end

    id = char(ids{k});
    n  = i_parse_bus_number(id);
    if isnan(n); continue; end   % ignore un noeud 'Vt' non numerote

    try
        vk = i_series_on(node.child('Vt'), timeRef);
    catch
        vk = nan(Nt,1);
    end
    try
        ak = i_series_on(node.child('ph'), timeRef);
    catch
        ak = nan(Nt,1);
    end

    Vcols{end+1} = vk; %#ok<AGROW>
    Acols{end+1} = ak; %#ok<AGROW>
    nums(end+1)  = n;  %#ok<AGROW>
    nms(end+1)   = string(id); %#ok<AGROW>
end

if isempty(Vcols)
    V = []; Vang = []; busNums = zeros(1,0); busNames = strings(1,0);
    return;
end

[busNums, order] = sort(nums);
V    = [Vcols{order}];
Vang = [Acols{order}];
busNames = nms(order);
end


%% ----------------------------------------------------------------------
function v = i_series_on(leafNode, timeRef)
% Lit la serie d'un noeud feuille et la reechantillonne sur timeRef si
% necessaire. Renvoie une colonne Nt x 1.
s = leafNode.series;
t = s.time;  t = t(:);
v = s.values;
if size(v,2) > 1; v = v(:,1); end   % garder la 1re colonne si multi-signaux
v = v(:);
if numel(t) ~= numel(timeRef)
    v = interp1(t, v, timeRef, 'linear', 'extrap');
end
v = v(:);
end


%% ----------------------------------------------------------------------
function n = i_parse_bus_number(id)
% Extrait le premier entier apparaissant apres 'Bus' dans l'id du noeud.
n = NaN;
tok = regexp(id, '^Bus(\d+)', 'tokens', 'once');
if ~isempty(tok)
    n = str2double(tok{1});
end
end
