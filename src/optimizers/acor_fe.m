function [xbest, Jbest, tr] = acor_fe(costfun, lb, ub, opts)
% aco-r but it stops after a fixed no. of evals (same logic as acor_pid.m), logs every eval
dim = numel(lb);
k = opts.k; nAnts = opts.nAnts; q = opts.q; xi = opts.xi; maxFE = opts.maxFE;

nfe = 0; Jbest = inf; xbest = nan(1, dim); stop = false;
trX = zeros(maxFE, dim); trJ = zeros(maxFE, 1); trB = zeros(maxFE, 1);

    function J = ev(x)
        if stop, J = inf; return; end
        J = costfun(x);
        nfe = nfe + 1;
        if J < Jbest, Jbest = J; xbest = x; end
        trX(nfe, :) = x; trJ(nfe) = J; trB(nfe) = Jbest;
        if nfe >= maxFE, stop = true; end
    end

Archive = lb + rand(k, dim) .* (ub - lb);
Acost = zeros(k, 1);
for i = 1:k
    Acost(i) = ev(Archive(i, :));
    if stop, break; end
end
[Acost, idx] = sort(Acost);
Archive = Archive(idx, :);

rank = (1:k)';
w = (1 / (q * k * sqrt(2 * pi))) * exp(-((rank - 1).^2) / (2 * q^2 * k^2));
p = w / sum(w);

while ~stop
    newSol = zeros(nAnts, dim);
    newCost = inf(nAnts, 1);
    for a = 1:nAnts
        x = zeros(1, dim);
        for j = 1:dim
            l = randsample(k, 1, true, p);
            sigma = (xi / (k - 1)) * sum(abs(Archive(:, j) - Archive(l, j)));
            if sigma == 0, sigma = 1e-6; end
            x(j) = Archive(l, j) + sigma * randn();
            x(j) = min(max(x(j), lb(j)), ub(j));
        end
        newSol(a, :) = x;
        newCost(a) = ev(x);
        if stop, break; end
    end
    keep = isfinite(newCost);
    allSol = [Archive; newSol(keep, :)];
    allCost = [Acost; newCost(keep)];
    [allCost, idx] = sort(allCost);
    Archive = allSol(idx(1:k), :);
    Acost = allCost(1:k);
end

tr.X = trX(1:nfe, :); tr.J = trJ(1:nfe); tr.best = trB(1:nfe); tr.nfe = nfe;
end
