function validation = validate_powerflow(network, results, mpc, cfg)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% VALIDATE_POWERFLOW
%
% OBJECTIF
% --------
% Analyser les résultats du Power Flow et classifier le scénario :
% - ACCEPTED
% - BORDERLINE
% - REJECTED
%
% Aucune modification du réseau n'est effectuée ici.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf(' -> Validating Power Flow results...\n');

%% INITIALISATION

define_constants; % matpower reading

validation.status = "";
validation.reason = "";
validation.converged = results.success;

validation.minVoltage = NaN;
validation.maxVoltage = NaN;

validation.lineLoadingMax = NaN;

validation.reactiveLimitViolation.global = false;
validation.reactiveLimitViolation.vector = [];

validation.powerBalanceError = NaN;

%% 1. NON-CONVERGENCE CHECK


if cfg.powerflow.validation.rejectNonConvergence && ~results.success
    validation.status = "REJECTED";
    validation.reason = "PowerFlowDidNotConverge";
    return;
end


%% 2. VOLTAGE ANALYSIS

% V = results.bus(:,8); % voltage magnitude

fprintf("\n********===========  VOLTAGE ANALYSIS ********===========\n")

gen_buses = results.gen(:, GEN_BUS);   % numéros des bus générateurs

mask = ~ismember(results.bus(:, BUS_I), gen_buses);

V = results.bus(mask, VM); % tension des bus sans générateurs (sans V consigne)

min(V)
max(V)
fprintf("\n******==========  FIN VOLTAGE ANALYSIS ********==========\n")


validation.minVoltage = min(V);
validation.maxVoltage = max(V);

vMinAcc = cfg.powerflow.validation.accepted.minVoltage;
vMaxAcc = cfg.powerflow.validation.accepted.maxVoltage;

vMinBor = cfg.powerflow.validation.borderline.minVoltage;
vMaxBor = cfg.powerflow.validation.borderline.maxVoltage;


%% 3. LINE LOADING

% lineLoading = compute_line_loading(results);
% validation.lineLoadingMax = lineLoading.maximum;

validation.lineLoadingMax = network.indices.lineLoading.maxLineLoading;


loadingLimit = cfg.powerflow.validation.lineLoadingThreshold;

%% 4. REACTIVE POWER LIMITS

Qg = results.gen(:,3);
Qmax = results.gen(:,4);
Qmin = results.gen(:,5);

violationVec = (Qg < Qmin) | (Qg > Qmax);

validation.reactiveLimitViolation.vector = violationVec;
validation.reactiveLimitViolation.global = any(violationVec);


%% 5. POWER BALANCE ERROR

Pg = sum(results.gen(:,2));
Pd = sum(results.bus(:,3));

validation.powerBalanceError = abs(Pg - Pd);


%% 6. CLASSIFICATION LOGIC

isVoltageAccepted = (validation.minVoltage >= vMinAcc) && ...
                    (validation.maxVoltage <= vMaxAcc);

% isVoltageBorderline = (validation.minVoltage >= vMinBor) && ...
%                       (validation.maxVoltage <= vMaxBor);

isVoltageBorderline = (validation.minVoltage >= vMinBor) && ...
                      (validation.minVoltage < vMinAcc) && ... 
                      (validation.maxVoltage > vMaxAcc) && ... 
                      (validation.maxVoltage <= vMaxBor);

isOverloaded = validation.lineLoadingMax > loadingLimit;

hasQViolation = validation.reactiveLimitViolation.global; %indication si 
% generateur 
% respecte ou non tension consigne; donc validation borderline peut se 
% faire uniquemnet sur les autres barres

%% DIAGNOSTICS

fprintf('\n----- Validation diagnostics -----\n');
fprintf('Success : %d\n', results.success);
fprintf('Vmin : %.4f\n', validation.minVoltage);
fprintf('Vmax : %.4f\n', validation.maxVoltage);
fprintf('Max line loading : %.2f\n', validation.lineLoadingMax);
fprintf('Q violation : %d\n', hasQViolation);
fprintf('Line overloaded : %d\n', isOverloaded);
fprintf('Power imbalance (Losses I^2*Z) : %.6f\n', validation.powerBalanceError);
fprintf('----------------------------------\n');


%% 7. DECISION TREE

if ~results.success
    validation.status = "REJECTED";
    validation.reason = "NonConvergence";

elseif validation.minVoltage < cfg.powerflow.validation.rejected.minVoltage || validation.maxVoltage > cfg.powerflow.validation.rejected.maxVoltage
    validation.status = "REJECTED";
    validation.reason = "ExtremeVoltageViolation";

elseif hasQViolation || isOverloaded
    validation.status = "BORDERLINE";
    validation.reason = "OperationalStress";

elseif isVoltageBorderline
    validation.status = "BORDERLINE";
    validation.reason = "VoltageStress";

elseif isVoltageAccepted
    validation.status = "ACCEPTED";
    validation.reason = "NormalOperation";

else
    validation.status = "BORDERLINE";
    validation.reason = "DefaultBorderlineCase";
end

%% OUTPUT SUMMARY

fprintf(' Status : %s\n', validation.status);
fprintf(' Reason : %s\n', validation.reason);

end
