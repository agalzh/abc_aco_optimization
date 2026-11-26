%% all the analysis figures, only reads whats already saved in results/
addpath(genpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src')));
P = project_paths(); D = P.results;
CA = [0.85 0.33 0.10];      % ACOR  (orange)
CB = [0.00 0.45 0.74];      % ABC   (blue)
CZ = [0.35 0.35 0.35];      % ZN    (grey)
S  = make_setup();

%% zn vs aco-r vs abc, step + poles
fprintf('F1 zn detail\n');
G = avr_plant(); Gs = avr_sensor(); s = tf('s');
X = struct('zn' ,[0.729431719723353 1.11676763466966  0.119109521358925], ...
           'aco',[1.01145623318914  0.678511413703303 0.346873381978876], ...
           'abc',[0.771568113818171 0.52731782730485  0.251968664267344]);
t = S.t;
[~,yz] = sim_cost(X.zn ,S); [~,ya] = sim_cost(X.aco,S); [~,yb] = sim_cost(X.abc,S);

fig = figure('Visible','off');
tiledlayout(fig,1,2,'Padding','compact','TileSpacing','compact');

ax = nexttile; hold(ax,'on');
plot(ax,t,yz,'-','LineWidth',3.2,'Color',CZ);
plot(ax,t,ya,'-','LineWidth',3.2,'Color',CA);
plot(ax,t,yb,'-','LineWidth',3.2,'Color',CB);
yline(ax,1,'--k','LineWidth',1.8);
[pk,ipk] = max(yz);
plot(ax,t(ipk),pk,'v','MarkerSize',13,'MarkerFaceColor',CZ,'MarkerEdgeColor','k','LineWidth',1.2);
text(ax,t(ipk)+0.12,pk,'48.6% overshoot','FontSize',16,'Color',CZ,'FontWeight','bold');
xlabel(ax,'Time (s)'); ylabel(ax,'Terminal voltage V_t (p.u.)');
title(ax,'(a)  Step response');
legend(ax,{'Ziegler-Nichols','ACO_R','ABC','Setpoint'},'Location','southeast','FontSize',16);
xlim(ax,[0 5]); ylim(ax,[0 1.6]); figstyle(ax);

ax = nexttile; hold(ax,'on');
mk = @(x) feedback((x(1)+x(2)/s+x(3)*s)*G, Gs);
P  = {pole(mk(X.zn)), pole(mk(X.aco)), pole(mk(X.abc))};
CC = {CZ,CA,CB}; MM = {'o','s','d'};
for z = [0.2 0.4 0.7]
    th = acos(z); r = 16;
    plot(ax,[0 -r*cos(th)],[0  r*sin(th)],':','Color',[.6 .6 .6],'LineWidth',1.4,'HandleVisibility','off');
    plot(ax,[0 -r*cos(th)],[0 -r*sin(th)],':','Color',[.6 .6 .6],'LineWidth',1.4,'HandleVisibility','off');
    text(ax,-r*cos(th)*0.40, -r*sin(th)*0.40, sprintf('\\zeta=%.1f',z),'FontSize',14,'Color',[.45 .45 .45]);
end
hp = gobjects(1,3);
for i=1:3
    hp(i) = plot(ax,real(P{i}),imag(P{i}),MM{i},'MarkerSize',14,'LineWidth',2.6,'Color',CC{i},'MarkerFaceColor','none');
end
% label the dominant pair of each design
for i=1:3
    pc = P{i}(imag(P{i}) > 1e-6);
    if isempty(pc), continue; end
    [~,id] = max(real(pc)); pd = pc(id);
    z = -real(pd)/abs(pd);
    text(ax, real(pd)-0.35, imag(pd)+0.95, sprintf('\\zeta = %.2f', z), ...
        'FontSize',15,'FontWeight','bold','Color',CC{i},'HorizontalAlignment','center');
end
xline(ax,0,'k','LineWidth',1.6,'HandleVisibility','off');
xlabel(ax,'Real axis (s^{-1})'); ylabel(ax,'Imaginary axis (s^{-1})');
title(ax,'(b)  Closed-loop poles');
legend(ax,hp,{'Ziegler-Nichols','ACO_R','ABC'},'Location','southwest','FontSize',16);
xlim(ax,[-12 1]); ylim(ax,[-11 11]); figstyle(ax);
savefig3(fig,'fig_zn_detail.png',1750,760);

%% where each one searched
fprintf('F2/F3 search traces\n');
L = load(fullfile(D,'exp3_grid.mat'));      % Kpv, Kiv, Z, xopt
T = load(fullfile(D,'exp3_traces.mat'));    % tra, trb, maxFE
for which = 1:2
    if which==1, tr = T.tra; nm = 'ACO_R'; file = 'fig_acor_search.png';
    else,        tr = T.trb; nm = 'ABC';   file = 'fig_abc_search.png';  end
    fig = figure('Visible','off'); ax = axes(fig); hold(ax,'on');
    contourf(ax, L.Kpv, L.Kiv, log10(L.Z), 22, 'LineColor','none', 'HandleVisibility','off');
    colormap(ax, flipud(gray(256))); clim(ax,[log10(0.055) log10(2)]);
    cb = colorbar(ax); cb.Label.String = 'log_{10} ITAE'; cb.FontSize = 15; cb.Label.FontSize = 17;
    n = tr.nfe; q = round(linspace(1,n+1,5));
    qc = [0.95 0.75 0.10; 0.45 0.78 0.20; 0.20 0.65 0.90; 0.80 0.10 0.70];
    hs = gobjects(1,4); lg = cell(1,4);
    for k=1:4
        idx = q(k):q(k+1)-1;
        hs(k) = scatter(ax, tr.X(idx,1), tr.X(idx,2), 48, 'filled', ...
            'MarkerFaceColor', qc(k,:), 'MarkerEdgeColor','k', 'LineWidth',0.4, 'MarkerFaceAlpha',0.85);
        lg{k} = sprintf('eval %d-%d', q(k), q(k+1)-1);
    end
    hstar = plot(ax, L.xopt(1), L.xopt(2), 'p', 'MarkerSize',30, 'MarkerFaceColor',[1 1 0.2], ...
        'MarkerEdgeColor','k','LineWidth',2.2);
    % where the run ended
    [Jb, ib] = min(tr.J); xb = tr.X(ib,:);
    plot(ax, xb(1), xb(2), 'o', 'MarkerSize',20, 'LineWidth',3.5, 'Color',[0.85 0 0], 'MarkerFaceColor','none');
    text(ax, xb(1)+0.055, xb(2)+0.080, {'finished here', sprintf('ITAE %.4f', Jb)}, ...
        'FontSize',15,'FontWeight','bold','Color',[0.85 0 0], ...
        'BackgroundColor',[1 1 1],'EdgeColor',[0.85 0 0],'Margin',3);
    text(ax, L.xopt(1)-0.015, L.xopt(2)-0.100, {'best known', sprintf('ITAE %.4f', sim_cost(L.xopt,S))}, ...
        'FontSize',15,'FontWeight','bold','Color',[0.15 0.15 0.15],'HorizontalAlignment','center', ...
        'BackgroundColor',[1 1 1],'EdgeColor',[0.3 0.3 0.3],'Margin',3);
    xlabel(ax,'K_p'); ylabel(ax,'K_i');
    title(ax, {sprintf('%s: every point it evaluated (620 evaluations)', nm), ...
               sprintf('background: ITAE with K_d fixed at %.3f; dots use their own K_d', L.xopt(3))});
    legend(ax, [hs hstar], [lg, {'best known'}], 'Location','northwest','FontSize',15);
    xlim(ax,[L.Kpv(1) L.Kpv(end)]); ylim(ax,[L.Kiv(1) L.Kiv(end)]); figstyle(ax);
    savefig3(fig, file, 1180, 1000);
end

%% search radius + the valley
fprintf('F4 mechanism\n');
E  = readtable(fullfile(D,'exp3_exploitation.csv'));
Hm = readtable(fullfile(D,'exp3_curvature_meta.csv'));
fig = figure('Visible','off');
tiledlayout(fig,1,2,'Padding','compact','TileSpacing','compact');

ax = nexttile; hold(ax,'on');
plot(ax,E.FE,E.ACOR_dist,'-','LineWidth',3.2,'Color',CA);
plot(ax,E.FE,E.ABC_dist ,'-','LineWidth',3.2,'Color',CB);
xlabel(ax,'Cost evaluations'); ylabel(ax,'Distance from running best');
title(ax,'(a)  How far each one still samples');
legend(ax,{'ACO_R','ABC'},'Location','northeast','FontSize',17);
xlim(ax,[0 620]); ylim(ax,[0 0.95]); figstyle(ax);

ax = nexttile; hold(ax,'on');
xo = L.xopt; r = 0.16; ng = 90;
kp = linspace(xo(1)-r, xo(1)+r, ng); ki = linspace(xo(2)-r, xo(2)+r, ng);
Zl = zeros(ng);
for a=1:ng
    for b=1:ng
        Zl(a,b) = sim_cost([kp(b) ki(a) xo(3)], S);
    end
end
contourf(ax, kp, ki, Zl, 18, 'LineColor','none');
colormap(ax, flipud(gray(256)));
cb = colorbar(ax); cb.Label.String='ITAE'; cb.FontSize=15; cb.Label.FontSize=17;

% curvature directions in kp-ki at the best point
hstep = 1e-3; H2 = zeros(2);
for i2 = 1:2
    for j2 = 1:2
        e1 = zeros(1,3); e1(i2) = hstep;
        e2 = zeros(1,3); e2(j2) = hstep;
        H2(i2,j2) = (sim_cost(xo+e1+e2,S) - sim_cost(xo+e1-e2,S) ...
                   - sim_cost(xo-e1+e2,S) + sim_cost(xo-e1-e2,S)) / (4*hstep^2);
    end
end
H2 = (H2+H2')/2; [Vv,Dd] = eig(H2); [dd,io] = sort(diag(Dd)); Vv = Vv(:,io);
vsoft = Vv(:,1);                               % flattest direction = valley floor
ang   = mod(atan2d(vsoft(2), vsoft(1)), 180);
tiltd = min(abs(ang-0), abs(ang-90));
Lv = 0.135;
plot(ax, xo(1)+[-1 1]*Lv*vsoft(1), xo(2)+[-1 1]*Lv*vsoft(2), '-', ...
    'LineWidth',4, 'Color',[0.10 0.60 0.25]);
quiver(ax,xo(1),xo(2), 0.10,0,'LineWidth',3,'Color',CB,'MaxHeadSize',1.3);
quiver(ax,xo(1),xo(2), 0,0.10,'LineWidth',3,'Color',CB,'MaxHeadSize',1.3);
plot(ax,xo(1),xo(2),'p','MarkerSize',28,'MarkerFaceColor',[1 1 0.2],'MarkerEdgeColor','k','LineWidth',2.2);
text(ax,xo(1)-0.15,xo(2)+0.138, sprintf('valley floor, %.0f%c off the axes', tiltd, char(176)), ...
    'FontSize',15,'Color',[0.08 0.45 0.20],'FontWeight','bold');
text(ax,xo(1)-0.148,xo(2)-0.125,sprintf('single-coordinate\nmoves cut across it'), ...
    'FontSize',14,'Color',CB,'FontWeight','bold');
xlabel(ax,'K_p'); ylabel(ax,'K_i');
title(ax,sprintf('(b)  Valley around the best design (curvature ratio %.0f:1)', Hm.ConditionNumber));
figstyle(ax);
fprintf('  valley tilt in (Kp,Ki): %.1f deg off nearest axis\n', tiltd);
writetable(table(tiltd,'VariableNames',{'ValleyTiltDeg'}), fullfile(D,'exp3_valley_tilt.csv'));
savefig3(fig,'fig_mechanism.png',1750,780);

%% equal budget curves
fprintf('F5 budget\n');
Cv = readtable(fullfile(D,'exp1_convergence.csv'));
B  = readtable(fullfile(D,'exp1_budget_summary.csv'));
fig = figure('Visible','off');
tiledlayout(fig,1,2,'Padding','compact','TileSpacing','compact');

ax = nexttile; hold(ax,'on');
bandfill(ax, Cv.FE, Cv.ACOR_mean, Cv.ACOR_std, CA);
bandfill(ax, Cv.FE, Cv.ABC_mean , Cv.ABC_std , CB);
pa = plot(ax,Cv.FE,Cv.ACOR_mean,'-','LineWidth',3.4,'Color',CA);
pb = plot(ax,Cv.FE,Cv.ABC_mean ,'-','LineWidth',3.4,'Color',CB);
xline(ax,620 ,'--','LineWidth',2.2,'Color',CA,'HandleVisibility','off');
xline(ax,2420,'--','LineWidth',2.2,'Color',CB,'HandleVisibility','off');
text(ax,660 ,0.148,sprintf('60 iterations of ACO_R\n= 620 evaluations'),'FontSize',14,'Color',CA,'FontWeight','bold');
text(ax,1330,0.102,sprintf('60 iterations of ABC\n\approx 2420 evaluations'),'FontSize',14,'Color',CB,'FontWeight','bold');
set(ax,'YScale','log'); xlabel(ax,'Cost evaluations'); ylabel(ax,'Best ITAE so far');
title(ax,'(a)  Equal-budget convergence (30 seeds, mean \pm 1\sigma)');
legend(ax,[pa pb],{'ACO_R','ABC'},'Location','northeast','FontSize',17);
xlim(ax,[20 2520]); ylim(ax,[0.05 0.20]);
set(ax,'YTick',[0.05 0.06 0.08 0.10 0.14 0.20],'YTickLabel',{'0.05','0.06','0.08','0.10','0.14','0.20'});
figstyle(ax);

ax = nexttile; hold(ax,'on');
xb = (1:height(B))';
sig = B.p_ranksum < 0.05;
area(ax,[0 height(B)+1],[50 50],'FaceColor',CA,'FaceAlpha',0.10,'EdgeColor','none','HandleVisibility','off');
bar(ax, xb, B.ABC_winrate_pct, 0.62, 'FaceColor', CB, 'EdgeColor','k', 'LineWidth',1.2);
yline(ax,50,'--k','LineWidth',2.6);
for i=1:numel(xb)
    txt = sprintf('%.0f%%', B.ABC_winrate_pct(i));
    if ~sig(i), txt = [txt ' (n.s.)']; end %#ok<AGROW>
    text(ax, xb(i), B.ABC_winrate_pct(i)+3.5, txt, 'HorizontalAlignment','center', ...
        'FontSize',14,'FontWeight','bold','Rotation',0);
end
text(ax,0.62,93,'ABC better'  ,'FontSize',16,'Color',CB,'FontWeight','bold');
text(ax,0.62,43,'ACO_R better','FontSize',16,'Color',CA,'FontWeight','bold');
set(ax,'XTick',xb,'XTickLabel',string(B.FE));
xlim(ax,[0.4 height(B)+0.6]); ylim(ax,[0 112]);
xlabel(ax,'Evaluation budget'); ylabel(ax,'Runs in which ABC wins (%)');
title(ax,'(b)  Who wins, as the budget grows'); figstyle(ax);
savefig3(fig,'fig_budget.png',1800,820);

%% dimension
fprintf('F6 dimension\n');
T2 = readtable(fullfile(D,'exp2_dimension.csv'));
fig = figure('Visible','off');
tiledlayout(fig,1,2,'Padding','compact','TileSpacing','compact');

ax = nexttile; hold(ax,'on');
x = (1:height(T2))';
errorbar(ax,x-0.07,T2.ACOR_mean,T2.ACOR_std,'o','LineWidth',3,'Color',CA, ...
    'MarkerSize',14,'MarkerFaceColor',CA,'CapSize',14,'LineStyle','none');
errorbar(ax,x+0.07,T2.ABC_mean ,T2.ABC_std ,'s','LineWidth',3,'Color',CB, ...
    'MarkerSize',14,'MarkerFaceColor',CB,'CapSize',14,'LineStyle','none');
set(ax,'XTick',x,'XTickLabel',compose('D = %d',T2.Dim)); xlim(ax,[0.6 numel(x)+0.4]);
xlabel(ax,'Number of tuned parameters'); ylabel(ax,'Best ITAE (mean \pm \sigma)');
title(ax,'(a)  Same plant, richer controller');
legend(ax,{'ACO_R','ABC'},'Location','northwest','FontSize',17); figstyle(ax);

ax = nexttile; hold(ax,'on');
bar(ax,x,T2.ABC_winrate_pct,0.6,'FaceColor',CB,'EdgeColor','k');
yline(ax,50,'--k','LineWidth',2.4);
text(ax,3.52,57,'ABC better'  ,'FontSize',15,'Color',CB,'FontWeight','bold');
text(ax,3.52,43,'ACO_R better','FontSize',15,'Color',CA,'FontWeight','bold');
for i=1:numel(x)
    text(ax,x(i),T2.ABC_winrate_pct(i)+4,sprintf('%.0f%%',T2.ABC_winrate_pct(i)), ...
        'HorizontalAlignment','center','FontSize',17,'FontWeight','bold');
end
set(ax,'XTick',x,'XTickLabel',compose('D = %d',T2.Dim)); ylim(ax,[0 112]); xlim(ax,[0.4 4.35]);
xlabel(ax,'Number of tuned parameters'); ylabel(ax,'Runs where ABC wins (%)');
title(ax,'(b)  The ranking inverts'); figstyle(ax);
savefig3(fig,'fig_dimension.png',1780,790);

%% delay
fprintf('F7 delay\n');
T5 = readtable(fullfile(D,'exp5_delay.csv'));
fig = figure('Visible','off');
tiledlayout(fig,1,2,'Padding','compact','TileSpacing','compact');

ax = nexttile; hold(ax,'on');
bandfill(ax,T5.Tau_s,T5.ACOR_mean,T5.ACOR_std,CA);
bandfill(ax,T5.Tau_s,T5.ABC_mean ,T5.ABC_std ,CB);
plot(ax,T5.Tau_s,T5.ACOR_mean,'-o','LineWidth',3.2,'Color',CA,'MarkerSize',11,'MarkerFaceColor',CA);
plot(ax,T5.Tau_s,T5.ABC_mean ,'-s','LineWidth',3.2,'Color',CB,'MarkerSize',11,'MarkerFaceColor',CB);
xlabel(ax,'Transport delay \tau (s)'); ylabel(ax,'Best ITAE (mean \pm \sigma)');
title(ax,'(a)  Best ITAE vs transport delay');
legend(ax,{'ACO_R','ABC'},'Location','northwest','FontSize',17); figstyle(ax);

ax = nexttile; hold(ax,'on');
plot(ax,T5.Tau_s,T5.ABC_winrate_pct,'-s','LineWidth',3.4,'Color',CB,'MarkerSize',13,'MarkerFaceColor',CB);
yline(ax,50,'--k','LineWidth',2.4);
text(ax,T5.Tau_s(1)+0.004,57,'ABC better'  ,'FontSize',16,'Color',CB,'FontWeight','bold');
text(ax,T5.Tau_s(1)+0.004,43,'ACO_R better','FontSize',16,'Color',CA,'FontWeight','bold');
xlabel(ax,'Transport delay \tau (s)'); ylabel(ax,'Runs where ABC wins (%)');
title(ax,'(b)  The ranking reverses'); ylim(ax,[0 105]); figstyle(ax);
savefig3(fig,'fig_delay.png',1780,790);

%% objective + noise
fprintf('F8 objective/noise\n');
T4 = readtable(fullfile(D,'exp4_objective.csv'));
T4d= readtable(fullfile(D,'exp4_objective_designs.csv'));
T6 = readtable(fullfile(D,'exp6_noise.csv'));
fig = figure('Visible','off');
tiledlayout(fig,1,3,'Padding','compact','TileSpacing','compact');

% (a) design from each objective, same step response
ax = nexttile; hold(ax,'on');
objs = {'ITAE','IAE','ISE','ITSE'};
oc = [0.00 0.45 0.74; 0.47 0.67 0.19; 0.85 0.33 0.10; 0.49 0.18 0.56];
for i = 1:numel(objs)
    r = T4d(strcmp(T4d.Objective,objs{i}) & strcmp(T4d.Method,'ABC'), :);
    [~, y] = sim_cost([r.Kp r.Ki r.Kd], S);
    plot(ax, S.t, y, '-', 'LineWidth',3.0, 'Color', oc(i,:), ...
        'DisplayName', sprintf('%s  (OS %.0f%%, t_s %.1f s)', objs{i}, r.Overshoot_pct, r.SettlingTime_s));
end
yline(ax,1,'--k','LineWidth',1.6,'HandleVisibility','off');
xlabel(ax,'Time (s)'); ylabel(ax,'V_t (p.u.)');
title(ax,'(a)  The objective picks the design');
legend(ax,'Location','southeast','FontSize',13);
xlim(ax,[0 5]); ylim(ax,[0 1.45]); figstyle(ax);

% (b) who wins under each objective
ax = nexttile; hold(ax,'on');
x = (1:height(T4))';
bar(ax, x, T4.ABC_winrate_pct, 0.6, 'FaceColor', CB, 'EdgeColor','k','LineWidth',1.2);
yline(ax,50,'--k','LineWidth',2.4);
for i=1:numel(x)
    text(ax,x(i),T4.ABC_winrate_pct(i)+4,sprintf('%.0f%%',T4.ABC_winrate_pct(i)), ...
        'HorizontalAlignment','center','FontSize',15,'FontWeight','bold');
end
text(ax,2.10,62,'ABC better'  ,'FontSize',15,'Color',CB,'FontWeight','bold');
text(ax,2.10,40,'ACO_R better','FontSize',15,'Color',CA,'FontWeight','bold');
text(ax,2.52,22,{'on IAE, ISE and ITSE both','reach the SAME optimum;','ACO_R is only more precise','(gap < 0.1%)'}, ...
    'FontSize',12.5,'HorizontalAlignment','center','Color',[0.25 0.25 0.25]);
set(ax,'XTick',x,'XTickLabel',T4.Objective); ylim(ax,[0 112]);
xlabel(ax,'Objective function'); ylabel(ax,'Runs in which ABC wins (%)');
title(ax,'(b)  Ranking by objective'); figstyle(ax);

% (c) noise, scored on the clean itae
ax = nexttile; hold(ax,'on');
x = (1:height(T6))';
errorbar(ax,x-0.07,T6.ACOR_mean,T6.ACOR_std,'o','LineWidth',3,'Color',CA, ...
    'MarkerSize',13,'MarkerFaceColor',CA,'CapSize',13,'LineStyle','none');
errorbar(ax,x+0.07,T6.ABC_mean ,T6.ABC_std ,'s','LineWidth',3,'Color',CB, ...
    'MarkerSize',13,'MarkerFaceColor',CB,'CapSize',13,'LineStyle','none');
set(ax,'XTick',x,'XTickLabel',compose('%g%%',T6.Noise_pct));
xlim(ax,[0.6 numel(x)+0.4]);
xlabel(ax,'Noise on each cost evaluation'); ylabel(ax,'True ITAE of returned design');
title(ax,'(c)  Noise: the ranking holds');
legend(ax,{'ACO_R','ABC'},'Location','northwest','FontSize',14); figstyle(ax);
savefig3(fig,'fig_objective_noise.png',2300,900);

fprintf('\nALL FIGURES DONE\n');

%% helper
function bandfill(ax, x, m, sd, c)
x = x(:); m = m(:); sd = sd(:);
fill(ax, [x; flipud(x)], [m-sd; flipud(m+sd)], c, ...
    'FaceAlpha',0.45, 'EdgeColor','none', 'HandleVisibility','off');
end
