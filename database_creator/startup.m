function startup()
% STARTUP  Add all repository folders to the MATLAB search path.
%   Run once at the start of a MATLAB session before generating a dataset:
%       >> startup
%
%   MATPOWER is a required, separate dependency. Install it and add it to the
%   path first (see README.md). Simscape Electrical is required for the
%   transient (dynamic) layer.

thisDir = fileparts(mfilename('fullpath'));
addpath(genpath(thisDir));

% MATPOWER check (steady-state power-flow engine).
if exist('loadcase', 'file') ~= 2
    warning('tsa:startup:noMatpower', ...
        ['MATPOWER not found on the path. Install MATPOWER (8.0) and add ', ...
         'it to the path before running (see README.md).']);
end

% Simscape Electrical check (dynamic layer).
if ~(license('test', 'Simscape') || license('test', 'Simscape_Electrical'))
    warning('tsa:startup:noSimscape', ...
        ['Simscape / Simscape Electrical license not detected. The transient ', ...
         'layer (cfg.transient.enable) needs it. Set cfg.transient.enable = ', ...
         'false to run the steady-state part only.']);
end

fprintf('IEEE9 TSA dataset generator: paths added.\n');
end
