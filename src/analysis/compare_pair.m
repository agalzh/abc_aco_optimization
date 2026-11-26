function R = compare_pair(costfun, lb, ub, maxFE, nSeeds, opt)
% runs aco-r and abc with the same seeds and the same eval budget
if nargin < 6, opt = struct(); end
ao.k = 20; ao.nAnts = 10; ao.q = 0.5; ao.xi = 0.85; ao.maxFE = maxFE;
bo.SN = 20; bo.limit = 15; bo.maxFE = maxFE;
if isfield(opt,'k'),  ao.k  = opt.k;  end
if isfield(opt,'SN'), bo.SN = opt.SN; end

dim = numel(lb);
Ja = zeros(nSeeds,1); Jb = zeros(nSeeds,1);
Xa = zeros(nSeeds,dim); Xb = zeros(nSeeds,dim);
Ba = zeros(nSeeds,maxFE); Bb = zeros(nSeeds,maxFE);
Ta = zeros(nSeeds,1); Tb = zeros(nSeeds,1);

parfor r = 1:nSeeds
    rng(r); tic; [xa, ja, tra] = acor_fe(costfun, lb, ub, ao); Ta(r) = toc;
    rng(r); tic; [xb, jb, trb] = abc_fe (costfun, lb, ub, bo); Tb(r) = toc;
    Ja(r) = ja; Jb(r) = jb; Xa(r,:) = xa; Xb(r,:) = xb;
    Ba(r,:) = padtrace(tra.best, maxFE);
    Bb(r,:) = padtrace(trb.best, maxFE);
end

R.Ja = Ja; R.Jb = Jb; R.Xa = Xa; R.Xb = Xb; R.Ba = Ba; R.Bb = Bb;
R.Ta = Ta; R.Tb = Tb; R.maxFE = maxFE; R.nSeeds = nSeeds;
end

function v = padtrace(b, n)
v = nan(1,n);
m = min(numel(b), n);
v(1:m) = b(1:m);
if m < n, v(m+1:end) = b(end); end
end
