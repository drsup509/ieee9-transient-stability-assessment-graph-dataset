function [residual, residualRMS, Haligned] = compute_swing_residual(dyn, cfg) %#ok<INUSD>
% COMPUTE_SWING_RESIDUAL  Classical swing-equation residual on the actual
% (detailed-model) trajectory, per machine and per time step.
%
%   PHYSICS (undamped classical model, D = 0 in this dataset)
%   --------------------------------------------------------
%   Per-unit form with rotor speed omega in pu (1.0 = synchronism) and
%   time in seconds:
%
%         2 H_i  d(omega_i)/dt  =  P_m,i - P_e,i - D_i (omega_i - 1)
%
%   so the residual (what the classical prior fails to explain on the
%   DETAILED EMT trajectory) is
%
%         r_i(t) = 2 H_i d(omega_i)/dt - ( P_m,i - P_e,i - D_i (omega_i-1) )
%
%   With D_i = 0 this reduces to  r_i = 2 H_i domega/dt - (P_m - P_e).
%
%   UNITS / BASES (verified against the code, not assumed)
%   -----------------------------------------------------
%   - omega : rotor speed [pu], 1.0 = synchronism (compute_dynamic_indices
%             uses |omega - 1|).
%   - P_e   : dyn.Pe = pu_torque .* pu_velocity  -> air-gap power [pu],
%             MACHINE base.
%   - P_m   : dyn.Pm = Governor .../Mechanical_Power/Pm_pu [pu], MACHINE base.
%   - H     : generatorData().H [s] on the MACHINE base (MVA=[247.5,192,128]).
%   H, P_e, P_m are therefore all on the machine base -> base-consistent,
%   no cross-base conversion needed, and r_i is in [pu] on the machine base.
%
%   NOTE (honest limitation): the IEEE9BusSystem machines are DETAILED
%   (AVR/exciter, governor, PSS, subtransient), so this classical residual
%   is generally NON-ZERO by construction -- it quantifies the mismatch
%   between the classical physics prior (H, D, using constants from
%   generatorData) and the detailed ground-truth trajectory. That is the
%   intended signal for a physics-informed (PINN/PIGNN) auxiliary loss.
%
%   INPUT
%     dyn : struct from import_dynamic_results with fields
%           .time [Nt x 1] s, .omega [Nt x nGen] pu, .Pe [Nt x nGen] pu,
%           .Pm [Nt x nGen] pu, .genNames [1 x nGen].
%     cfg : global config (unused; kept for signature symmetry).
%
%   OUTPUT
%     residual    : [Nt x nGen] r_i(t) [pu], aligned to dyn.genNames columns.
%     residualRMS : [1 x nGen]  sqrt(mean_t r_i^2) per machine.
%     Haligned    : [1 x nGen]  inertia constants aligned to genNames [s].
%
%   Returns empty on missing inputs (additive field: never breaks labels).

residual = []; residualRMS = zeros(1,0); Haligned = zeros(1,0);

if ~isstruct(dyn) || ~isfield(dyn,'omega') || ~isfield(dyn,'Pe') ...
        || ~isfield(dyn,'Pm') || ~isfield(dyn,'time') || ~isfield(dyn,'genNames')
    return;
end
if isempty(dyn.omega) || isempty(dyn.Pe) || isempty(dyn.Pm)
    return;
end

t     = dyn.time(:);
omega = dyn.omega;    % Nt x nGen [pu]
Pe    = dyn.Pe;       % Nt x nGen [pu]
Pm    = dyn.Pm;       % Nt x nGen [pu]
nGen  = size(omega, 2);

% Dimensions must agree; otherwise abstain (additive field is optional).
if size(Pe,2) ~= nGen || size(Pm,2) ~= nGen ...
        || size(Pe,1) ~= numel(t) || size(Pm,1) ~= numel(t) ...
        || size(omega,1) ~= numel(t)
    return;
end

% Inertia (and damping) aligned to the trajectory column order.
[Haligned, Daligned] = i_align_inertia(dyn.genNames);
if isempty(Haligned)
    return;
end

% d(omega)/dt : centered difference on the (possibly non-uniform) time grid.
domega_dt = zeros(size(omega));
for g = 1:nGen
    domega_dt(:,g) = gradient(omega(:,g), t);
end

Hrow = Haligned(:).';   % 1 x nGen
Drow = Daligned(:).';   % 1 x nGen (all zeros in this dataset)

% r_i = 2 H_i domega/dt - (Pm - Pe - D_i (omega-1))
residual = 2 .* Hrow .* domega_dt - (Pm - Pe - Drow .* (omega - 1));

residualRMS = sqrt(mean(residual.^2, 1));   % 1 x nGen

end


% ----------------------------------------------------------------------
function [H, D] = i_align_inertia(genNames)
% Align generatorData H/D to the trajectory column order using the "Bus<n>"
% token in each generator name (e.g. "Gen1Bus1_Swing" -> bus 1). Falls back
% to identity order (with a warning) if a name cannot be parsed.
gen = generatorData();
names = string(genNames(:)).';
nGen  = numel(names);
H = nan(1, nGen); D = nan(1, nGen);

ok = true;
for k = 1:nGen
    tok = regexp(char(names(k)), 'Bus(\d+)', 'tokens', 'once');
    if isempty(tok); ok = false; break; end
    b = str2double(tok{1});
    idx = find(gen.bus(:).' == b, 1);
    if isempty(idx); ok = false; break; end
    H(k) = gen.H(idx);
    D(k) = gen.D(idx);
end

if ~ok
    if numel(gen.H) == nGen
        warning('tsa:swingResidual:alignFallback', ...
            ['Could not parse "Bus<n>" from all genNames; falling back to ' ...
             'identity order for H/D alignment.']);
        H = gen.H(1:nGen).';
        D = gen.D(1:nGen).';
    else
        warning('tsa:swingResidual:alignFailed', ...
            'H/D alignment failed and count mismatch; swing residual skipped.');
        H = zeros(1,0); D = zeros(1,0);
    end
end
end
