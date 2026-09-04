function mpcUpdated = sanity_check_post_update(mpcUpdated)
%% SANITY CHECKS AFTER UPDATING MATPOWER
% % Vérifications simples permettant de détecter rapidement un scénario
% % incorrect avant de lancer le Power Flow.


% Vérifier l'absence de valeurs invalides
if any(isnan(mpcUpdated.bus(:,3))) || any(isnan(mpcUpdated.bus(:,4)))
    error('NaN detected in bus loads.');
end

if any(isinf(mpcUpdated.bus(:,3))) || any(isinf(mpcUpdated.bus(:,4)))
    error('Infinite value detected in bus loads.');
end

%%%%%%%%%%%%%%%%%%%%%%%% INFORMATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


fprintf(' Loads updated : %d buses\n', size(mpcUpdated.bus,1));
fprintf(' Generators updated : %d generators\n', size(mpcUpdated.gen,1));


fprintf(' MATPOWER case successfully updated.\n');
