function nodeMap = node_map(mpc, nodeMap)

% Bus type MATPOWER
nodeMap.busType = mpc.bus(:,2);


% Voltage level
nodeMap.baseKV = mpc.bus(:,10);


% Area and zone

nodeMap.area = mpc.bus(:,7);

nodeMap.zone = mpc.bus(:,11);

end