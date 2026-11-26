function G = avr_plant()
% forward path: amplifier * exciter * generator
s = tf('s');
Ka = 10;  Ta = 0.1;   % amplifier
Ke = 1;   Te = 0.4;   % exciter
Kg = 1;   Tg = 1.0;   % generator
G = (Ka/(1+s*Ta)) * (Ke/(1+s*Te)) * (Kg/(1+s*Tg));
end
