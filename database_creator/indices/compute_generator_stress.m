function genStress = compute_generator_stress(Pg, Pmax)
% COMPUTE_GENERATOR_STRESS  Mean generator loading Pg./Pmax (falls back when Pmax is missing).

if exist('Pmax','var') && ~isempty(Pmax)

    fprintf("======================== PMAX =============================\n\n")
    fprintf('Pmax ===== var\n\n');    
    fprintf("======================== FIN PMAX =============================\n\n")

    genStress = mean(Pg ./ (Pmax + eps));

else

    % fallback : utilisation relative simple
    genStress = mean(Pg) / (max(Pg) + eps);

end


end