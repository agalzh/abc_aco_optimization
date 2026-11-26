function P = project_paths()
% where the results and figures go
here      = fileparts(mfilename('fullpath'));          % <root>/src/util
P.root    = fileparts(fileparts(here));
P.results = fullfile(P.root, 'results');
P.figures = fullfile(P.results, 'figures');
P.simulink = fullfile(P.root, 'simulink');
if ~isfolder(P.results), mkdir(P.results); end
if ~isfolder(P.figures), mkdir(P.figures); end
end
