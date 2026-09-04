function lineStress = compute_line_stress(network)

%% LINE STRESS
% 
% Réutilisation de line loading déjà calculé (IMPORTANT)
% On suppose :
% network.indices.meanLineLoading esiste
% 

lineStress = network.indices.lineLoading.meanLineLoading;

end