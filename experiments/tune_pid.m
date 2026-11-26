%% zn baseline, then tune with aco-r and abc (60 iterations, seed 1)
% 60 iterations isnt the same work for both (620 evals vs ~2420)
% so this only gives the designs, the fair comparison is exp1_budget.m
clear; clc; close all;
addpath(genpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src')));
P = project_paths();

cfg  = avr_config();
Tsim = cfg.Tsim;
G  = avr_plant();
Gs = avr_sensor();
costfun = @(x) pid_itae_cost(x, G, Gs, Tsim);

%% zn
[Kp_zn, Ki_zn, Kd_zn, Ku, Pu] = compute_zn(G, Gs);
fprintf('--- Ziegler-Nichols baseline ---\n');
fprintf('Ku = %.4f, Pu = %.4f s\n', Ku, Pu);
fprintf('Kp=%.4f  Ki=%.4f  Kd=%.4f\n\n', Kp_zn, Ki_zn, Kd_zn);

%% bounds
lb = cfg.lb;
ub = cfg.ub;
fprintf('Search bounds: Kp in [%.2f,%.3f], Ki in [%.2f,%.3f], Kd in [%.2f,%.3f]\n', lb(1),ub(1), lb(2),ub(2), lb(3),ub(3));
fprintf('Justification: %s\n\n', cfg.bounds_justification);

%% aco-r
rng(1);
acorOpts.k = 20; acorOpts.nAnts = 10; acorOpts.maxIter = 60;
acorOpts.q = 0.5; acorOpts.xi = 0.85;
tic;
[x_aco, J_aco] = acor_pid(costfun, lb, ub, acorOpts);
t_aco = toc;
fprintf('--- ACO-R result (%.2fs) ---\nKp=%.4f Ki=%.4f Kd=%.4f  ITAE=%.5f\n\n', t_aco, x_aco(1), x_aco(2), x_aco(3), J_aco);

%% abc
rng(1);
abcOpts.SN = 20; abcOpts.maxIter = 60; abcOpts.limit = 15;
tic;
[x_abc, J_abc] = abc_pid(costfun, lb, ub, abcOpts);
t_abc = toc;
fprintf('--- ABC result (%.2fs) ---\nKp=%.4f Ki=%.4f Kd=%.4f  ITAE=%.5f\n\n', t_abc, x_abc(1), x_abc(2), x_abc(3), J_abc);

%% compare
s = tf('s');
mk = @(x) feedback((x(1) + x(2)/s + x(3)*s) * G, Gs);
CL_zn  = mk([Kp_zn Ki_zn Kd_zn]);
CL_aco = mk(x_aco);
CL_abc = mk(x_abc);

t = 0:0.001:Tsim;
y_zn  = step(CL_zn,  t);
y_aco = step(CL_aco, t);
y_abc = step(CL_abc, t);

info_zn  = stepinfo(CL_zn,  'SettlingTimeThreshold', 0.02);
info_aco = stepinfo(CL_aco, 'SettlingTimeThreshold', 0.02);
info_abc = stepinfo(CL_abc, 'SettlingTimeThreshold', 0.02);

names = {'Ziegler-Nichols', 'ACOR', 'ABC'};
Kps  = [Kp_zn x_aco(1) x_abc(1)]';
Kis  = [Ki_zn x_aco(2) x_abc(2)]';
Kds  = [Kd_zn x_aco(3) x_abc(3)]';
ITAEs = [costfun([Kp_zn Ki_zn Kd_zn]); J_aco; J_abc];
RiseT = [info_zn.RiseTime; info_aco.RiseTime; info_abc.RiseTime];
Overshoot = [info_zn.Overshoot; info_aco.Overshoot; info_abc.Overshoot];
SettleT = [info_zn.SettlingTime; info_aco.SettlingTime; info_abc.SettlingTime];
SSE = [abs(1-y_zn(end)); abs(1-y_aco(end)); abs(1-y_abc(end))];

T = table(Kps, Kis, Kds, ITAEs, RiseT, Overshoot, SettleT, SSE, 'RowNames', names);
disp(T);
writetable(T, fullfile(P.results, 'results_summary.csv'), 'WriteRowNames', true);

%% plot
figure('Position', [100 100 900 500]);
plot(t, y_zn, 'LineWidth', 1.5); hold on;
plot(t, y_aco, 'LineWidth', 1.5);
plot(t, y_abc, 'LineWidth', 1.5);
yline(1, '--k');
legend('Ziegler-Nichols', 'ACOR', 'ABC', 'Setpoint', 'Location', 'southeast');
xlabel('Time (s)'); ylabel('Terminal voltage V_t (p.u.)');
title('AVR step response: ZN vs ACOR vs ABC tuned PID');
grid on;
saveas(gcf, fullfile(P.figures, 'step_response_comparison.png'));

fprintf('\nSaved: results/results_summary.csv, results/figures/step_response_comparison.png\n');
