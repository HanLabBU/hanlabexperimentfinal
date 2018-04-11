function [corrTrials,errTrials] = readFiles(fileName)

if nargin<1
    [fileName,path] = uigetfile('*.bhv');
else
    [path name ext] = fileparts(fileName);
    fileName = [name ext];
end

[path fileName],
[head,trials] = readBhvFile([path '/' fileName]);
[path head.EyeDataFileName],
% [ehead,etrials] = readEyeFile([path '/' head.EyeDataFileName]);

tmp = [trials.head];
outcome = [tmp.Outcome];
nTotal = head.TotalTrials,
posCorrect = find(outcome>0),
posError = find(outcome==0),
nCorrect = length(posCorrect),

% add the eyetrace to the trials
% for n = 1:length(trials)
%     tmp = [etrials(n).data.points];
%     trials(n).eyeTrace = [[tmp.X];[tmp.Y];[tmp.T]];
% end

% sort out correct and incorrect trials into separate matrices
corrTrials = trials(posCorrect);
errTrials = trials(posError);
