function simIn = configure_simulation(model, cfg)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONFIGURE_SIMULATION
%
% OBJECTIF
% --------
% Construire l'objet Simulink.SimulationInput utilise pour la simulation
% transitoire, a partir de la configuration centralisee (cfg.transient).
%
% Cette fonction NE lance PAS la simulation et ne modifie PAS le modele
% de facon persistante : elle prepare uniquement les parametres solveur
% et active le Simscape logging necessaire a import_dynamic_results.
%
% ENTREES
% -------
% model : nom du modele Simulink (char)
% cfg : configuration globale (voir config.m -> cfg.transient)
%
% SORTIE
% ------
% simIn : Simulink.SimulationInput pret pour sim()
%
% LICENCE
% -------
% La simulation dynamique requiert Simscape Electrical. Cette fonction ne
% verifie pas la licence : c'est le role de run_dynamic_simulation.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

simIn = Simulink.SimulationInput(model);

%% Fenetre temporelle
%
% On conserve le parametrage solveur du modele (deja adapte au reseau
% SPS) et on ne modifie que la duree simulee et le logging.

simIn = simIn.setModelParameter('StopTime', num2str(cfg.transient.stopTime));

%% Simscape logging
%
% Le Simscape logging capture toutes les variables physiques (angles
% rotoriques, vitesses, tensions) sans instrumenter le modele.

simIn = simIn.setModelParameter('SimscapeLogType', 'all');
simIn = simIn.setModelParameter('SimscapeLogName', 'simlog');

%% Robustesse : renvoyer les sorties dans un objet SimulationOutput

simIn = simIn.setModelParameter('ReturnWorkspaceOutputs', 'on');

end
