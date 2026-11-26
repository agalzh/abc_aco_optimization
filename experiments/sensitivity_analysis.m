%% change one gain at a time (0.5x to 1.5x), other two fixed
% saves overshoot, settling time and itae for each
clear; clc; close all;
addpath(genpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src')));
P = project_paths(); outdir = P.results;

cfg = avr_config();
G  = avr_plant();
Gs = avr_sensor();
s  = tf('s');
costfun = @(x) pid_itae_cost(x, G, Gs, cfg.Tsim);
mkCL    = @(x) feedback((x(1) + x(2)/s + x(3)*s) * G, Gs);

%% operating point = lowest itae design from results_summary.csv
csv = fullfile(outdir, 'results_summary.csv');
if isfile(csv)
    Tr = readtable(csv, 'ReadRowNames', true);
    [~, bi] = min(Tr.ITAEs);
    xopt = [Tr.Kps(bi), Tr.Kis(bi), Tr.Kds(bi)];
    opname = Tr.Properties.RowNames{bi};
else
    warning('results_summary.csv not found; run tune_pid.m first.');
    xopt = [0.6394 0.4446 0.2077]; opname = 'fallback';
end
fprintf('Operating point: %s  Kp=%.4f Ki=%.4f Kd=%.4f\n\n', opname, xopt);

gainNames = {'Kp','Ki','Kd'};
factors   = 0.5:0.1:1.5;           % multipliers applied to one gain
showFac   = [0.6 0.8 1.0 1.2 1.4]; % step responses drawn for these
t = 0:0.001:cfg.Tsim;

rows = {};
for g = 1:3
    nF = numel(factors);
    OS = zeros(nF,1); ST = zeros(nF,1); JJ = zeros(nF,1); GV = zeros(nF,1);
    for i = 1:nF
        x = xopt; x(g) = xopt(g)*factors(i);
        GV(i) = x(g);
        CL = mkCL(x);
        info = stepinfo(CL, 'SettlingTimeThreshold', 0.02);
        OS(i) = info.Overshoot;
        ST(i) = info.SettlingTime;
        JJ(i) = costfun(x);
    end

    figure('Position',[100 100 1000 420]);
    % left: step responses
    subplot(1,2,1); hold on;
    for f = showFac
        x = xopt; x(g) = xopt(g)*f;
        y = step(mkCL(x), t);
        plot(t, y, 'LineWidth', 1.3, 'DisplayName', sprintf('%.1f\\times', f));
    end
    yline(1,'--k','HandleVisibility','off');
    xlabel('Time (s)'); ylabel('V_t (p.u.)');
    title(sprintf('Step response as %s varies', gainNames{g}));
    legend('Location','southeast'); grid on; xlim([0 cfg.Tsim]);

    % right: overshoot and itae vs the gain
    subplot(1,2,2);
    yyaxis left;  plot(GV, OS, '-o','LineWidth',1.4); ylabel('Overshoot (%)');
    yyaxis right; plot(GV, JJ, '-s','LineWidth',1.4); ylabel('ITAE');
    xline(xopt(g),':','optimal','HandleVisibility','off');
    xlabel(sprintf('%s value', gainNames{g}));
    title(sprintf('Overshoot & ITAE vs %s', gainNames{g})); grid on;

    saveas(gcf, fullfile(P.figures, sprintf('sensitivity_%s.png', gainNames{g})));

    for i = 1:nF
        rows(end+1,:) = {gainNames{g}, factors(i), GV(i), OS(i), ST(i), JJ(i)}; %#ok<SAGROW>
    end
    fprintf('%s swept %.3f .. %.3f : overshoot %.1f%%..%.1f%%, ITAE %.4f..%.4f\n', ...
        gainNames{g}, GV(1), GV(end), min(OS), max(OS), min(JJ), max(JJ));
end

S = cell2table(rows, 'VariableNames', ...
    {'Gain','Factor','Value','Overshoot_pct','SettlingTime_s','ITAE'});
writetable(S, fullfile(outdir, 'sensitivity_summary.csv'));
fprintf('\nSaved: sensitivity_Kp.png, sensitivity_Ki.png, sensitivity_Kd.png, sensitivity_summary.csv\n');
