function ax = figstyle(ax)
% bigger fonts and thicker lines so the plots are readable
set(ax, 'FontName','Helvetica', 'FontSize',17, 'LineWidth',1.4, ...
        'Box','on', 'XGrid','on','YGrid','on', 'GridAlpha',0.18, 'Layer','top');
ax.XLabel.FontSize = 19; ax.YLabel.FontSize = 19;
ax.Title.FontSize  = 20; ax.Title.FontWeight = 'bold';
end
