function cfg = config()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Pour rendre le framework évolutif,
% toutes les informations de configuration sont centraliéses ici.
% Les fonctions ne font que les utiliser.
% afin de pouvoir modifier les
% scénarios sans changer les fonctions du framework.
%
%
% 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% PROJECT CONFIGURATION

cfg.project.name = 'an_nou_fel';

% Racine du projet tsa_project (dossier parent de config/), calculee a partir
% de l'emplacement de ce fichier -> chemins robustes independants du cwd.
cfg.project.rootPath = fileparts(fileparts(mfilename('fullpath')));

cfg.project.caseName = 'case_IEEE9BusSystem';

cfg.simulation.modelName = 'IEEE9BusSystem';
cfg.project.randomSeed = 1234; % graine RNG globale -> reproductibilite du dataset

%% DATASETCONFIGURATION

cfg.dataset.numberScenarios = 20000; %10000

cfg.dataset.saveAcceptedOnly = false;

cfg.dataset.outputFolder = "datasets";

cfg.dataset.verbose = true;

% Sauvegarde de securite pour les longs runs : ecrire un checkpoint tous les
% checkpointEvery scenarios. resume=true reprend un run interrompu sans
% recalculer les scenarios deja faits (graine deterministe par scenario).
cfg.dataset.checkpointEvery = 500; %500
cfg.dataset.resume = false; %true

%% LOAD SCENARIO GENERATION (correlated)

% cfg.load.nZones = 3;

cfg.load.globalMinFactor = 0.90;
cfg.load.globalMaxFactor = 1.10;

cfg.load.zoneMinFactor = 0.95;
cfg.load.zoneMaxFactor = 1.15;

cfg.load.localMinFactor = 0.90;
cfg.load.localMaxFactor = 1.10;

cfg.load.keepPowerFactor = true;



cfg.scenario.loadScaling.min = .6;
cfg.scenario.loadScaling.max = 1.25;

%% GENERATION

cfg.generator.min = 0.90;
cfg.generator.max = 1.10;

cfg.scenario.generatorScaling.min = .9;
cfg.scenario.generatorScaling.max = 1.1;

%% FAULT CONFIGURATION

cfg.fault.startTime = 1.0;
% Plage de temps d'elimination calibree sur le balayage CCT IEEE9 (3PH bus) :
% CCT ~0.13 s (bus7 faible) a ~0.35 s (bus6 fort). La plage [0.08, 0.45] s
% chevauche tous les CCT et produit un melange ~50/50 STABLE/UNSTABLE.
% La plage [0.08, 0.40] s NE39's 0.35, so expect a reasonable but slightly stable-leaning balance

cfg.fault.minClearingTime = 0.08;
cfg.fault.maxClearingTime = 0.45;

cfg.fault.availableTypes = "3PHG"; %peut être une liste de défaut donc liste de proba plus bas
cfg.fault.typeProbability = 1.0; %% Probabilité associée à chaque type; % La somme des probabilités doit être égale à 1.

cfg.fault.probaLinevsBus = 0.7;


%% GRAPH

cfg.graph.bidirectional = true;

%% SIMULATION
cfg.simulation.stopTime = 5;
cfg.simulation.timeStep = 0.001;
cfg.simulation.solver = 'ode23tb';


%% TRANSIENT STABILITY ANALYSIS (Simscape dynamic layer)
%
% Toute la configuration de la couche transitoire est centralisée ici.
% Les fonctions du dossier simscape/ ne font que consommer ces valeurs.
%
% NOTE LICENCE : la simulation dynamique nécessite Simscape Electrical.
% Utiliser un MATLAB disposant de Simscape Electrical. Le MATLAB de base échoue.

cfg.transient.enable = true;          % activer/désactiver la couche transitoire

% BACKEND de simulation dynamique. Deux paradigmes Simulink coexistent :
%   'simscape-ee' : Simscape Electrical (ee_lib) -> modèle IEEE9BusSystem.
%                   Blocs Busbar, Fault (Three-Phase), Solver Configuration,
%                   résultats via Simscape logging (simlog).
%   'sps-powerlib': SimPowerSystems classique (powerlib)
%                   Load Flow Bus, Synchronous Machine (SPS), powergui.
%                   NON encore implémenté (backend séparé à venir).
%   'auto'        : détecte le paradigme du modèle et vérifie la compatibilité.
% Actuellement, seul 'simscape-ee' est pris en charge par la couche transitoire.
cfg.transient.backend = 'auto';

% Fenêtre et solveur de simulation (réutilise cfg.simulation.*)
% 3 s suffit : defaut a t=1 s -> 2 s de fenetre post-defaut pour classer
% STABLE/UNSTABLE (valide par le balayage CCT). Reduit le cout par scenario.
cfg.transient.stopTime = 3.0;         % s : durée totale simulée
cfg.transient.solver   = 'ode23tb';   % solveur Simscape recommandé (stiff)
cfg.transient.maxStep  = 1e-3;        % s : pas maximal

% Paramètres du bloc Fault (Three-Phase) de ee_lib
% fault_type_option : index du menu déroulant "Failure mode" du bloc (0..11).
% Correspondance officielle (doc MathWorks) :
%   0  = None (inactif)
%   1  = Single-phase to ground (a-g)   |  2 = (b-g)  |  3 = (c-g)     -> LG
%   4  = Two-phase (a-b)                |  5 = (b-c)  |  6 = (c-a)     -> LL
%   7  = Two-phase to ground (a-b-g)    |  8 = (b-c-g)|  9 = (c-a-g)   -> LLG
%   10 = Three-phase (a-b-c, non relié à la terre)                    -> 3PH
%   11 = Three-phase to ground (a-b-c-g, le plus sévère)              -> 3PHG
cfg.transient.fault.typeOption = 11;  % valeur de repli si type de scénario inconnu

% TABLE DE CORRESPONDANCE type de défaut (scénario) -> option du bloc ee.
% Utilisée par simscape/map_fault_type_to_option.m pour propager le type
% choisi par choose_fault_type dans la simulation dynamique.
% Les deux tableaux sont alignés par position.
cfg.transient.fault.typeLabels  = ["3PH", "3PHG", "LG", "LL", "LLG"];
cfg.transient.fault.typeOptions = [   10,     11,    1,    4,     7];

% Résistances de défaut (bolted par défaut). Le bloc ee EXIGE des valeurs
% strictement positives : minResistance sert de plancher lorsque l'impédance
% du scénario vaut 0 (défaut franc).
cfg.transient.fault.Rpn        = 1e-3;% Ohm : résistance phase-neutre (repli)
cfg.transient.fault.Rng        = 1e-3;% Ohm : résistance neutre-terre (repli)
cfg.transient.fault.minResistance = 1e-3; % Ohm : plancher (défaut franc)

% Capture des résultats
cfg.transient.logDecimation = 1;      % décimation du signal logging

%% STABILITY LABEL
%
% Critère de labellisation TSA (utilisé par labels/compute_stability_label.m)
% Label STABLE/UNSTABLE basé sur la séparation angulaire rotorique maximale.

cfg.label.angleSeparationThresholdDeg = 180;  % > seuil => UNSTABLE
cfg.label.speedDeviationThreshold     = 0.05; % pu : indicateur secondaire (info)


%% POWER FLOW VALIDATION THRESHOLDS
%
% Ces seuils définissent la classification :
% - ACCEPTED
% - BORDERLINE
% - REJECTED
%
% Ils sont utilisés dans validate_powerflow.m
%
cfg.powerflow.validation.accepted.minVoltage = 0.94;
cfg.powerflow.validation.accepted.maxVoltage = 1.06;

cfg.powerflow.validation.borderline.minVoltage = 0.90;
cfg.powerflow.validation.borderline.maxVoltage = 1.10;

cfg.powerflow.validation.rejected.minVoltage = 0.8;
cfg.powerflow.validation.rejected.maxVoltage = 1.2;

cfg.powerflow.validation.lineLoadingThreshold = 0.90; % 90% loading en pu dans code

cfg.powerflow.validation.rejectNaN = true;
cfg.powerflow.validation.rejectNonConvergence = true;

cfg.powerflow.validation.maxPowerImbalance = 1e-3;

cfg.powerflow.validation.minPowerSlack = 0.3; % 30% Pmax gen slack bus pour Pmin si non indiqué

%% STRESS Threshold

cfg.stress.weights.line = 0.4;
cfg.stress.weights.voltage = 0.3;
cfg.stress.weights.generator = 0.3;






%% Matpower réseau de distribution
%
%
% case4_dist : réseau de distribution radial à 4 nœuds. [matpower.app]
% case18 : réseau radial à 18 nœuds. [matpower.app]
% case22 : réseau radial à 22 nœuds. [matpower.app]
% case33bw : célèbre réseau de distribution radial de 33 nœuds de Baran & Wu. [matpower.org], [matpower.app]
% case69 : réseau de distribution radial de 69 nœuds, dérivé du système de Baran & Wu/Das. [github.com], [matpower.app]
% case85 : réseau radial à 85 nœuds. [matpower.app]
% case141 : réseau radial à 141 nœuds. [matpower.app]
%



end
