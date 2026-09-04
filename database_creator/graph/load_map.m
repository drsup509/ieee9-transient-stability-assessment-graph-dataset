function nodeMap = load_map(mpc, nbus, nodeMap)
% LOAD_MAP  Tag each node carrying a load (Pd or Qd nonzero) with a load id.

loadID = NaN(nbus,1);

counter = 1;


for i = 1:nbus

    Pd = mpc.bus(i,3);
    Qd = mpc.bus(i,4);

    if Pd ~=0 || Qd ~=0

        loadID(i)=counter;

        counter = counter + 1;

    end

end


nodeMap.loadID = loadID;

end