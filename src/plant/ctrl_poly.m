function [ny, dc, nr] = ctrl_poly(variant, x)
% controller polys for x
%   'pid'   x = [Kp Ki Kd]
%   'pidf'  x = [Kp Ki Kd N]        filtered derivative
%   'pid2'  x = [Kp Ki Kd N b c]    2dof with setpoint weights
switch variant
    case 'pid'
        Kp = x(1); Ki = x(2); Kd = x(3);
        ny = [Kd Kp Ki];              % (Kd s^2 + Kp s + Ki)/s
        dc = [1 0];
        nr = ny;

    case 'pidf'
        Kp = x(1); Ki = x(2); Kd = x(3); N = x(4);
        ny = [Kp + Kd*N, Kp*N + Ki, Ki*N];   % over s(s+N)
        dc = [1 N 0];
        nr = ny;

    case 'pid2'
        Kp = x(1); Ki = x(2); Kd = x(3); N = x(4); b = x(5); c = x(6);
        ny = [Kp + Kd*N,     Kp*N + Ki,     Ki*N];
        nr = [Kp*b + Kd*c*N, Kp*b*N + Ki,   Ki*N];
        dc = [1 N 0];

    otherwise
        error('ctrl_poly:variant', 'unknown variant %s', variant);
end
end
