function nodeMap = generator_map(mpc, nbus, nodeMap)
% GENERATOR_MAP  Tag each node with its generator id (NaN where no generator).

generatorID = NaN(nbus,1);

for i = 1:size(mpc.gen,1)

    busNumber = mpc.gen(i,1);

    idx = find(nodeMap.busNumber == busNumber);

    if ~isempty(idx)

        generatorID(idx)=i;

    end

end


nodeMap.generatorID = generatorID;

end