%% exp2 - more parameters to tune
% same plant, 3 / 4 / 6 params (pid, pid + filter N, 2dof pid with b and c)
% abc only changes one gain per trial so it should slow down as D goes up
addpath(genpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src')));
P = project_paths(); outdir = P.results;
variants = {'pid','pidf','pid2'};
labels   = {'3-D ideal PID','4-D PID + derivative filter','6-D two-DOF PID'};
nSeeds = 25; maxFE = 3000;

rows = {}; gains = {};
for v = 1:numel(variants)
    S = make_setup('variant', variants{v});
    f = @(x) sim_cost(x, S);
    fprintf('exp2 %s (dim %d)...\n', variants{v}, S.dim);
    t0 = tic; R = compare_pair(f, S.lb, S.ub, maxFE, nSeeds); fprintf('  %.1f s\n', toc(t0));
    r = summarise_pair(R, sprintf('%s (D=%d)', labels{v}, S.dim));
    rows(end+1,:) = [{variants{v}, S.dim}, r(2:end)]; %#ok<SAGROW>
    [~,ia] = min(R.Ja); [~,ib] = min(R.Jb);
    gains(end+1,:) = {variants{v}, S.dim, mat2str(round(R.Xa(ia,:),4)), mat2str(round(R.Xb(ib,:),4))}; %#ok<SAGROW>
    save(fullfile(outdir, sprintf('exp2_raw_%s.mat', variants{v})), 'R', '-v7.3');
end
T = cell2table(rows, 'VariableNames', {'Variant','Dim', ...
    'ACOR_mean','ACOR_std','ACOR_med','ACOR_best','ACOR_nearbest_pct', ...
    'ABC_mean','ABC_std','ABC_med','ABC_best','ABC_nearbest_pct', ...
    'ABC_winrate_pct','p_ranksum'});
disp(T); writetable(T, fullfile(outdir,'exp2_dimension.csv'));
writetable(cell2table(gains,'VariableNames',{'Variant','Dim','ACOR_best_x','ABC_best_x'}), ...
    fullfile(outdir,'exp2_dimension_gains.csv'));
fprintf('Saved exp2_dimension.csv\n');
