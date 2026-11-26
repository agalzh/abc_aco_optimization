function P = avr_poly(cfg, tau)
% plant and sensor as polynomials
% tau = optional delay in the forward path (pade, 2nd order)
if nargin < 2, tau = 0; end
p = cfg.plant;

P.ng = p.Ka * p.Ke * p.Kg;
P.dg = conv(conv([p.Ta 1], [p.Te 1]), [p.Tg 1]);

if tau > 0
    % Pade(2,2): (1 - s*tau/2 + s^2*tau^2/12) / (1 + s*tau/2 + s^2*tau^2/12)
    npade = [tau^2/12, -tau/2, 1];
    dpade = [tau^2/12,  tau/2, 1];
    P.ng = conv(P.ng, npade);
    P.dg = conv(P.dg, dpade);
end

P.nh = p.Ks;
P.dh = [p.Ts 1];
end
