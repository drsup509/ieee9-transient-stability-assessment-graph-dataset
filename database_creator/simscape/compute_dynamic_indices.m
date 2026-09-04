function indices = compute_dynamic_indices(dyn, cfg)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COMPUTE_DYNAMIC_INDICES
%
% OBJECTIF
% --------
% Calculer les indicateurs de stabilite transitoire a partir des series
% temporelles rotoriques importees par import_dynamic_results.
%
% Cette fonction ne fait AUCUNE lecture de modele et AUCUNE simulation :
% elle opere uniquement sur des vecteurs numeriques.
%
% ENTREE
% ------
% dyn : struct produit par import_dynamic_results, avec les champs
%       .time  (Nt x 1)  temps [s]
%       .delta (Nt x nGen) angle electrique rotorique [rad]
%       .omega (Nt x nGen) vitesse rotorique [pu]
%       .genNames (1 x nGen) noms des generateurs
% cfg : configuration globale
%
% SORTIE
% ------
% indices.maxAngleSeparationDeg  : separation angulaire max entre machines
% indices.finalAngleSeparationDeg: separation en fin de fenetre
% indices.maxSpeedDeviation      : deviation de vitesse max |w-1| [pu]
% indices.timeOfMaxSeparation    : instant de la separation max [s]
% indices.angleSeparationSeries  : separation(t) [deg] (Nt x 1)
%
% CRITERE TSA
% -----------
% La separation angulaire est definie comme l'ecart max-min entre les
% angles rotoriques (deroules) de toutes les machines a chaque instant.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

indices = struct();

t     = dyn.time(:);
delta = dyn.delta;   % Nt x nGen [rad]
omega = dyn.omega;   % Nt x nGen [pu]

nGen = size(delta, 2);

%% 1. REFERENCE AU CENTRE D'INERTIE (COI)
%
% L'angle electrique rotorique fourni est ABSOLU (il accumule 2*pi*f*t).
% On retranche la moyenne inter-machines (approximation du centre
% d'inertie) pour eliminer la rotation commune et obtenir les angles
% RELATIFS, seuls pertinents pour la separation.
%
% On n'applique PAS unwrap ici : les angles fournis sont deja continus
% (non replies), et unwrap corromprait un signal a fort taux de variation.

if nGen >= 1
    coi = mean(delta, 2);
    deltaRel = delta - coi;   % Nt x nGen, angles relatifs [rad]
else
    deltaRel = delta;
end

%% 2. SEPARATION ANGULAIRE (max - min entre machines, a chaque instant)

if nGen >= 2
    sepRad = max(deltaRel, [], 2) - min(deltaRel, [], 2);
else
    % Une seule machine : pas de separation relative possible.
    sepRad = zeros(size(t));
end

sepDeg = rad2deg(sepRad);

[maxSepDeg, idxMax] = max(sepDeg);

indices.angleSeparationSeries   = sepDeg;
indices.maxAngleSeparationDeg   = maxSepDeg;
indices.finalAngleSeparationDeg = sepDeg(end);
indices.timeOfMaxSeparation     = t(idxMax);

%% 3. DEVIATION DE VITESSE

speedDev = abs(omega - 1);          % ecart au synchronisme [pu]
indices.maxSpeedDeviation = max(speedDev(:));

%% 4. DIVERGENCE MONOTONE (indicateur secondaire)
%
% Si la separation croit encore fortement en fin de fenetre, la machine
% est probablement en train de decrocher.

if numel(t) >= 2
    indices.finalSeparationSlope = (sepDeg(end) - sepDeg(max(1,end-1))) ...
        / max(eps, t(end) - t(max(1,end-1)));
else
    indices.finalSeparationSlope = 0;
end

indices.numGenerators = nGen;

end
