%% exp5 - transport delay in the loop (pade, 2nd order)
% only checks if the ranking changes, the surface itself isnt measured here
addpath(genpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src')));
P = project_paths(); outdir = P.results;
taus = [0 0.05 0.10 0.15 0.20];
nSeeds = 25; maxFE = 2400;

rows = {};
for i = 1:numel(taus)
    S = make_setup('tau', taus(i));
    f = @(x) sim_cost(x, S);
    fprintf('exp5 tau=%.2f s ...\n', taus(i));
    t0 = tic; R = compare_pair(f, S.lb, S.ub, maxFE, nSeeds); fprintf('  %.1f s\n', toc(t0));
    r = summarise_pair(R, sprintf('%.2f', taus(i)));
    % failed = ended on the unstable penalty
    fa = 100*mean(R.Ja > 1e5); fb = 100*mean(R.Jb > 1e5);
    rows(end+1,:) = [{taus(i)}, r(2:end), {fa, fb}]; %#ok<SAGROW>
    save(fullfile(outdir, sprintf('exp5_raw_tau%03d.mat', round(100*taus(i)))), 'R', '-v7.3');
end
T = cell2table(rows, 'VariableNames', {'Tau_s', ...
    'ACOR_mean','ACOR_std','ACOR_med','ACOR_best','ACOR_nearbest_pct', ...
    'ABC_mean','ABC_std','ABC_med','ABC_best','ABC_nearbest_pct', ...
    'ABC_winrate_pct','p_ranksum','ACOR_fail_pct','ABC_fail_pct'});
disp(T); writetable(T, fullfile(outdir,'exp5_delay.csv'));
fprintf('Saved exp5_delay.csv\n');
