function [xbest, Jbest, history] = acor_pid(costfun, lb, ub, opts)
% aco-r (socha & dorigo 2008)
% archive of the k best = pheromone, each ant samples a gaussian around a picked member
% sigma comes from how spread out the archive is
dim = numel(lb);
k = opts.k; nAnts = opts.nAnts; maxIter = opts.maxIter;
q = opts.q; xi = opts.xi;

Archive = lb + rand(k, dim) .* (ub - lb);
Acost = zeros(k, 1);
for i = 1:k
    Acost(i) = costfun(Archive(i, :));
end
[Acost, idx] = sort(Acost);
Archive = Archive(idx, :);

rank = (1:k)';
w = (1 / (q * k * sqrt(2 * pi))) * exp(-((rank - 1).^2) / (2 * q^2 * k^2));
p = w / sum(w);

history = zeros(maxIter, 1);
for iter = 1:maxIter
    newSol = zeros(nAnts, dim);
    newCost = zeros(nAnts, 1);
    for a = 1:nAnts
        x = zeros(1, dim);
        for j = 1:dim
            l = randsample(k, 1, true, p);
            sigma = (xi / (k - 1)) * sum(abs(Archive(:, j) - Archive(l, j)));
            if sigma == 0
                sigma = 1e-6;
            end
            x(j) = Archive(l, j) + sigma * randn();
            x(j) = min(max(x(j), lb(j)), ub(j));
        end
        newSol(a, :) = x;
        newCost(a) = costfun(x);
    end
    allSol = [Archive; newSol];
    allCost = [Acost; newCost];
    [allCost, idx] = sort(allCost);
    Archive = allSol(idx(1:k), :);
    Acost = allCost(1:k);
    history(iter) = Acost(1);
end
xbest = Archive(1, :);
Jbest = Acost(1);
end
