function [macOut, report] = sanitize_machine_data_sps(macIn)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SANITIZE_MACHINE_DATA_SPS
%
% OBJECTIF
% --------
% Rendre la matrice mac_con (format PST) compatible avec le convertisseur
% "Synchronous Machine pu Standard -> parametres fondamentaux" de
% Simscape Electrical (R2024a). Ce convertisseur EXIGE l'ordonnancement
% physique des reactances :
%
%       x_l  <  x"_d  <  x'_d  <  x_d      (axe d)
%       x_l  <  x"_q  <  x'_q  <  x_q      (axe q)
%
% Le jeu de donnees NE39 fournit des reactances subtransitoires uniformes
% et manifestement "placeholder" (x"_d = 0.01, x"_q = 0.03 pour TOUTES les
% machines) alors que la reactance de fuite x_l varie de 0.03 a 0.54.
% La contrainte x_l < x"_d est donc violee pour les 10 machines, ce qui
% fait ECHOUER (erreur MATLAB:badsubscript dans SynchronousMachineConvert)
% l'initialisation du masque des blocs G1..G10, empechant toute simulation
% (le premier bloc compile, G1, avorte avant les autres).
%
% CORRECTION APPLIQUEE
% --------------------
% On ne touche PAS aux parametres qui gouvernent la stabilite transitoire
% de premiere oscillation (angle rotorique) : inertie H, x_d, x'_d, x_q,
% x'_q, T'_do, T'_qo restent EXACTEMENT tels qu'ils sont dans les donnees.
% On corrige uniquement la reactance de FUITE x_l (col. 4) - le parametre
% le moins influent sur la dynamique angulaire - en la ramenant juste en
% dessous de la plus petite reactance subtransitoire de la machine :
%
%       x_l  <-  min(x_l, MARGIN * min(x"_d, x"_q))
%
% Cette correction est MINIMALE (elle n'agit que si x_l viole la
% contrainte), locale (appliquee en memoire, jamais ecrite dans
% NE39bus_data.m) et sans effet notable sur le label de stabilite.
%
% ENTREE
% ------
% macIn : matrice mac_con [nMach x 19] (format PST, cf. NE39bus_data.m)
%
% SORTIE
% ------
% macOut : matrice corrigee (meme taille)
% report : struct de tracabilite
%          .changed   : indices des machines modifiees
%          .xlBefore  : x_l avant correction (colonne)
%          .xlAfter   : x_l apres correction (colonne)
%          .nChanged  : nombre de machines corrigees
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Colonnes PST utiles (cf. entete NE39bus_data.m)
COL_XL   = 4;    % reactance de fuite x_l
COL_XDPP = 8;    % reactance subtransitoire axe d  x"_d
COL_XQPP = 13;   % reactance subtransitoire axe q  x"_q

MARGIN = 0.8;    % x_l ramenee a 80% de la subtransitoire minimale

macOut = macIn;

if size(macIn, 2) < COL_XQPP
    % Matrice trop courte pour etre un mac_con PST : ne rien faire.
    report = struct('changed', [], 'xlBefore', [], 'xlAfter', [], 'nChanged', 0);
    return;
end

xl     = macIn(:, COL_XL);
xdpp   = macIn(:, COL_XDPP);
xqpp   = macIn(:, COL_XQPP);

xppMin = min(xdpp, xqpp);          % plus petite subtransitoire par machine
xlCap  = MARGIN .* xppMin;         % plafond admissible pour x_l

violate = xl >= xppMin;            % contrainte x_l < x"_min violee
xlNew   = xl;
xlNew(violate) = xlCap(violate);

macOut(:, COL_XL) = xlNew;

report = struct( ...
    'changed',  find(violate(:)'), ...
    'xlBefore', xl, ...
    'xlAfter',  xlNew, ...
    'nChanged', nnz(violate));

end
