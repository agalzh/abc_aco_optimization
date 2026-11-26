function row = summarise_pair(R, label, Jclean)
% one row of stats for an aco-r vs abc run
% Jclean is optional, used when the search ran on a noisy cost
if nargin >= 3 && ~isempty(Jclean)
    a = Jclean.a; b = Jclean.b;
else
    a = R.Ja; b = R.Jb;
end
try, p = ranksum(a, b); catch, p = NaN; end
best = min([a; b]);
tol  = 1.01 * best;                       % near best = within 1% of the best
row = {label, mean(a), std(a), median(a), min(a), 100*mean(a <= tol), ...
              mean(b), std(b), median(b), min(b), 100*mean(b <= tol), ...
              100*mean(b < a), p};
end
