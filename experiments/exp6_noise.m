%% exp6 - noisy cost
% search runs on the noisy itae, the design it returns is scored on the clean one
addpath(genpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src')));
P = project_paths(); outdir = P.results;
levels = [0 0.01 0.03 0.10];
nSeeds = 25; maxFE = 2400;
Sc = make_setup();                        % clean scorer

rows = {};
for i = 1:numel(levels)
    S = make_setup('noise', levels(i));
    f = @(x) sim_cost(x, S);
    fprintf('exp6 noise=%.0f%% ...\n', 100*levels(i));
    t0 = tic; R = compare_pair(f, S.lb, S.ub, maxFE, nSeeds); fprintf('  %.1f s\n', toc(t0));
    Ca = zeros(nSeeds,1); Cb = zeros(nSeeds,1);
    for r = 1:nSeeds
        Ca(r) = sim_cost(R.Xa(r,:), Sc);
        Cb(r) = sim_cost(R.Xb(r,:), Sc);
    end
    r = summarise_pair(R, '', struct('a',Ca,'b',Cb));
    rows(end+1,:) = [{100*levels(i)}, r(2:end)]; %#ok<SAGROW>
end
T = cell2table(rows, 'VariableNames', {'Noise_pct', ...
    'ACOR_mean','ACOR_std','ACOR_med','ACOR_best','ACOR_nearbest_pct', ...
    'ABC_mean','ABC_std','ABC_med','ABC_best','ABC_nearbest_pct', ...
    'ABC_winrate_pct','p_ranksum'});
disp(T); writetable(T, fullfile(outdir,'exp6_noise.csv'));
fprintf('Saved exp6_noise.csv\n');
