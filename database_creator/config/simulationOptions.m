function opt = simulationOptions()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SIMULATION OPTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% MATPOWER
opt.matpower.verbose = 0;
opt.matpower.maxIteration = 20;
opt.matpower.tolerance = 1e-8;

%% SIMULINK
opt.simulink.solver = 'ode23tb';
opt.simulink.stopTime = 5;
opt.simulink.fixedStep = 1e-3;

%% DATASET
opt.dataset.saveVersion = '-v7.3';

end
