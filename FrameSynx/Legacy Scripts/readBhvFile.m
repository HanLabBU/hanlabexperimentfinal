function [header,trials] = readBhvFile(fileName)

if nargin<1
    [fileName,path] = uigetfile('*.bhv');
    fileName = [path fileName];
end

CHUNK_HEAD = struct(...
    'ID',{'char',[4]},...
    'Size',{'ulong',[1]});

% typedef struct tagBEHAV_FILE_HEADER
% {
% 	char	ID[4];					//"HEAD" - HEADer
% 	ULONG	Size;					//size of the header = 256 bytes
% 	char	Tag[4];					//01 01 the version info
% 	char	DateTimeRecorded[24];	//02 07 the date and time the file was made
% 	char	ThisFileName[16];		//03 11 the name of the original file
% 	char	EyeDataFileName[16];	//04 15 the name of the associated eye log file
% 	char	ExperimentName[4];		//05 16 the name of the experiment
% 	ULONG	TotalTrials;			//06 17 the total number of trials collected
% 	char	Comments[188];			//07 64
% } BEHAV_FILE_HEADER;

BEHAV_FILE_HEADER = struct(...
    'ID',{'char',[4]},...
    'Size',{'ulong',[1]},...
    'Tag',{'char',[4]},...
    'DateTimeRecorded',{'char',[24]},...
    'ThisFileName',{'char',[16]},...
    'EyeDataFileName',{'char',[16]},...
    'ExperimentName',{'char',[4]},...
    'TotalTrials',{'ulong',[1]},...
    'Comments',{'char',[188]});

% typedef struct tagTRIAL_HEADER
% {
% 	char	ID[4];					//"TRIH" - TRIal Header
% 	ULONG	Size;					// size of trial header = 256 bytes
% 	char	Tag[4];					//01 01
% 	ULONG	TrialNumber;			//02 02 the global trial number
% 	double	StartTime;				//03 04 the start time of the trial
% 	double	EndTime;				//04 06 the end time of the trial
% 	ULONG	Outcome;				//05 07 the outcome of the trial
% 	ULONG	TotalEvents;			//06 08 the number of events to follow
% 	char	Comments[224];			//07 64
% } TRIAL_HEADER;

TRIAL_HEADER = struct(...
    'ID',{'char',[4]},...
    'Size',{'ulong',[1]},...
    'Tag',{'char',[4]},...
    'TrialNumber',{'ulong',[1]},...
    'StartTime',{'double',[1]},...
    'EndTime',{'double',[1]},...
    'Outcome',{'ulong',[1]},...
    'TotalEvents',{'ulong',[1]},...
    'Comments',{'char',[224]});

% typedef struct tagTRIAL_STIM
% {
% 	char	ID[4];					//"TRIS" - TRIal Stimulus descriptor
% 	ULONG	Size;					// size of trial stimulus descriptor = 256 bytes
% 	char	Tag[4];					//01 01
% 	ULONG	TrialNumber;			//02 02 the global trial number
% 	char	Info[STIM_INFO_SIZE];	//03 64 stimulus information (arbitrary data)
% } TRIAL_STIM;

TRIAL_STIM = struct(...
    'ID',{'char',[4]},...
    'Size',{'ulong',[1]},...
    'Tag',{'char',[4]},...
    'TrialNumber',{'ulong',[1]},...
    'Info',{'char',[248]});

% typedef struct tagRFMP_INFO
% {
% 	char	ID[4];		// "RFIN" - RFmap stimulus INfo
% 	ULONG	Size;		// size of info
% 	double	StimPosX;	// stimulus X position
% 	double	StimPosY;	// 
% 	double	StimOrient; // stimulus orientation
% 	double	StimWidth;
% 	double	StimHeight;
% 	double  StimSpatial;
% 	double	StimTemporal;
% 	//double	Stim
% 
% 	double	FixPosX;	// fixation X position
% 	double	FixPosY;	//
% 	double	FixDia;
% 	double	FixWinDia;
% 	
% 	ULONG	MaskType;	// type of mask used horizontal, vertical, or none)
% 	ULONG	MaskPolarity;
% 	double  MaskStart;
% 	double	MaskEnd;
% } RFMP_INFO;

RFMP_INFO = struct(...
    'ID',{'char',[4]},...
    'Size',{'ulong',[1]},...
    'StimPosX',{'double',[1]},...
	'StimPosY',{'double',[1]},...
	'StimOrient',{'double',[1]},...
	'StimWidth',{'double',[1]},...
	'StimHeight',{'double',[1]},...
	'StimSpatial',{'double',[1]},...
	'StimTemporal',{'double',[1]},...
	'FixPosX',{'double',[1]},...
	'FixPosY',{'double',[1]},...
	'FixDia',{'double',[1]},...
	'FixWinDia',{'double',[1]},...
	'MaskType',{'ulong',[1]},...
	'MaskPolarity',{'ulong',[1]},...
	'MaskStart',{'double',[1]},...
	'MaskEnd',{'double',[1]});


% typedef struct tagTRIAL_EVENT
% {
% 	char	ID[4];					//"TRIE" - TRIal Event
% 	ULONG	Size;					// size of trial event = 256 bytes
% 	char	Tag[4];					//01 01
% 	ULONG	TrialNumber;			//02 02 the global trial number
% 	double	Time;					//03 04 the time of the event
% 	ULONG	Event;					//04 05 the event code
% 	char	Comments[236];			//05 08
% } TRIAL_EVENT;

TRIAL_EVENT = struct(...
    'ID',{'char',[4]},...
    'Size',{'ulong',[1]},...
    'Tag',{'char',[4]},...
    'TrialNumber',{'ulong',[1]},...
    'Time',{'double',[1]},...
    'Event',{'char',[240]});


data = {};
pos = 1;
    
fid = fopen(fileName);

header = readStructFromFile(BEHAV_FILE_HEADER,fid,0);
data{pos} = header;
nTrials = header.TotalTrials;

if nTrials == 0
    UnfinishedHeader = 1;
    fprintf('%s: %s contains unknown number of trials\n',mfilename,fileName);
else
    UnfinishedHeader = 0;
    fprintf('%s: %s contains %i trials\n',mfilename,fileName,nTrials);
end

fprintf('\t progress: %03i',0);
chunk = readStructFromFile(CHUNK_HEAD,fid,1);
trial = 0;
while ~isempty(chunk.ID)
    
    pos = pos + 1;
    switch chunk.ID
    case 'TRIH' % trial header
        data{pos} = readStructFromFile(TRIAL_HEADER,fid,0);
        %disp(['Read Trial: ' num2str(data{pos}.TrialNumber)]);
        trial = trial + 1;
        if UnfinishedHeader
            fprintf('\b\b\b%03i',trial);
        else
            fprintf('\b\b\b%03i',round(100*trial/nTrials));
        end
    case 'TRIE' % trial event
        data{pos} = readStructFromFile(TRIAL_EVENT,fid,0);
    case 'TRIS' % stimulus info
        data{pos} = readStructFromFile(TRIAL_STIM,fid,0);
    case 'RFIN' % RfMap stimulus info
        data{pos} = readStructFromFile(RFMP_INFO,fid,1);
        fseek(fid,248,'cof'); % seek ahead to next chunk
    otherwise
        keyboard;
        warning([mfilename ': skipping unknown chunk ' chunk.ID]);
    end
    
    chunk = readStructFromFile(CHUNK_HEAD,fid,1);

end
fprintf(' complete!\n');

fclose(fid);

% parse out trials

event = struct('ID',[],'Size',[],'Tag',[],'TrialNumber',[],'Time',[],'Event',[]);
trials = struct('head',[],'stim',TRIAL_STIM,'events',event);

t = 0; e = 1;
for n = 1:length(data)
    switch(data{n}.ID)
    case 'TRIH'
       t = t + 1; trials(t).head = data{n}; e = 1; s = 1;
    case 'TRIE'
        if t>0
            trials(t).events(e) = data{n}; e = e + 1;
        else
            warning('Bad event outside a trial');
        end
    case 'TRIS'
        trials(t).stim(s) = data{n}; s = s + 1;
    case 'RFIN'
        trials(t).stimInfo = data{n};
    end
end


for n=1:length(trials)
    tmp = parseStimInfo([trials(n).stim(:).Info]);
    if length(tmp)>0 & ~isempty(tmp{1}.Name)
        trials(n).stim = struct(tmp{1}.Name,tmp{1});
    elseif length(tmp)>1 & ~isempty(tmp{2}.Name)
        trials(n).stim = struct(tmp{2}.Name,tmp{2});
    end
    for s = 2:length(tmp)
        if ~isempty(tmp{s}.Name)
            trials(n).stim = setfield(trials(n).stim,tmp{s}.Name,tmp{s});
        end
    end
end

header.TotalTrials = length(trials);