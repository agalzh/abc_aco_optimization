%% exp1 - equal budget
% aco-r does 10 evals per iteration, abc does ~40... so comparing by iterations isnt fair
% this runs both for the same no. of evals (30 seeds) and saves the whole curve
addpath(genpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src')));
P = project_paths(); outdir = P.results;
S = make_setup(); f = @(x) sim_cost(x, S);

nSeeds = 30; maxFE = 2400;
fprintf('exp1: %d seeds, %d FE\n', nSeeds, maxFE);
t0 = tic; R = compare_pair(f, S.lb, S.ub, maxFE, nSeeds); fprintf('elapsed %.1f s\n', toc(t0));

% best so far vs evals (mean and std over seeds)
fe = (1:maxFE)';
C = table(fe, mean(R.Ba,1)', std(R.Ba,0,1)', median(R.Ba,1)', ...
              mean(R.Bb,1)', std(R.Bb,0,1)', median(R.Bb,1)', ...
    'VariableNames', {'FE','ACOR_mean','ACOR_std','ACOR_med','ABC_mean','ABC_std','ABC_med'});
writetable(C, fullfile(outdir,'exp1_convergence.csv'));

% summary at a few budgets
budgets = [100 200 400 620 1000 1500 2000 2400];
rows = {};
for B = budgets
    a = R.Ba(:,B); b = R.Bb(:,B);
    try, p = ranksum(a,b); catch, p = NaN; end
    rows(end+1,:) = {B, mean(a), std(a), median(a), mean(b), std(b), median(b), ...
                     100*mean(b<a), p, mean(a)-mean(b)}; %#ok<SAGROW>
end
T = cell2table(rows, 'VariableNames', {'FE','ACOR_mean','ACOR_std','ACOR_med', ...
    'ABC_mean','ABC_std','ABC_med','ABC_winrate_pct','p_ranksum','mean_gap'});
disp(T);
writetable(T, fullfile(outdir,'exp1_budget_summary.csv'));

% time per eval
fprintf('mean wall-clock: ACOR %.2f s/run, ABC %.2f s/run (%d FE each)\n', mean(R.Ta), mean(R.Tb), maxFE);
W = table({'ACOR';'ABC'}, [mean(R.Ta);mean(R.Tb)], [1000*mean(R.Ta)/maxFE; 1000*mean(R.Tb)/maxFE], ...
    'VariableNames',{'Method','Sec_per_run','ms_per_FE'});
writetable(W, fullfile(outdir,'exp1_walltime.csv'));

% check the old designs give the same itae with the fast cost
G = avr_plant(); Gs = avr_sensor(); cfg = avr_config();
ref = [0.729431719723353 1.11676763466966 0.119109521358925;
       1.01145623318914  0.678511413703303 0.346873381978876;
       0.771568113818171 0.52731782730485  0.251968664267344];
nm = {'Ziegler-Nichols','ACOR (60 it.)','ABC (60 it.)'};
fprintf('\nReference design points re-evaluated with the fast polynomial core:\n');
for i=1:3
    fprintf('  %-18s toolbox %.10f   fast %.10f\n', nm{i}, ...
        pid_itae_cost(ref(i,:),G,Gs,cfg.Tsim), sim_cost(ref(i,:),S));
end
save(fullfile(outdir,'exp1_raw.mat'),'R','-v7.3');
fprintf('\nSaved exp1_convergence.csv, exp1_budget_summary.csv, exp1_walltime.csv, exp1_raw.mat\n');
