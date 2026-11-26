%% runs everything
% tune_pid has to go first, sensitivity and robustness read its csv
% the 6 experiments take long (25-30 seeds each), set RUN_LONG = true if you want them
RUN_LONG = false;

root = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(root, 'src')));
addpath(fullfile(root, 'experiments'), fullfile(root, 'simulink'), fullfile(root, 'tests'));

quick = {'tune_pid', 'plant_facts', 'sensitivity_analysis', 'bounds_study', ...
         'robustness_test', 'build_avr_simulink'};
long  = {'exp1_budget', 'exp3_landscape', 'exp2_dimension', 'exp4_objective', ...
         'exp5_delay', 'exp6_noise'};
final = {'key_facts', 'make_figures'};

todo = quick;
if RUN_LONG, todo = [todo, long]; end
todo = [todo, final];

for i = 1:numel(todo)
    fprintf('\n> %s\n', todo{i});
    t0 = tic;
    runscript(todo{i});
    fprintf('  %s took %.0f s\n', todo{i}, toc(t0));
end
fprintf('\ndone, check results/\n');
