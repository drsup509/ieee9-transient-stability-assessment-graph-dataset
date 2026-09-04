function edgeMap = import_electrical_param(edgeMap, mpc)
% IMPORT_ELECTRICAL_PARAM  Copy branch electrical parameters (R, X, B, tap, ratings) into the edge map.

edgeMap.R = mpc.branch(:,3);
edgeMap.X = mpc.branch(:,4);
edgeMap.B = mpc.branch(:,5);

edgeMap.tap = mpc.branch(:,9);
edgeMap.shift = mpc.branch(:,10);

edgeMap.rateA = mpc.branch(:,6);
edgeMap.rateB = mpc.branch(:,7);
edgeMap.rateC = mpc.branch(:,8);

edgeMap.status = mpc.branch(:,11);

end