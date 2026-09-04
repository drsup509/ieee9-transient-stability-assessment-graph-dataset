function network = compute_fault_metadata(network, cfg)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%modifie uniquement network et non mpc (update_mpc en est
% repsonsable)
%
% OBJECTIF
% --------
% Calculer des informations dérivées associées au défaut.
%
% Ces informations sont essentielles pour :
% - analyses de stabilité transitoire (TSA)
% - modèles GNN / PINN
% - interprétation physique des scénarios
%
% IMPORTANT
% ---------
% Cette fonction ne modifie PAS le réseau.
% Elle enrichit uniquement network.fault avec des features.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf(' Computing fault metadata...\n');
% disp(class(network))
% disp(class(network.mpc.bus))
% fprintf(' 2 - Computing fault metadata...\n');

%% INITIALISATION

% nBus = size(network.steadyState.Pd, 1);
nBus = size(network.mpc.bus, 1);


%% 1. TENSION PRE-DEFAUT
%
% Mesure simple basée sur l'état steady-state
%

% V = network.steadyState.V;
V = network.steadyState.V0;

if isempty(V)
    V = ones(nBus,1); % fallback si non disponible
end

% disp(V);
% fprintf(' 3 - Computing fault metadata...\n');


%% 2. NIVEAU DE CHARGE LOCALE (proxy)
%
% Indicateur simple : charge active relative
%

% Pd = network.steadyState.Pd;
Pd = network.steadyState.Pd0;

loadLevel = Pd ./ (max(Pd) + 1e-6);

%% 3. LOCALISATION DU DEFAUT

% faultType = network.fault.locationType; 
faultType = network.fault.type;


%non exploite pour l'instant. 
% on pourra par la suite ajouter un poids à chaque type de défaut 
% par exemple  "3PH" seceirtyFactor 1; "" 0.7; LL 0.8 sinon 0.9

%% 4. DISTANCE ELECTRIQUE (PROXY SIMPLE)
% On utilise une approximation simple :
% distance = |Vbus - Vmean|
%
% (plus tard on remplacera par Ybus / impedance distance)
%

Vmean = mean(V);

electricalDistance = abs(V - Vmean);

% disp('Vmean:');
% disp(Vmean);
% fprintf(' 4 - Computing fault metadata...\n');

%% 5. CRITICITE DU BUS (PROXY GNN READY)
%
% combinaison simple :
% charge + déviation tension
%

busCriticality = loadLevel .* electricalDistance;
% disp('bus criticality')
% disp(busCriticality);
% fprintf(' 5 - Computing fault metadata...\n');

%% 6. IDENTIFICATION DU POINT DE DEFAUT

disp(network.fault);
disp('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx')
if strcmp(network.fault.locationType, "BUS")

    % faultBus = network.fault.bus;
    % faultBus = network.scenario.fault.location.bus;
    faultBus = network.fault.bus;

    network.fault.generatorElectricalDistance = electricalDistance(faultBus);

    network.fault.localVoltage = V(faultBus);

    network.fault.localLoadLevel = loadLevel(faultBus);

    network.fault.criticalityIndex = busCriticality(faultBus);

else

    % défaut sur ligne → moyenne des deux buses

    buses = network.fault.bus;

    network.fault.generatorElectricalDistance = mean(electricalDistance(buses));

    network.fault.localVoltage = mean(V(buses));

    network.fault.localLoadLevel = mean(loadLevel(buses));

    network.fault.criticalityIndex = mean(busCriticality(buses));

end

%% 7. METADATA GLOBALE DU RESEAU
%
% Ces features peuvent être utilisées pour GNN global
%

network.fault.globalVoltageMean = mean(V);
network.fault.globalLoadMean = mean(loadLevel);
network.fault.globalVoltageStd = std(V);

%% STATUT FINAL

network.fault.status = "Complete";

fprintf(' Fault metadata computed.\n');

end
