%% does a bigger search box help?
% runs both with ub = 1.5, 2, 3, 5, 10 and saves the best itae + biggest gain found
clear; clc; close all;
addpath(genpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src')));
P = project_paths(); outdir = P.results;

cfg = avr_config();
G = avr_plant(); Gs = avr_sensor();
costfun = @(x) pid_itae_cost(x, G, Gs, cfg.Tsim);

ubs = [1.5 2 3 5 10];            % uniform upper bound tested on all 3 gains
acorOpts.k=20; acorOpts.nAnts=10; acorOpts.maxIter=50; acorOpts.q=0.5; acorOpts.xi=0.85;
abcOpts.SN=20;  abcOpts.maxIter=50; abcOpts.limit=15;

rows = {};
J_aco = zeros(numel(ubs),1); J_abc = zeros(numel(ubs),1);
maxg_aco = zeros(numel(ubs),1); maxg_abc = zeros(numel(ubs),1);
for i = 1:numel(ubs)
    lb = [0 0 0]; ub = ubs(i)*[1 1 1];
    rng(1); [xa, Ja] = acor_pid(costfun, lb, ub, acorOpts);
    rng(1); [xb, Jb] = abc_pid(costfun, lb, ub, abcOpts);
    J_aco(i)=Ja; J_abc(i)=Jb; maxg_aco(i)=max(xa); maxg_abc(i)=max(xb);
    rows(end+1,:) = {ubs(i),'ACOR',xa(1),xa(2),xa(3),Ja,max(xa)}; %#ok<SAGROW>
    rows(end+1,:) = {ubs(i),'ABC', xb(1),xb(2),xb(3),Jb,max(xb)}; %#ok<SAGROW>
    fprintf('ub=%4.1f | ACOR ITAE=%.4f (maxgain %.3f) | ABC ITAE=%.4f (maxgain %.3f)\n', ...
        ubs(i), Ja, max(xa), Jb, max(xb));
end

T = cell2table(rows, 'VariableNames', {'UpperBound','Method','Kp','Ki','Kd','ITAE','MaxGain'});
writetable(T, fullfile(outdir,'bounds_study_summary.csv'));

figure('Position',[100 100 1000 420]);
subplot(1,2,1);
plot(ubs, J_aco,'-o','LineWidth',1.5); hold on; plot(ubs, J_abc,'-s','LineWidth',1.5);
xlabel('Search upper bound (all gains)'); ylabel('Best ITAE found');
title('Best ITAE vs search-box size'); legend('ACOR','ABC'); grid on;
subplot(1,2,2);
plot(ubs, maxg_aco,'-o','LineWidth',1.5); hold on; plot(ubs, maxg_abc,'-s','LineWidth',1.5);
plot(ubs, ubs,'--k','DisplayName','if optimum hit the bound');
xlabel('Search upper bound'); ylabel('Largest gain in the solution');
title('Do the optima push against the bound?'); legend('ACOR','ABC','bound line'); grid on;
saveas(gcf, fullfile(P.figures,'bounds_study.png'));
fprintf('\nSaved: bounds_study_summary.csv, bounds_study.png\n');
