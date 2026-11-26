function savefig3(fig, name, w, h)
% saves a figure at a fixed size, 200 dpi
set(fig, 'Units','pixels', 'Position', [100 100 w h], 'Color','w');
drawnow;
P = project_paths();
exportgraphics(fig, fullfile(P.figures, name), 'Resolution', 200, 'BackgroundColor','white');
close(fig);
fprintf('  saved %s (%dx%d)\n', name, w, h);
end
