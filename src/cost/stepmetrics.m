function info = stepmetrics(y, t)
% overshoot, 10-90% rise time and 2% settling time
y = y(:); t = t(:);
yf = y(end);
info.Overshoot = 100*(max(y) - yf)/yf;
i1 = find(y >= 0.10*yf, 1); i2 = find(y >= 0.90*yf, 1);
if isempty(i1) || isempty(i2), info.RiseTime = NaN; else, info.RiseTime = t(i2)-t(i1); end
out = find(abs(y - yf) > 0.02*abs(yf), 1, 'last');
if isempty(out), info.SettlingTime = 0; else, info.SettlingTime = t(min(out+1, numel(t))); end
end
