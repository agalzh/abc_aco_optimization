function [xbest, Jbest, tr] = abc_fe(costfun, lb, ub, opts)
% abc but it stops after a fixed no. of evals (same logic as abc_pid.m)
dim = numel(lb);
SN = opts.SN; limit = opts.limit; maxFE = opts.maxFE;

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

foods = lb + rand(SN, dim) .* (ub - lb);
costs = inf(SN, 1);
for i = 1:SN
    costs(i) = ev(foods(i, :));
    if stop, break; end
end
trial = zeros(SN, 1);

    function neighbour(i)
        j = randi(dim);
        kk = randi(SN);
        while kk == i, kk = randi(SN); end
        phi = -1 + 2 * rand();
        v = foods(i, :);
        v(j) = foods(i, j) + phi * (foods(i, j) - foods(kk, j));
        v(j) = min(max(v(j), lb(j)), ub(j));
        cv = ev(v);
        if cv < costs(i)
            foods(i, :) = v; costs(i) = cv; trial(i) = 0;
        else
            trial(i) = trial(i) + 1;
        end
    end

while ~stop
    % employed bees
    for i = 1:SN
        neighbour(i); if stop, break; end
    end
    if stop, break; end

    % onlookers
    fitness = 1 ./ (1 + costs);
    prob = fitness / sum(fitness);
    i = 1; t = 0;
    while t < SN && ~stop
        if rand() < prob(i)
            t = t + 1;
            neighbour(i);
        end
        i = i + 1;
        if i > SN, i = 1; end
    end
    if stop, break; end

    % scout
    [maxTrial, sidx] = max(trial);
    if maxTrial > limit
        foods(sidx, :) = lb + rand(1, dim) .* (ub - lb);
        costs(sidx) = ev(foods(sidx, :));
        trial(sidx) = 0;
    end
end

tr.X = trX(1:nfe, :); tr.J = trJ(1:nfe); tr.best = trB(1:nfe); tr.nfe = nfe;
end
