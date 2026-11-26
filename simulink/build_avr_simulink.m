%% builds the avr loop in simulink and checks it against the tf step response
% saves avr_pid.slx and a png of the diagram
clear; clc; close all;
addpath(genpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src')));
P = project_paths();
cfg = avr_config(); p = cfg.plant;

mdl = 'avr_pid';
if bdIsLoaded(mdl), close_system(mdl, 0); end
new_system(mdl);

% abc gains, Nf = derivative filter (high = close to ideal)
Kp = 0.772; Ki = 0.527; Kd = 0.252; Nf = 1000;

% blocks
add_block('simulink/Sources/Step',            [mdl '/Vref'], 'Time','0','After','1', 'Position',[20 98 50 128]);
add_block('simulink/Math Operations/Sum',     [mdl '/Sum'],  'Inputs','+-','IconShape','round', 'Position',[95 100 120 125]);
add_block('simulink/Continuous/PID Controller',[mdl '/PID'], 'P',num2str(Kp),'I',num2str(Ki),'D',num2str(Kd), ...
          'N',num2str(Nf), 'Position',[160 90 240 140]);
add_block('simulink/Continuous/Transfer Fcn', [mdl '/Amplifier'], 'Numerator',sprintf('[%g]',p.Ka), 'Denominator',sprintf('[%g 1]',p.Ta), 'Position',[285 92 365 138]);
add_block('simulink/Continuous/Transfer Fcn', [mdl '/Exciter'],   'Numerator',sprintf('[%g]',p.Ke), 'Denominator',sprintf('[%g 1]',p.Te), 'Position',[405 92 485 138]);
add_block('simulink/Continuous/Transfer Fcn', [mdl '/Generator'], 'Numerator',sprintf('[%g]',p.Kg), 'Denominator',sprintf('[%g 1]',p.Tg), 'Position',[525 92 605 138]);
add_block('simulink/Sinks/Scope',             [mdl '/Vt'], 'Position',[690 95 730 135]);
add_block('simulink/Sinks/To Workspace',      [mdl '/Vt_out'], 'VariableName','Vt_sim','SaveFormat','Structure With Time', 'Position',[690 170 760 200]);
% sensor in the feedback path
add_block('simulink/Continuous/Transfer Fcn', [mdl '/Sensor'], 'Numerator',sprintf('[%g]',p.Ks), 'Denominator',sprintf('[%g 1]',p.Ts), ...
          'Orientation','left', 'Position',[395 230 510 280]);

% wiring
add_line(mdl,'Vref/1','Sum/1','autorouting','on');
add_line(mdl,'Sum/1','PID/1','autorouting','on');
add_line(mdl,'PID/1','Amplifier/1','autorouting','on');
add_line(mdl,'Amplifier/1','Exciter/1','autorouting','on');
add_line(mdl,'Exciter/1','Generator/1','autorouting','on');
add_line(mdl,'Generator/1','Vt/1','autorouting','on');
add_line(mdl,'Generator/1','Vt_out/1','autorouting','on');     % branch to workspace
add_line(mdl,'Generator/1','Sensor/1','autorouting','on');     % branch to sensor
add_line(mdl,'Sensor/1','Sum/2','autorouting','on');           % feedback to minus input

% solver, save
set_param(mdl,'StopTime',num2str(cfg.Tsim),'Solver','ode45');
save_system(mdl, fullfile(P.simulink, [mdl '.slx']));

% diagram png
try
    print(['-s' mdl], '-dpng', '-r200', fullfile(P.figures,'avr_simulink.png'));
    fprintf('Exported avr_simulink.png\n');
catch ME
    warning('print -s failed (%s); trying saveas.', ME.message);
    saveas(get_param(mdl,'Handle'), fullfile(P.figures,'avr_simulink.png'));
end

% simulate and compare with the tf response
so = sim(mdl, 'StopTime', num2str(cfg.Tsim));
ts = so.Vt_sim.time; ys = so.Vt_sim.signals.values;
s = tf('s'); C = Kp + Ki/s + Kd*s;
G = avr_plant(); Gs = avr_sensor();
tu = (0:0.01:cfg.Tsim)';                 % same time grid for both
yi  = step(feedback(C*G,Gs), tu);
ysi = interp1(ts, ys(:), tu, 'linear');
fprintf('Simulink vs ideal-TF step response: max |diff| = %.4g (filter N=%g)\n', ...
    max(abs(ysi - yi)), Nf);

fprintf('Saved: avr_pid.slx, avr_simulink.png\n');
