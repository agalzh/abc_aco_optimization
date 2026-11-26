function setup()
% adds the code folders to the path, run it once from the repo folder
root = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(root, 'src')));
addpath(fullfile(root, 'experiments'), fullfile(root, 'simulink'), fullfile(root, 'tests'));
fprintf('paths added\n');
end
