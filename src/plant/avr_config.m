function cfg = avr_config()
% plant values and the search box

% plant values from gaing 2004
cfg.plant.Ka = 10;  cfg.plant.Ta = 0.10;   % amplifier
cfg.plant.Ke = 1;   cfg.plant.Te = 0.40;   % exciter
cfg.plant.Kg = 1;   cfg.plant.Tg = 1.00;   % generator (Kg,Tg vary with load)
cfg.plant.Ks = 1;   cfg.plant.Ts = 0.05;   % sensor

cfg.Tsim = 5;        % itae from 0 to 5 s

% search box, range from gaing 2004 (no negative gains)
cfg.lb = [0 0 0];
cfg.ub = [1.5 1.5 1.5];
cfg.bounds_justification = 'range [0,1.5] from gaing 2004, bounds_study.m shows a bigger box doesnt really help';
end
