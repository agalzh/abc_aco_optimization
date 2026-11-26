function [xbest, Jbest, history] = abc_pid(costfun, lb, ub, opts)
% abc: employed, onlooker and scout bees
dim = numel(lb);
SN = opts.SN; maxIter = opts.maxIter; limit = opts.limit;

foods = lb + rand(SN, dim) .* (ub - lb);
costs = zeros(SN, 1);
for i = 1:SN
    costs(i) = costfun(foods(i, :));
end
trial = zeros(SN, 1);
history = zeros(maxIter, 1);

% keep the best ever so a scout cant throw it away
[bestCost, bidx0] = min(costs);
bestX = foods(bidx0, :);

for iter = 1:maxIter
    % employed bees
    for i = 1:SN
        [foods, costs, trial] = tryNeighbor(i, foods, costs, trial, lb, ub, costfun);
    end

    % onlookers
    fitness = 1 ./ (1 + costs);
    prob = fitness / sum(fitness);
    i = 1; t = 0;
    while t < SN
        if rand() < prob(i)
            t = t + 1;
            [foods, costs, trial] = tryNeighbor(i, foods, costs, trial, lb, ub, costfun);
        end
        i = i + 1;
        if i > SN, i = 1; end
    end

    % scout
    [maxTrial, sidx] = max(trial);
    if maxTrial > limit
        foods(sidx, :) = lb + rand(1, dim) .* (ub - lb);
        costs(sidx) = costfun(foods(sidx, :));
        trial(sidx) = 0;
    end

    [curBest, cidx] = min(costs);
    if curBest < bestCost
        bestCost = curBest;
        bestX = foods(cidx, :);
    end
    history(iter) = bestCost;
end
Jbest = bestCost;
xbest = bestX;
end

function [foods, costs, trial] = tryNeighbor(i, foods, costs, trial, lb, ub, costfun)
dim = size(foods, 2);
SN = size(foods, 1);
j = randi(dim);
k = randi(SN);
while k == i
    k = randi(SN);
end
phi = -1 + 2 * rand();
v = foods(i, :);
v(j) = foods(i, j) + phi * (foods(i, j) - foods(k, j));
v(j) = min(max(v(j), lb(j)), ub(j));
cv = costfun(v);
if cv < costs(i)
    foods(i, :) = v;
    costs(i) = cv;
    trial(i) = 0;
else
    trial(i) = trial(i) + 1;
end
end
