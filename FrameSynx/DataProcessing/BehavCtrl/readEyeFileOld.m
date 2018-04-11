function [header,trials] = readEyeFile(fileName,varargin)

Val_MatFormat = 3;
list = -1;
for n = 1:2:length(varargin)
    switch varargin{n}
    case 'Val_MatFormat'
        Val_MatFormat = varargin{n+1};
    case 'list'
        list = varargin{n+1};
    end
end

CHUNK_HEAD = struct(...
    'ID','char[4]',...
    'Size','ulong');

% typedef struct tagEYE_FILE_HEADER
% {
% 	char	ID[4];					//"EYEH" - EYE Header
% 	ULONG	Size;					//size of the header = 256 bytes
% 	char	Tag[4];					//01 01 the version info
% 	char	DateTimeRecorded[24];	//02 07 the date and time the file was made
% 	char	ThisFileName[16];		//03 11 the name of the original file
% 	char	BehavDataFileName[16];	//04 15 the name of the associated behav log file
% 	char	ExperimentName[4];		//05 16 the name of the experiment
% 	ULONG	TotalTrials;			//06 17 the total number of trials collected
% 	char	Comments[188];			//07 64
% } EYE_FILE_HEADER;

EYE_FILE_HEADER = struct(...
    'ID','char[4]',...
    'Size','ulong',...
    'Tag','char[4]',...
    'DateTimeRecorded','char[24]',...
    'ThisFileName','char[16]',...
    'BehavDataFileName','char[16]',...
    'ExperimentName','char[4]',...
    'TotalTrials','ulong',...
    'Comments','char[188]');
 
% typedef struct tagEYE_TRIAL_HEADER
% {
% 	char	ID[4];					//"EYET" - EYE Trial header
% 	ULONG	Size;					//size of eye header = 256 bytes
% 	char	Tag[4];					//01 01
% 	ULONG	TrialNumber;			//02 02 number of the trial for which the data was recorded
% 	ULONG	TotalPoints;			//03 03 number of eye data points to follow
% 	char	Comments[244];			//04 64
% } EYE_TRIAL_HEADER;

EYE_TRIAL_HEADER = struct(...
    'ID','char[4]',...
    'Size','ulong',...
    'Tag','char[4]',...
    'TrialNumber','ulong',...
    'TotalPoints','ulong',...
    'Comments','char[244]');
    
% typedef struct tagEYE_DATA
% {
% 	char	ID[4];					//"EYED" - EYE Data for a trial
% 	ULONG	Size;					// size of eye data point = 32 bytes
% 	char	Tag[4];					//01 01
% 	double	X;						//02 03 eye x position
% 	double	Y;						//03 05 eye y position
% 	double	T;						//04 07 time of collection
% 	char	Extra[4];				//05 08
% } EYE_DATA;

EYE_DATA = struct(...
    'ID','char[4]',...
    'Size','ulong',...
    'Tag','char[4]',...
    'Length','ulong',...
    'Extra','char[24]');

if Val_MatFormat<2
    EYE_POINT = struct(...
        'X','double',...
        'Y','double',...
        'T','double');
else
    EYE_POINT = struct(...
        'X','double',...
        'Y','double',...
        'R','double',...
        'T','double');
end

if nargin<1
    [fileName,path] = uigetfile('*.eye');
else
    path = '';
end

fid = fopen([path fileName]);

data = {};
pos = 1;

header = readStructFromFile(EYE_FILE_HEADER,fid,0);
data{pos} = header;
nTrials = header.TotalTrials;
fprintf('%s: %s contains %i trials\n',mfilename,fileName,nTrials);

% keyboard;

if nargin<2
    list = -1;
end

skip = 0; last = 0;

fprintf('\t progress: %03i',0);
chunk = readStructFromFile(CHUNK_HEAD,fid,1);
trial = 0;

ID = cell(1,length(data));

while ~isempty(chunk.ID)
    pos = pos + 1;
    
%     keyboard;

    switch chunk.ID
    case 'EYET' % trial header
        data{pos} = readStructFromFile(EYE_TRIAL_HEADER,fid,0);
        ID{pos} = data{pos}.ID;
        if ~isempty(find(list==data{pos}.TrialNumber)) | (list==-1)
            %disp(['Read Trial: ' num2str(data{pos}.TrialNumber)]);
            trial = trial + 1;
            fprintf('\b\b\b%03i',round(100*trial/nTrials));
            skip = 0;
            if data{pos}.TrialNumber==max(list)
                last = 1;
            end
        else
            disp(['Skipping Trial: ' num2str(data{pos}.TrialNumber)]);
            skip = 1;
        end
    case 'EYED' % eye data
        tmp = readStructFromFile(EYE_DATA,fid,0);
        if skip
            % fast forward the file
            if tmp.Length>0
                fseek(fid,24*tmp.Length,'cof');
            end
            pos = pos - 1;
        elseif tmp.Length>0
            data{pos} = tmp;
            ID{pos} = data{pos}.ID;
            data{pos}.points = repmat(EYE_POINT,1,data{pos}.Length);
            if data{pos}.Length>0
                for n = 1:data{pos}.Length
                    data{pos}.points(n) = readStructFromFile(EYE_POINT,fid,0);
                end
            end
            if last
                break; break;
            end
        else
            pos = pos - 1;
        end
    otherwise
        keyboard;
        warning([mfilename ': skipping unknown chunk ' chunk.ID]);
    end
    
    chunk = readStructFromFile(CHUNK_HEAD,fid,1);
    
end
fprintf(' complete!\n');
fclose(fid);

% parse out trials
tmp = EYE_DATA;
tmp.points = [];

trials = struct('head',[],'data',tmp);

%////////////////

keyboard;

t = 0;
for n = 1:length(data)
    switch ID{n}
    case 'EYET'
        t = t + 1; trials(t).head = data{n}; d = 1; 
    case 'EYED'
        if t == 0
            warning([mfilename ': data point before first trial']);
        else
            trials(t).data(d) = data{n}; d = d + 1;
        end
    end    
end
 %//////////////////////////////////////////////


%  t = 0; d = 1;
% for n = 1:length(data)
%     switch(data{n}.ID)
%     case 'EYEH'
%        t = t + 1; trials(t).head = data{n}; d = 1; s = 1;
%     case 'EYED'
%         if t>0
%             trials(t).data(d) = data{n}; d = d + 1;
%         else
%             warning('Bad event outside a trial');
%         end
%     case 'EYES'
%         trials(t).stim(s) = data{n}; s = s + 1;
%         %case 'RFIN'
%       %  trials(t).stimInfo = data{n};
%     end
% end
