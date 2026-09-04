function network = choose_fault_impedance(network, cfg)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CHOOSE_FAULT_IMPEDANCE
%
% OBJECTIF
% --------
% Définir l'impédance du défaut (résistance et réactance).
%
% IMPORTANCE TSA
% --------------
% L'impédance de défaut influence directement :
% - le courant de court-circuit
% - la sévérité du défaut
% - la dynamique rotorique
% - la stabilité transitoire
%
% CAS CONSIDERES
% --------------
% - Défaut idéal (Rf = 0, Xf = 0)
% - Défaut résistif
% - Défaut plus réaliste (résistance non nulle)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf(' Selecting fault impedance...\n');


%% DEFAULT VALUES
%
% On considère souvent un défaut idéal (bolted)
%

Rf = 0;
Xf = 0;

%% POSSIBLE EXTENSION (FUTURE)
%
% Structure prête pour évolution :
% - défaut résistif
% - défaut haute impédance
%

useRealisticFault = false;

if isfield(cfg.fault, 'useRealisticImpedance')
    useRealisticFault = cfg.fault.useRealisticImpedance;
end

%% IMPEDANCE MODEL

if useRealisticFault

    % Résistance de défaut (petite mais non nulle)
    Rf = 0.001 + (0.01 - 0.001) * rand;

    % Réactance de défaut (faible inductance parasite)
    Xf = 0.0001 + (0.005 - 0.0001) * rand;

end

%% STORE RESULTS

network.fault.impedance.R = Rf;
network.fault.impedance.X = Xf;

%% STATUS

network.fault.status = "ImpedanceDefined";

fprintf(' Fault impedance: R = %.5f, X = %.5f\n', Rf, Xf);

end
