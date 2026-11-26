function S = make_setup(varargin)
% settings for sim_cost. default = ideal pid, itae, 0-5 s at 1 ms, no delay, no noise
ip = inputParser;
ip.addParameter('variant', 'pid');
ip.addParameter('obj',     'ITAE');
ip.addParameter('tau',      0);
ip.addParameter('noise',    0);
ip.parse(varargin{:});
o = ip.Results;

cfg  = avr_config();
S.P       = avr_poly(cfg, o.tau);
S.variant = o.variant;
S.obj     = o.obj;
S.noise   = o.noise;
S.dt      = 0.001;
S.t       = 0:S.dt:cfg.Tsim;
S.cfg     = cfg;

% box per variant, the gains stay in [0,1.5], N and b,c get their own range
switch o.variant
    case 'pid',  S.lb = [0 0 0];              S.ub = [1.5 1.5 1.5];
    case 'pidf', S.lb = [0 0 0 1];            S.ub = [1.5 1.5 1.5 100];
    case 'pid2', S.lb = [0 0 0 1 0 0];        S.ub = [1.5 1.5 1.5 100 1 1];
end
S.dim = numel(S.lb);
end
