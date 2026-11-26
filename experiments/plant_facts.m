%% plant equation written out
% closed loop polynomial, the loop with no pid (C = 1), and the poles with the abc gains
addpath(genpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src')));
P = project_paths(); outdir = P.results;
cfg = avr_config();
P = avr_poly(cfg);

% s * dg * dh, the s is from the integrator
base = conv([1 0], conv(P.dg, P.dh));          % 5th order, constant term 0
k = P.ng * P.nh;                                  % loop gain multiplying (Kd s^2 + Kp s + Ki)

% no pid, C = 1
[nU, dU] = cl_poly(P, 1, 1, 1);
TU = tf(nU, dU);
t = 0:0.001:60;
yU = step(TU, t);
yss = dcgain(TU);
pU = roots(dU);
[~, i] = max(real(pU(abs(imag(pU)) > 1e-6)));
pc = pU(abs(imag(pU)) > 1e-6); pd = pc(i);
infoU = stepinfo(yU, t, yss, 'SettlingTimeThreshold', 0.02);

% with the abc gains
x = [0.771568113818171 0.52731782730485 0.251968664267344];
dABC = base + [0 0 0 k*x(3) k*x(1) k*x(2)];   % s^2: Kd, s^1: Kp, s^0: Ki
pA = roots(dABC);

K = {}; V = {};
put = @(key, val) deal(key, val);
K{end+1} = 'dg3'; V{end+1} = sprintf('%.4g', P.dg(1));
K{end+1} = 'dg2'; V{end+1} = sprintf('%.4g', P.dg(2));
K{end+1} = 'dg1'; V{end+1} = sprintf('%.4g', P.dg(3));
K{end+1} = 'loopk'; V{end+1} = sprintf('%.4g', k);
for j = 1:5
    K{end+1} = sprintf('c%d', 6 - j); V{end+1} = sprintf('%.4g', base(j)); %#ok<SAGROW>
end
K{end+1} = 'unc_final'; V{end+1} = sprintf('%.3f', yss);
K{end+1} = 'unc_sse_pct'; V{end+1} = sprintf('%.1f', 100*(1 - yss));
K{end+1} = 'unc_peak'; V{end+1} = sprintf('%.2f', max(yU));
K{end+1} = 'unc_os_pct'; V{end+1} = sprintf('%.0f', infoU.Overshoot);
K{end+1} = 'unc_settle'; V{end+1} = sprintf('%.0f', infoU.SettlingTime);
K{end+1} = 'unc_pole_re'; V{end+1} = sprintf('%.2f', real(pd));
K{end+1} = 'unc_pole_im'; V{end+1} = sprintf('%.2f', abs(imag(pd)));
K{end+1} = 'unc_zeta'; V{end+1} = sprintf('%.3f', -real(pd)/abs(pd));
pA = sort(pA, 'descend', 'ComparisonMethod', 'real');
cp = arrayfun(@local_fmt, pA.', 'UniformOutput', false);
cp = cp(~cellfun(@isempty, cp));
K{end+1} = 'abc_poles'; V{end+1} = strjoin(cp, ';  ');
K{end+1} = 'abc_c2'; V{end+1} = sprintf('%.3f', dABC(4));
K{end+1} = 'abc_c1'; V{end+1} = sprintf('%.3f', dABC(5));
K{end+1} = 'abc_c0'; V{end+1} = sprintf('%.3f', dABC(6));

T = table(K(:), V(:), 'VariableNames', {'Key', 'Value'});
writetable(T, fullfile(outdir, 'plant_facts.csv'));
disp(T);

function s = local_fmt(p)
if abs(imag(p)) < 1e-6
    s = sprintf('%.2f', real(p));
elseif imag(p) > 0
    s = sprintf('%.2f ± j%.2f', real(p), imag(p));
else
    s = '';
end
end
