function network = compute_voltage_stats(network, results)
% COMPUTE_VOLTAGE_STATS  Store min/max/mean/std of bus voltage magnitudes into network.indices.

V = results.bus(:,8);

network.indices.voltageStats.minVoltage = min(V);
network.indices.voltageStats.maxVoltage = max(V);
network.indices.voltageStats.meanVoltage = mean(V);
network.indices.voltageStats.stdVoltage = std(V);

end