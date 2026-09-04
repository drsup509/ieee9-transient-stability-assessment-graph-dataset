function sepDeg = compute_coi_separation(transient)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COMPUTE_COI_SEPARATION  (post-traitement)
%
% OBJECTIF
% --------
% Reconstruire la serie temporelle de la separation angulaire inter-
% machines, referee au centre d'inertie (COI), a partir des angles
% rotoriques stockes dans un echantillon.
%
% Cette fonction reproduit EXACTEMENT la logique de
% compute_dynamic_indices.m (reference COI, pas d'unwrap) afin que le
% post-traitement soit coherent avec le label deja calcule.
%
% ENTREE
% ------
% transient : struct sample.transient, doit contenir
%             .delta (Nt x nGen) [rad] angles rotoriques absolus
%
% SORTIE
% ------
% sepDeg : Nt x 1, separation angulaire (max-min entre machines) [deg]
%          Vide si les donnees dynamiques sont absentes.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

sepDeg = [];

if ~isfield(transient,'delta') || isempty(transient.delta)
    return;
end

delta = transient.delta;      % Nt x nGen [rad]

if size(delta,2) < 2
    % Une seule machine : pas de separation relative possible.
    sepDeg = zeros(size(delta,1),1);
    return;
end

coi      = mean(delta, 2);
deltaRel = delta - coi;                       % angles relatifs [rad]
sepRad   = max(deltaRel, [], 2) - min(deltaRel, [], 2);
sepDeg   = rad2deg(sepRad);

end
