function simScape = inspect_simscape_model(cfg)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INSPECT_SIMSCAPE_MODEL
%
% Inspect the Simscape Electrical model and identify all major electrical
% components required by the TSA framework.
%
% This function DOES NOT modify the model.
%
% It creates a complete inventory of the Simscape model and stores the
% information inside network.simscape.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('\n');
fprintf('====================================================\n');
fprintf(' Inspecting Simscape model...\n');
fprintf('====================================================\n');

%% Model name

modelName = cfg.simulation.modelName;

%% Check if model is loaded

if ~bdIsLoaded(modelName)

    load_system(modelName);

end

%% Retrieve all blocks

blocks = find_system(modelName);

nBlocks = length(blocks);

blockNames = strings(nBlocks,1);
blockTypes = strings(nBlocks,1);
maskTypes  = strings(nBlocks,1);
referenceBlocks = strings(nBlocks,1);



simScape.blocks = blocks;

simScape.metadata.modelName = modelName;

simScape.metadata.numberBlocks = length(blocks);


%% Display block information

for i = 1:nBlocks

    block = blocks{i};

    blockNames(i) = string(get_param(block,'Name'));

    try
        blockTypes(i) = string(get_param(block,'BlockType'));
    catch
        blockTypes(i) = "";
    end

    try
        maskTypes(i) = string(get_param(block,'MaskType'));
    catch
        maskTypes(i) = "";
    end

    try
        referenceBlocks(i) = string(get_param(block,'ReferenceBlock'));
    catch
        referenceBlocks(i) = "";
    end

end

%% Build inventory

inventory = struct();

inventory.blockNames = blockNames;

inventory.blockPaths = string(blocks);

inventory.blockTypes = blockTypes;

inventory.maskTypes = maskTypes;

inventory.referenceBlocks = referenceBlocks;

inventory.uniqueBlockTypes = unique(blockTypes);

inventory.uniqueMaskTypes = unique(maskTypes);

inventory.uniqueReferenceBlocks = unique(referenceBlocks);

simScape.inventory = inventory;


%% Summary

fprintf('\n');
fprintf('Unique Mask Types detected : %d\n', ...
    numel(inventory.uniqueMaskTypes));

disp(inventory.uniqueMaskTypes)

disp(inventory.uniqueBlockTypes)

disp(inventory.uniqueReferenceBlocks)

fprintf(' Inspection completed.\n');

fprintf('====================================================\n');

end
