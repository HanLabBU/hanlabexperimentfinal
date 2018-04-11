function setProjectPath

[a,~] = fileparts(which('setProjectPath.m'));
[imaqpath,~] = fileparts(a);
addpath(genpath(imaqpath));
savepath;