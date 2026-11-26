function [Kp, Ki, Kd, Ku, Pu] = compute_zn(G, Gs)
% ziegler nichols from ku and pu (gain margin of the loop)
[Gm, ~, Wcg, ~] = margin(G*Gs);
Ku = Gm;
Pu = 2*pi/Wcg;

Kp = 0.6*Ku;
Ki = 1.2*Ku/Pu;
Kd = 0.6*Ku*Pu/8;
end
