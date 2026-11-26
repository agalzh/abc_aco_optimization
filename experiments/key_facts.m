%% small numbers i needed: ku, pu, damping of each design, search radius early vs late
addpath(genpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src')));
P = project_paths(); outdir = P.results;
cfg = avr_config(); G = avr_plant(); Gs = avr_sensor(); s = tf('s');
[Kp,Ki,Kd,Ku,Pu] = compute_zn(G,Gs);
mk = @(x) feedback((x(1)+x(2)/s+x(3)*s)*G, Gs);
zof = @(x) local_zeta(pole(mk(x)));
X.zn  = [0.729431719723353 1.11676763466966  0.119109521358925];
X.aco = [1.01145623318914  0.678511413703303 0.346873381978876];
X.abc = [0.771568113818171 0.52731782730485  0.251968664267344];
K = {}; V = {};
add = @(k,v) deal(k,v);
K{end+1}='Ku';        V{end+1}=sprintf('%.3f',Ku);
K{end+1}='Pu';        V{end+1}=sprintf('%.3f',Pu);
K{end+1}='zeta_zn';   V{end+1}=sprintf('%.2f',zof(X.zn));
K{end+1}='zeta_aco';  V{end+1}=sprintf('%.2f',zof(X.aco));
K{end+1}='zeta_abc';  V{end+1}=sprintf('%.2f',zof(X.abc));
K{end+1}='zn_Kp';     V{end+1}=sprintf('%.3f',Kp);
K{end+1}='zn_Ki';     V{end+1}=sprintf('%.3f',Ki);
K{end+1}='zn_Kd';     V{end+1}=sprintf('%.3f',Kd);
% search radius from the logged traces
TR = load(fullfile(outdir, 'exp3_traces.mat'));
rad = @(tr,i0,i1) mean(arrayfun(@(i) norm(tr.X(i,:) - tr.X(find(tr.J(1:i)==min(tr.J(1:i)),1),:)), i0:i1));
ra_e = rad(TR.tra,1,100);  ra_l = rad(TR.tra,521,620);
rb_e = rad(TR.trb,1,100);  rb_l = rad(TR.trb,521,620);
K{end+1}='radius_aco_early'; V{end+1}=sprintf('%.3f',ra_e);
K{end+1}='radius_aco_late';  V{end+1}=sprintf('%.3f',ra_l);
K{end+1}='radius_abc_early'; V{end+1}=sprintf('%.3f',rb_e);
K{end+1}='radius_abc_late';  V{end+1}=sprintf('%.3f',rb_l);
K{end+1}='contract_aco';     V{end+1}=sprintf('%.0f',ra_e/ra_l);
K{end+1}='contract_abc';     V{end+1}=sprintf('%.1f',rb_e/rb_l);

T = table(K(:), V(:), 'VariableNames', {'Key','Value'});
writetable(T, fullfile(outdir, 'key_facts.csv'));
disp(T);
function z = local_zeta(p)
p = p(abs(imag(p))>1e-6);
if isempty(p), z = 1; return; end
[~,i] = max(real(p));           % dominant (slowest) oscillatory pair
z = -real(p(i))/abs(p(i));
end
