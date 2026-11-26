function [J, y, t] = sim_cost(x, S)
% same cost as pid_itae_cost but done with polynomials, a lot faster
% S has: P (plant polys), variant ('pid','pidf','pid2'), obj ('ITAE','IAE','ISE','ITSE'), t, dt, noise
% unstable -> same penalty as pid_itae_cost so both can be swapped
[ny, dc, nr] = ctrl_poly(S.variant, x);
[numT, denT] = cl_poly(S.P, ny, dc, nr);

p = roots(denT);
if any(real(p) >= 0) || any(~isfinite(p))
    J = 1e6 + 1e6*max([0; real(p)]);
    y = []; t = S.t;
    return;
end

[A, B, C, D] = tf2ss(numT, denT);
n = size(A, 1);
M  = expm([A B; zeros(1, n+1)] * S.dt);
Ad = M(1:n, 1:n);  Bd = M(1:n, end);

N = numel(S.t);
u = ones(N, 1);
X = ltitr(Ad, Bd, u);
y = X * C.' + D * u;

t = S.t(:);
e = 1 - y;
switch S.obj
    case 'ITAE', J = trapz(t, t .* abs(e));
    case 'IAE',  J = trapz(t,      abs(e));
    case 'ISE',  J = trapz(t,       e.^2 );
    case 'ITSE', J = trapz(t, t .* (e.^2));
    otherwise,   error('sim_cost:obj', 'unknown objective %s', S.obj);
end

if isfield(S, 'noise') && S.noise > 0
    J = J * (1 + S.noise*randn());
end
end
