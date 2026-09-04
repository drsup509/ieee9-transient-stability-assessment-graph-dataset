function network = compute_line_loading(network, results)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COMPUTE_LINE_LOADING
%
% OBJECTIF
% --------
% Calculer le pourcentage de chargement de chaque ligne ainsi que les
% statistiques principales.
%
% ENTREES
% -------
% results : résultats du Power Flow MATPOWER
%
% SORTIE
% ------
% lineLoading : structure contenant les informations de chargement
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% INITIALISATION

define_constants;

lineLoading.vector = [];
lineLoading.maximum = NaN;
lineLoading.mean = NaN;
lineLoading.overloaded = false;


%% CALCUL DU CHARGEMENT
%
% MATPOWER :
% PF = colonne 14
% QF = colonne 15
% RATE_A = colonne 6
%

pF = results.branch(:,PF);
% PF = results.branch(:,PF)

% results.branch(:,15)
qF = results.branch(:,QF);

% results.branch(:,6);
rate_a = results.branch(:,RATE_A);

S = sqrt(pF.^2 + qF.^2);

loading = NaN(size(S));

valid = rate_a > 0;

loading(valid) = S(valid) ./ rate_a(valid);

%% STATISTIQUES

lineLoading.vector = loading;
lineLoading.maximum = max(loading,[],"omitnan");
lineLoading.mean = mean(loading,"omitnan");
lineLoading.std = std(loading,"omitnan");

%% Correction si limite thermique non fournie
%
%si rate a non fournies alors mettre 0 à la place des nan
%

lineLoading.vector = fillmissing(loading,"constant",0);
lineLoading.maximum(isnan(lineLoading.maximum)) = 0;
lineLoading.mean(isnan(lineLoading.mean)) = 0;
lineLoading.std(isnan(lineLoading.std)) = 0;

%% Mise à jour network

network.indices.lineLoading.vector = lineLoading.vector*100;
network.indices.lineLoading.maxLineLoading = lineLoading.maximum; %per unit
network.indices.lineLoading.meanLineLoading = lineLoading.mean; %per unit
network.indices.lineLoading.stdLineLoading = lineLoading.std; 





%% Ancien code
% if size(results.branch,2) >= 14
% 
%     fprintf('\nlineloading\n\n');
%     lineLoading = compute_line_loading(results);
% 
%     network.indices.lineLoading.vector = lineLoading.vector*100;
%     network.indices.lineLoading.maxLineLoading = lineLoading.maximum;
%     network.indices.lineLoading.meanLineLoading = lineLoading.mean;
%     network.indices.lineLoading.stdLineLoading = lineLoading.std;
% 
%     network.indices
%     fprintf('\nfin lineloading\n\n');
% 
% else
% 
%     % network.indices.maxLineLoading = NaN;
%     % network.indices.meanLineLoading = NaN;
%     % network.indices.stdLineLoading = NaN;
% 
%     network.indices.lineLoading.maxLineLoading = NaN;
%     network.indices.lineLoading.meanLineLoading = NaN;
%     network.indices.lineLoading.stdLineLoading = NaN;
% 
% end

end
