%% robustness, gains kept fixed
% A: kg and tg changed by +-20%
% B: -10% load step at t = 5 s, how long till its back within 1%
clear; clc; close all;
addpath(genpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src')));
P = project_paths(); outdir = P.results;
s = tf('s');
cfg = avr_config(); p = cfg.plant; Tsim = cfg.Tsim;
Gs = (p.Ks)/(1+s*p.Ts);

% plant for a given kg, tg (amp and exciter fixed)
Gp = @(Kg,Tg) (p.Ka/(1+s*p.Ta))*(p.Ke/(1+s*p.Te))*(Kg/(1+s*Tg));
Cof = @(x) x(1) + x(2)/s + x(3)*s;

% gains from tune_pid
Tr = readtable(fullfile(outdir,'results_summary.csv'), 'ReadRowNames', true);
names = Tr.Properties.RowNames;
gains = [Tr.Kps Tr.Kis Tr.Kds];

% A: +-20% drift in kg, tg
scen = { 'Nominal',   p.Kg,      p.Tg;
         'Tg +20%',   p.Kg,      1.2*p.Tg;
         'Tg -20%',   p.Kg,      0.8*p.Tg;
         'Kg +20%',   1.2*p.Kg,  p.Tg;
         'Kg -20%',   0.8*p.Kg,  p.Tg };
t = 0:0.001:Tsim;
rows = {};
for c = 1:numel(names)
    C = Cof(gains(c,:));
    for k = 1:size(scen,1)
        CL = feedback(C*Gp(scen{k,2},scen{k,3}), Gs);
        pls = pole(CL); stable = all(real(pls) < 0);
        if stable
            y = step(CL, t); e = 1-y;
            info = stepinfo(CL,'SettlingTimeThreshold',0.02);
            J = trapz(t, t(:).*abs(e(:)));
            rows(end+1,:) = {names{c}, scen{k,1}, info.Overshoot, info.SettlingTime, J, 'yes'}; %#ok<SAGROW>
        else
            rows(end+1,:) = {names{c}, scen{k,1}, NaN, NaN, NaN, 'NO'}; %#ok<SAGROW>
        end
    end
end
A = cell2table(rows, 'VariableNames', {'Controller','Scenario','Overshoot_pct','Settling_s','ITAE','Stable'});
disp(A);
writetable(A, fullfile(outdir,'robustness_summary.csv'));

% drift plot for the best one
[~, bc] = min(Tr.ITAEs); Cb = Cof(gains(bc,:));
f1 = figure('Position',[100 100 950 430], 'Visible','off');
hold on;
for k = 1:size(scen,1)
    y = step(feedback(Cb*Gp(scen{k,2},scen{k,3}), Gs), t);
    plot(t, y, 'LineWidth', 1.4, 'DisplayName', scen{k,1});
end
yline(1,'--k','HandleVisibility','off');
xlabel('Time (s)'); ylabel('V_t (p.u.)');
title(sprintf('%s-tuned controller under \\pm20%% generator drift (no re-tuning)', names{bc}));
legend('Location','southeast'); grid on; xlim([0 Tsim]);
exportgraphics(f1, fullfile(P.figures,'robustness_drift.png'), 'Resolution', 120);

% B: load step
td = 5; ddist = -0.10;            % -10% load step at t = 5 s (voltage dip)
tt = 0:0.001:10;
ref = ones(size(tt));
d = ddist*(tt >= td);
f2 = figure('Position',[100 100 950 430], 'Visible','off'); hold on;
drec = {};
for c = 1:numel(names)
    C = Cof(gains(c,:));
    Gpnom = Gp(p.Kg,p.Tg);
    L = C*Gpnom*Gs;
    Tref = feedback(C*Gpnom, Gs);        % reference -> output
    Sd   = feedback(1, C*Gpnom*Gs);      % output-disturbance -> output = 1/(1+L)
    y = lsim(Tref, ref, tt) + lsim(Sd, d, tt);
    plot(tt, y, 'LineWidth', 1.4, 'DisplayName', names{c});
    y = y(:); tc = tt(:);
    dip = min(y(tc>=td));                     % lowest voltage after the disturbance
    % recovery = last time its outside 1% of 1.0
    bad = find(abs(y-1) >= 0.01 & tc >= td, 1, 'last');
    if isempty(bad),            rec = 0;
    elseif bad < numel(tc),     rec = tc(bad+1) - td;
    else,                       rec = NaN;     % never recovered within the window
    end
    drec(end+1,:) = {names{c}, dip, rec}; %#ok<SAGROW>
end
yline(1,'--k','HandleVisibility','off');
xline(td,':','load disturbance','HandleVisibility','off');
xlabel('Time (s)'); ylabel('V_t (p.u.)');
title('Load-disturbance rejection (-10% step at t = 5 s)');
legend('Location','southeast'); grid on; xlim([0 10]);
exportgraphics(f2, fullfile(P.figures,'robustness_disturbance.png'), 'Resolution', 120);

D = cell2table(drec, 'VariableNames', {'Controller','MinVoltage_afterStep','RecoveryTime_s'});
disp(D);
writetable(D, fullfile(outdir,'robustness_disturbance.csv'));
fprintf('\nSaved: robustness_summary.csv, robustness_drift.png, robustness_disturbance.png, robustness_disturbance.csv\n');
