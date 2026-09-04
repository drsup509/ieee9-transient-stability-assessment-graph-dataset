function voltageStress = compute_voltage_stress(V)

%% VOLTAGE STRESS
%
% Mesure de l'écart des tensions autour de 1 pu
%

if ~isempty(V)
    voltageStress = mean(abs(V - 1));
else
    voltageStress = NaN;
end

end