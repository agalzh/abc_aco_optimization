%% checks sim_cost gives the same itae as pid_itae_cost, and times both
clear; clc;
addpath(genpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src')));
cfg = avr_config(); G = avr_plant(); Gs = avr_sensor();
slow = @(x) pid_itae_cost(x, G, Gs, cfg.Tsim);
S = make_setup();
fast = @(x) sim_cost(x, S);

rng(7);
X = [0.729431719723353 1.11676763466966 0.119109521358925;   % ZN
     1.01145623318914  0.678511413703303 0.346873381978876;  % ACOR
     0.771568113818171 0.52731782730485  0.251968664267344;  % ABC
     cfg.lb + rand(12,3).*(cfg.ub-cfg.lb)];

err = zeros(size(X,1),1);
for i = 1:size(X,1)
    a = slow(X(i,:)); b = fast(X(i,:));
    err(i) = abs(a-b)/max(abs(a),eps);
    fprintf('%2d  slow %.10f   fast %.10f   rel.err %.2e\n', i, a, b, err(i));
end
fprintf('\nMAX RELATIVE ERROR  %.3e\n', max(err));

Xt = cfg.lb + rand(200,3).*(cfg.ub-cfg.lb);
tic; for i=1:200, slow(Xt(i,:)); end; ts=toc;
tic; for i=1:200, fast(Xt(i,:)); end; tf_=toc;
fprintf('slow %.2f ms/eval   fast %.2f ms/eval   speedup %.1fx\n', 1000*ts/200, 1000*tf_/200, ts/tf_);
