function Gs = avr_sensor()
% sensor tf (feedback path)
s = tf('s');
Ks = 1; Ts = 0.05;
Gs = Ks/(1+s*Ts);
end
