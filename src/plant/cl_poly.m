function [numT, denT] = cl_poly(P, ny, dc, nr)
% closed loop polys
%   T = (ng*nr*dh) / (dc*dg*dh + ng*ny*nh)
n = conv(conv(P.ng, nr), P.dh);
d = padd(conv(conv(dc, P.dg), P.dh), conv(conv(P.ng, ny), P.nh));
L = numel(d);
numT = [zeros(1, L - numel(n)), n];
denT = d;
end

function c = padd(a, b)
% adds two polys of different length
L = max(numel(a), numel(b));
c = [zeros(1, L - numel(a)), a] + [zeros(1, L - numel(b)), b];
end
