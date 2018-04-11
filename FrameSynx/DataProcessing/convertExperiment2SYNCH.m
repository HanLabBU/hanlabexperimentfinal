function convertExperiment2SYNCH(experimentObj)

% USAGE:  convertExperiment2SYNCH(experimentObj)

SynchOutput = struct(...
		'fileSequence',struct('name',[],'first_frame',[],'last_frame',[]),...
		'frameArrivalTime',[],...
		'frameMean',[],...
		'frameSynch',[]);
nframes = length(experimentObj.rawTrace);
SyncInput = experimentObj.frameSyncData;%(1:nframes);%NOTE: This whole file needs to be fixed to change the way it indexes into frameSyncData

%% File Sequence = trial object info
trialset = experimentObj.trialSet;
for n = 1:length(trialset)
		a.name = [trialset(n).experimentName,'_',sprintf('%0.5i',trialset(n).number),'.mat'];
		a.first_frame = trialset(n).firstFrame;
		a.last_frame = trialset(n).lastFrame;
		SynchOutput.fileSequence(n,1) = a;
end

%% Frame Arrival Time - time since start in msec
a = [SyncInput.AbsTime]'; % date vectors
a = reshape(a,[6 length(a)/6]);
a = datenum(a'); % serial date numbers (days since 01/01/0000)
a = rem(a,1); % time in days
a = a*24*60*60*1000; % time in milliseconds
SynchOutput.frameArrivalTime = a';

%% Frame Mean - 
SynchOutput.frameMean = experimentObj.rawTrace';

%% Frame Synch
% Stim State
stimon = strcmp({SyncInput.StimState}','stim on');
stimshift = strcmp({SyncInput.StimState}','stim shift');
stimoff = strcmp({SyncInput.StimState}','stim off');
stimstate = zeros(nframes,1);
stimstate(stimon) = 100001;
stimstate(stimshift) = 100002;
stimstate(stimoff) = 100003;
% Experiment State
exppause = strcmp({SyncInput.ExpState}','pause');
expunpause= strcmp({SyncInput.ExpState}','unpause');
expfinished = strcmp({SyncInput.ExpState}','finished');
expstart = strcmp({SyncInput.ExpState}','start');
expstate = zeros(nframes,1);
expstate(exppause) = 2001;
expstate(expunpause) = 2002;
expstate(expfinished) = 2003;
expstate(expstart) = 2004;
% Trial Number
trialnumber = [SyncInput.TrialNumber]';
% Put all together in frameSynch matrix
SynchOutput.frameSynch = [zeros(nframes,1), stimstate, expstate, trialnumber, zeros(nframes,1)]';

%% Save
fname = fullfile(experimentObj.exptFilePath, [experimentObj.exptFileName,'_','SYNCH.mat']);
% fpath = experimentObj.exptFilePath;
% fname = [experimentObj.exptFileName,'_','SYNCH.mat'];
[fname, fpath] = uiputfile(fname,'Save SYNCH File As... ')
if fname
		save(fullfile(fpath,fname),'-struct','SynchOutput')
end
% assignin('base','sdata',SynchOutput);









%% Info
% Rough Translation of BehavControl UDP Messages
% STIM STATE CHANGE
% SY0100001 stim on
% SY0100002 stim shift
% SY0100003 stim off
% SY0100004 stim 1
% SY0100005 stim 2
% SY0100006 stim 3 ... etc
%
% EXPERIMENT STATE CHANGE
% SY12001   pause
% SY12002   unpause
% SY12003   finished
% SY12004   start
%
% TRIAL NUMBER CHANGE
% SY2369    start Trial 369
% SY2370    start Trial 370 ... etc
%
% FILENAME
% FNTWK1    filename is TWK1
