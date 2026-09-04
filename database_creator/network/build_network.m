function network = build_network(mpc, cfg)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% OBJECTIF:
% Construire un objet réseau complet pour TSA + PINN + GNN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf(' -> Building network object...\n');

%% BASE / MPC

network.base = mpc;
network.mpc = mpc;

% compatibility layer (IMPORTANT pour éviter casse immédiate)
network.bus = network.mpc.bus;
network.gen = network.mpc.gen;
network.branch = network.mpc.branch;

%% METADATA

network.metadata.caseName = cfg.project.caseName;
network.metadata.areas = unique(mpc.bus(:,7));

network.metadata.nbBus = size(mpc.bus,1);
network.metadata.nbGen = size(mpc.gen,1);
network.metadata.nbBranch = size(mpc.branch,1);

network.metadata.version = "stable_v1";

%% STEADY STATE (ESSENTIEL TSA)

network.steadyState.V0 = mpc.bus(:,8);
network.steadyState.theta0 = mpc.bus(:,9);

network.steadyState.Pg0 = mpc.gen(:,2);
network.steadyState.Qg0 = mpc.gen(:,3);

network.steadyState.Pd0 = mpc.bus(:,3);
network.steadyState.Qd0 = mpc.bus(:,4);

network.steadyState.totalLoad0 = sum(mpc.bus(:,3));
network.steadyState.totalGen0 = sum(mpc.gen(:,2));

%% GRAPH (GNN READY)

% network.graph.nodeCount = size(mpc.bus,1);
% 
% network.graph.edgeIndex = mpc.branch(:,1:2)';
% 
% network.graph.edgeAttr.R = mpc.branch(:,3);
% network.graph.edgeAttr.X = mpc.branch(:,4);
% network.graph.edgeAttr.B = mpc.branch(:,5);
% 
% network.graph.nodeAttr.busType = mpc.bus(:,2);
% network.graph.nodeAttr.area = mpc.bus(:,7);

network.topology = struct();

%% SCENARIO 

network.scenario = struct();
network.scenario.id = [];
network.scenario.randomSeed = [];

network.scenario.areaScaling = struct([]);
% network.scenario.fault = struct();
network.scenario.summary = struct();

%% FAULT (INITIAL EMPTY STRUCTURE)

network.fault.type = "";
network.fault.status = "";
network.fault.locationType = "";
network.fault.line = "";
network.fault.location = "";
network.fault.bus = [];
network.fault.startTime = "";
network.fault.clearTime = "";
network.fault.duration = "";
network.fault.impedance = struct();
network.fault.generatorElectricalDistance = "";
network.fault.localVoltage = "";
network.fault.localLoadLevel = "";
network.fault.criticalityIndex = "";
network.fault.globalVoltageMean = "";
network.fault.globalLoadMean = "";
network.fault.globalVoltageStd = "";


% network.fault.type = "";
% network.fault.location.bus = [];
% network.fault.location.line = [];
% network.fault.time.on = [];
% network.fault.time.off = [];
% network.fault.impedance = [];

%% INDICES (TSA / STABILITY)

network.indices.loadDiversityP = [];
network.indices.loadDiversityQ = [];

network.indices.stress = [];
network.indices.voltageMargin = [];

network.indices.lossRatio = [];

network.indices.inertia = [];
network.indices.shortCircuitLevel = [];

network.indices.maxOmegaDeviation = [];
network.indices.kineticEnergy = [];

%% DYNAMIC (SIMULATION OUTPUT)

network.dynamic.time = [];

network.dynamic.delta = [];
network.dynamic.omega = [];

network.dynamic.Pe = [];
network.dynamic.Pm = [];

network.dynamic.voltage = [];
network.dynamic.frequency = [];

%% LABELS (TSA / ML)

network.label.stable = [];

network.label.CCT = [];

network.label.maxRotorAngle = [];

network.label.energyMargin = [];

network.label.instability.mode = "";
network.label.instability.time = [];
network.label.instability.bus = [];

%% PHYSICS (PINN)


network.physics.Ybus = [];

network.physics.inertiaMatrix = [];
network.physics.dampingMatrix = [];
network.physics.electricalDistance = [];

network.physics.swingEquation.M = [];
network.physics.swingEquation.D = [];
network.physics.swingEquation.Pe = [];
network.physics.swingEquation.Pm = [];


%% SIMULATION CONFIG

network.simulation.modelName = cfg.simulation.modelName;
network.simulation.stopTime = cfg.simulation.stopTime;
network.simulation.timeStep = cfg.simulation.timeStep;
network.simulation.solver = cfg.simulation.solver;

%% RUNTIME (TEMP ONLY)

network.runtime.powerFlow = [];
network.runtime.simOut = [];

%% TEST BLOCK (VALIDATION IMMÉDIATE)

fprintf(' -> Running build_network validation...\n');

assert(isfield(network,'base'), 'base missing');
assert(isfield(network,'mpc'), 'mpc missing');
assert(~isempty(network.metadata.areas), 'areas missing');
% assert(size(network.graph.edgeIndex,1) == 2, 'graph edgeIndex invalid');
assert(~isempty(network.steadyState.V0), 'steady state missing');

fprintf('build_network OK\n');

end
