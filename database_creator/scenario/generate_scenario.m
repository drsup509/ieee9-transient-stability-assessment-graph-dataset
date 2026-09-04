function network = generate_scenario(network, cfg, scenarioNumber)
%modifie uniquement network et non mpc (update_mpc en est
% repsonsable)

fprintf('\n---------------------------------------------\n');
fprintf(' Generating TSA scenario...\n');
fprintf('---------------------------------------------\n');



% network = scale_loads(network, cfg);
% network = scale_generators(network, cfg);
% network = generate_fault(network, cfg);

network = initialize_scenario(network, scenarioNumber, cfg);

network = generate_area_scaling(network, cfg);

network = scale_loads(network);

network = scale_generators(network);

network = generate_fault(network, cfg);




%% SCENARIO IDENTIFICATION
% Chaque scénario reçoit :
% - un numéro (utile pour suivre la génération)
% - un identifiant unique (UUID)
% - une date de création
%
% Ces informations permettront de retrouver facilement
% un scénario lors des analyses ou des entraînements IA.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

network.metadata.scenarioNumber = scenarioNumber;

network.metadata.scenarioID = char(java.util.UUID.randomUUID);

network.metadata.creationDate = datetime("now");

fprintf('Scenario %d successfully generated.\n', scenarioNumber);

end