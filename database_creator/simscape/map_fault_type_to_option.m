function option = map_fault_type_to_option(faultType, cfg)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MAP_FAULT_TYPE_TO_OPTION
%
% OBJECTIF
% --------
% Convertir le type de défaut sémantique choisi par le scénario
% (choose_fault_type) en valeur numérique attendue par le paramètre
% "Failure mode" (fault_type_option) du bloc ee "Fault (Three-Phase)".
%
% Fonction à responsabilité unique : simple traduction via la table de
% correspondance centralisée dans config.m
% (cfg.transient.fault.typeLabels / typeOptions).
%
% ENTREE
% ------
% faultType : type de défaut sémantique (string/char), ex. "3PH", "3PHG",
%             "LG", "LL", "LLG".
% cfg       : configuration globale.
%
% SORTIE
% ------
% option    : entier 0..11 attendu par le bloc ee (voir config.m pour la
%             correspondance officielle MathWorks).
%
% COMPORTEMENT
% ------------
% Si le type n'est pas trouvé dans la table, on retombe sur la valeur de
% repli cfg.transient.fault.typeOption en émettant un avertissement, afin
% de ne jamais bloquer la génération du dataset.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

labels  = string(cfg.transient.fault.typeLabels);
options = cfg.transient.fault.typeOptions;

idx = find(labels == string(faultType), 1);

if isempty(idx)
    option = cfg.transient.fault.typeOption;   % repli
    warning('tsa:map_fault_type:unknownType', ...
        ['Type de défaut "%s" absent de la table de correspondance. ' ...
         'Utilisation de la valeur de repli fault_type_option = %d.'], ...
        string(faultType), option);
    return;
end

option = options(idx);

end
