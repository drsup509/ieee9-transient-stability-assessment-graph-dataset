function simIn = configure_simulation_sps(model, cfg)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONFIGURE_SIMULATION_SPS
%
% OBJECTIF
% --------
% Analogue SimPowerSystems de configure_simulation. Construit l'objet
% Simulink.SimulationInput pour la simulation transitoire d'un modele SPS
% (phasor). Contrairement au backend ee, on n'active PAS le Simscape
% logging (simlog) : les signaux rotoriques sont recuperes via le signal
% logging (logsout), instrumente par prepare_fault_infrastructure_sps.
%
% On conserve le parametrage solveur du modele (ode23tb, powergui phasor)
% et on ne modifie que la duree simulee et le logging.
%
% ENTREE
% ------
% model : nom du modele Simulink (char)
% cfg   : configuration globale (cfg.transient)
%
% SORTIE
% ------
% simIn : Simulink.SimulationInput pret pour sim()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

simIn = Simulink.SimulationInput(model);

%% Fenetre temporelle (reutilise cfg.transient.stopTime)
simIn = simIn.setModelParameter('StopTime', num2str(cfg.transient.stopTime));

%% Signal logging (logsout) : porte les angles/vitesses rotoriques
simIn = simIn.setModelParameter('SignalLogging', 'on');
simIn = simIn.setModelParameter('SignalLoggingName', 'logsout');

%% Robustesse : renvoyer les sorties dans un objet SimulationOutput
simIn = simIn.setModelParameter('ReturnWorkspaceOutputs', 'on');

%% Coherence des donnees machine (mac_con)
% Le convertisseur "Synchronous Machine pu Standard" (R2024a) exige
% x_l < x"_d et x_l < x"_q. Le jeu NE39 viole cette contrainte (voir
% sanitize_machine_data_sps). On injecte une copie corrigee de mac_con,
% portee UNIQUEMENT par cette simulation (setVariable), sans modifier le
% workspace de base ni le fichier de donnees. Aucun effet si mac_con est
% absent (modeles SPS n'utilisant pas ce format).
if evalin('base', 'exist(''mac_con'', ''var'')')
    macRaw = evalin('base', 'mac_con');
    [macFix, rep] = sanitize_machine_data_sps(macRaw);
    if rep.nChanged > 0
        simIn = simIn.setVariable('mac_con', macFix);
    end
end

end
