%% exp4 - itae vs iae vs ise vs itse
% does the ranking hold if the objective changes, best design of each is checked on the step response too
addpath(genpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src')));
P = project_paths(); outdir = P.results;
objs = {'ITAE','IAE','ISE','ITSE'};
nSeeds = 25; maxFE = 2400;

rows = {}; drows = {};
Sref = make_setup();                      % for scoring every design on ITAE
for o = 1:numel(objs)
    S = make_setup('obj', objs{o});
    f = @(x) sim_cost(x, S);
    fprintf('exp4 %s...\n', objs{o});
    t0 = tic; R = compare_pair(f, S.lb, S.ub, maxFE, nSeeds); fprintf('  %.1f s\n', toc(t0));
    rows(end+1,:) = summarise_pair(R, objs{o}); %#ok<SAGROW>
    % best design for this objective, check its step response
    for m = 1:2
        if m==1, [~,i0]=min(R.Ja); x=R.Xa(i0,:); nm='ACOR'; else, [~,i0]=min(R.Jb); x=R.Xb(i0,:); nm='ABC'; end
        [~, y] = sim_cost(x, Sref);
        info = stepmetrics(y, Sref.t);
        drows(end+1,:) = {objs{o}, nm, x(1), x(2), x(3), sim_cost(x,Sref), ...
                          info.Overshoot, info.RiseTime, info.SettlingTime}; %#ok<SAGROW>
    end
end
T = cell2table(rows, 'VariableNames', {'Objective', ...
    'ACOR_mean','ACOR_std','ACOR_med','ACOR_best','ACOR_nearbest_pct', ...
    'ABC_mean','ABC_std','ABC_med','ABC_best','ABC_nearbest_pct', ...
    'ABC_winrate_pct','p_ranksum'});
disp(T); writetable(T, fullfile(outdir,'exp4_objective.csv'));
D = cell2table(drows, 'VariableNames', {'Objective','Method','Kp','Ki','Kd', ...
    'ITAE_of_design','Overshoot_pct','RiseTime_s','SettlingTime_s'});
disp(D); writetable(D, fullfile(outdir,'exp4_objective_designs.csv'));
fprintf('Saved exp4_objective.csv, exp4_objective_designs.csv\n');
