function err = runExperimentWithUpdate(varargin)
if (nargin<1)
	prevDir = evalin('base','pwd;');
% 	cd(virmenExperimentPath)
    [virmenExperimentName, pathName] = uigetfile('*.mat');
    virmenExperimentName = fullfile(pathName,virmenExperimentName);
	cd(prevDir)
else
    virmenExperimentName = varargin{1};
end

try
load(virmenExperimentName);
exper = updateCode(exper);
assignin('base','exper',exper)

err = run(exper);

catch me
    disp(me.message)
    disp(me.stack(1))
end