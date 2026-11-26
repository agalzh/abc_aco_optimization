%% quick check that acor_fe / abc_fe stop at the exact eval budget
clear; clc;
addpath(genpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src')));
S = make_setup(); f = @(x) sim_cost(x, S);
ao.k = 20; ao.nAnts = 10; ao.q = 0.5; ao.xi = 0.85;
bo.SN = 20; bo.limit = 15;

for B = [620 2420]
    ao.maxFE = B; bo.maxFE = B;
    rng(1); [~, Ja, ta] = acor_fe(f, S.lb, S.ub, ao);
    rng(1); [~, Jb, tb] = abc_fe (f, S.lb, S.ub, bo);
    assert(ta.nfe == B && tb.nfe == B, 'evaluation budget not respected');
    fprintf('budget %4d FE:  ACO-R ITAE %.5f   ABC ITAE %.5f\n', B, Ja, Jb);
end
fprintf('\nEvaluation cost of a 60-iteration run: ACO-R = 20 + 60*10 = %d;  ', 20 + 60*10);
fprintf('ABC = 20 + 60*(20+20) = %d, plus at most one scout evaluation per iteration.\n', 20 + 60*40);
fprintf('smoke_fe: PASS\n');
