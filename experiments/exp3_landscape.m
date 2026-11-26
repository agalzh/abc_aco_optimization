%% exp3 - what the cost surface looks like and how each one moves on it
% itae contour on a kp-ki slice (kd fixed at the abc value), every point each algo tried,
% distance from the running best (search radius) and the hessian at the best point
addpath(genpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src')));
P = project_paths(); outdir = P.results;
S = make_setup(); f = @(x) sim_cost(x, S);
xopt = [0.771568113818171 0.52731782730485 0.251968664267344];   % abc design from tune_pid

%% (a) contour grid
np = 140;
Kpv = linspace(0.30, 1.50, np);
Kiv = linspace(0.05, 1.20, np);
Z = zeros(np);
t0 = tic;
parfor a = 1:np
    row = zeros(1,np);
    for b = 1:np
        row(b) = sim_cost([Kpv(b) Kiv(a) xopt(3)], S);
    end
    Z(a,:) = row;
end
fprintf('contour %d x %d in %.1f s\n', np, np, toc(t0));
Z(Z > 1e5) = NaN;                         % unstable region
save(fullfile(outdir,'exp3_grid.mat'),'Kpv','Kiv','Z','xopt');

%% (b) search traces at equal budget
maxFE = 620;
ao.k=20; ao.nAnts=10; ao.q=0.5; ao.xi=0.85; ao.maxFE=maxFE;
bo.SN=20; bo.limit=15; bo.maxFE=maxFE;
rng(3); [~,~,tra] = acor_fe(f, S.lb, S.ub, ao);
rng(3); [~,~,trb] = abc_fe (f, S.lb, S.ub, bo);
save(fullfile(outdir,'exp3_traces.mat'),'tra','trb','maxFE');

%% (c) search radius, distance from the running best
prof = @(tr) arrayfun(@(i) norm(tr.X(i,:) - tr.X(find(tr.J(1:i)==min(tr.J(1:i)),1),:)), (1:tr.nfe)');
da = prof(tra); db = prof(trb);
w = 20;                                   % moving average window
sm = @(v) movmean(v, w);
P = table((1:maxFE)', sm(da), sm(db), 'VariableNames', {'FE','ACOR_dist','ABC_dist'});
writetable(P, fullfile(outdir,'exp3_exploitation.csv'));
q = round(maxFE*[0.25 0.5 0.75 1.0]);
fprintf('\nmean distance from running best (search radius):\n');
for i=1:numel(q)
    lo = max(1,q(i)-99);
    fprintf('  FE %3d-%3d : ACOR %.4f   ABC %.4f\n', lo, q(i), mean(da(lo:q(i))), mean(db(lo:q(i))));
end

%% (d) hessian at the best point
h = 1e-3; n = 3; H = zeros(n);
J0 = f(xopt);
for i=1:n
    for j=1:n
        ei=zeros(1,n); ei(i)=h; ej=zeros(1,n); ej(j)=h;
        H(i,j) = (f(xopt+ei+ej) - f(xopt+ei-ej) - f(xopt-ei+ej) + f(xopt-ei-ej))/(4*h^2);
    end
end
H = (H+H')/2;
[V,D] = eig(H); d = diag(D);
[d, is] = sort(d,'descend'); V = V(:,is);
cond2 = d(1)/d(end);
% tilt = angle between each axis of the valley and the nearest gain axis
tilt = zeros(n,1);
for i=1:n, tilt(i) = acosd(max(abs(V(:,i)))); end
fprintf('\nITAE Hessian at the ABC optimum (J0 = %.6f):\n', J0);
fprintf('  eigenvalues      %.4g  %.4g  %.4g\n', d);
fprintf('  condition number %.1f\n', cond2);
fprintf('  axis tilt (deg)  %.1f  %.1f  %.1f\n', tilt);
C = table(d, tilt, 'VariableNames', {'Eigenvalue','TiltDeg'});
C.Properties.UserData = cond2;
writetable(C, fullfile(outdir,'exp3_curvature.csv'));
writetable(table(cond2, J0, 'VariableNames',{'ConditionNumber','ITAE_at_opt'}), ...
    fullfile(outdir,'exp3_curvature_meta.csv'));
fprintf('Saved exp3_grid.mat, exp3_traces.mat, exp3_exploitation.csv, exp3_curvature.csv\n');
