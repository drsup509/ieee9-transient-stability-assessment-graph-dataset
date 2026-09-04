function seed = derive_scenario_seed(cfg, scenarioNumber)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DERIVE_SCENARIO_SEED
%
% OBJECTIF
% --------
% Calculer une graine RNG DETERMINISTE pour un scenario donne, a partir de
% la graine de base du projet et du numero de scenario.
%
% Garantit que le scenario i produit toujours EXACTEMENT les memes tirages
% (charges, generation, defaut), independamment de l'ordre d'execution.
% C'est la condition necessaire pour reprendre un run interrompu
% (checkpoint) sans recalculer les scenarios deja faits.
%
% ENTREES
% -------
% - cfg            : configuration (utilise cfg.project.randomSeed).
% - scenarioNumber : indice entier du scenario (1..N).
%
% SORTIE
% ------
% - seed : entier positif dans [1, 2^31-2], utilisable par rng(seed).
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if isfield(cfg, 'project') && isfield(cfg.project, 'randomSeed') ...
        && ~isempty(cfg.project.randomSeed)
    baseSeed = double(cfg.project.randomSeed);
else
    baseSeed = 0;
end

% Constante multiplicative de Knuth (hachage) pour disperser les indices
% consecutifs. Les calculs restent exacts en double (< 2^53).
KNUTH = 2654435761;

seed = mod(baseSeed + double(scenarioNumber) * KNUTH, 2^31 - 1);

if seed == 0
    seed = 1;   % rng exige une graine > 0
end

end
