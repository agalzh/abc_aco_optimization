function J = pid_itae_cost(x, G, Gs, Tsim)
% itae of the step response for x = [Kp Ki Kd]
% unstable gains get a big penalty instead of an error
s = tf('s');
Kp = x(1); Ki = x(2); Kd = x(3);
C = Kp + Ki/s + Kd*s;
CL = feedback(C*G, Gs);

p = pole(CL);
if any(real(p) >= 0) || any(~isfinite(p))
    J = 1e6 + 1e6*max([0; real(p)]);
    return;
end

dt = 0.001;
t = 0:dt:Tsim;
y = step(CL, t);
e = 1 - y;
J = trapz(t, t(:) .* abs(e(:)));
end
