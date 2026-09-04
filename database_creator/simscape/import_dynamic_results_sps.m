function dyn = import_dynamic_results_sps(out, cfg) %#ok<INUSD>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% IMPORT_DYNAMIC_RESULTS_SPS
%
% OBJECTIF
% --------
% Analogue SimPowerSystems de import_dynamic_results. Extrait, depuis le
% signal logging (logsout) d'une simulation SPS phasor, les series
% temporelles rotoriques par machine et les normalise dans la MEME
% structure "dyn" que le backend ee (contrat identique en aval).
%
% SOURCE DES DONNEES
% ------------------
% prepare_fault_infrastructure_sps logue, par machine n :
%   tsa_dtheta_{n} : deviation d'angle rotorique [rad]
%   tsa_omega_{n}  : vitesse rotorique [pu]
% L'indice n identifie la machine sans ambiguite (pas d'ordre de mux).
%
% ENTREE
% ------
% out : Simulink.SimulationOutput (contient 'logsout')
% cfg : configuration globale (non utilisee ici)
%
% SORTIE
% ------
% dyn.time     : Nt x 1     temps [s]
% dyn.delta    : Nt x nGen  angle rotorique [rad] (deviation)
% dyn.omega    : Nt x nGen  vitesse rotorique [pu]
% dyn.genNames : 1 x nGen   noms des machines ("G1".."Gn")
% dyn.nGen     : nombre de machines
% dyn.success  : true si au moins une machine a ete extraite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

dyn = struct('time', [], 'delta', [], 'omega', [], ...
    'genNames', strings(1,0), 'nGen', 0, 'success', false);

%% Recuperer le dataset de signal logging

if ~ismember('logsout', out.who)
    return;   % pas de log -> echec silencieux, gere par validate_dynamic_results
end

ls = out.get('logsout');

%% Recenser les noms d'elements et les indices de machine presents

nEl = ls.numElements;
elemNames = strings(nEl, 1);
for k = 1:nEl
    elemNames(k) = string(ls.get(k).Name);
end

idxSet = [];
for k = 1:nEl
    tok = regexp(elemNames(k), '^tsa_dtheta_(\d+)$', 'tokens', 'once');
    if ~isempty(tok)
        idxSet(end+1) = str2double(tok{1}); %#ok<AGROW>
    end
end
idxSet = sort(unique(idxSet));

if isempty(idxSet)
    return;
end

%% Assembler les colonnes par machine (ordre = indice croissant)

timeRef   = [];
deltaCols = {};
omegaCols = {};
names     = strings(1,0);

for j = 1:numel(idxSet)
    n = idxSet(j);

    % Angle rotorique (obligatoire).
    dEl = ls.get(sprintf('tsa_dtheta_%d', n));
    tsD = dEl.Values;
    td  = tsD.Time(:);
    dd  = squeeze(tsD.Data);
    dd  = dd(:);

    if isempty(timeRef)
        timeRef = td;
    elseif numel(td) ~= numel(timeRef)
        dd = interp1(td, dd, timeRef, 'linear', 'extrap');
    end

    % Vitesse rotorique (optionnelle : repli a 1 pu si absente).
    omega = ones(size(timeRef));
    if any(elemNames == sprintf("tsa_omega_%d", n))
        oEl = ls.get(sprintf('tsa_omega_%d', n));
        tsO = oEl.Values;
        to  = tsO.Time(:);
        oo  = squeeze(tsO.Data);
        oo  = oo(:);
        if numel(to) ~= numel(timeRef)
            oo = interp1(to, oo, timeRef, 'linear', 'extrap');
        end
        omega = oo;
    end

    deltaCols{end+1} = dd(:);         %#ok<AGROW>
    omegaCols{end+1} = omega(:);      %#ok<AGROW>
    names(end+1)     = sprintf("G%d", n); %#ok<AGROW>
end

%% Assemblage matriciel (Nt x nGen)

dyn.time     = timeRef;
dyn.delta    = [deltaCols{:}];
dyn.omega    = [omegaCols{:}];
dyn.genNames = names;
dyn.nGen     = numel(names);
dyn.success  = true;

end
