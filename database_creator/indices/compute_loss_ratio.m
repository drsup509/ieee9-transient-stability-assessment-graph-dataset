function network = compute_loss_ratio(network, results)

%% ACTIVE / REACTIVE LOAD

Pd = results.bus(:,3);
Qd = results.bus(:,4);

network.indices.lossRatio.totalLoadP = sum(Pd);
network.indices.lossRatio.totalLoadQ = sum(Qd);

%% ACTIVE / REACTIVE GENERATION

Pg = results.gen(:,2);
Qg = results.gen(:,3);

network.indices.lossRatio.totalGenerationP = sum(Pg);
network.indices.lossRatio.totalGenerationQ = sum(Qg);

%% POWER lossRatio

network.indices.lossRatio.activeLoss = ...
    network.indices.lossRatio.totalGenerationP - network.indices.lossRatio.totalLoadP;

network.indices.lossRatio.reactiveLoss = ...
    network.indices.lossRatio.totalGenerationQ - network.indices.lossRatio.totalLoadQ;

if network.indices.lossRatio.totalLoadP > 0
    % network.indices.lossRatio = ...
    %     network.indices.activeLoss / network.indices.totalLoadP;
    % network.indices.lossRatio
    network.indices.lossRatio.lossratio_pu = ...
        network.indices.lossRatio.activeLoss / network.indices.lossRatio.totalGenerationP;
else
    network.indices.lossRatio.lossRatio = NaN;
end