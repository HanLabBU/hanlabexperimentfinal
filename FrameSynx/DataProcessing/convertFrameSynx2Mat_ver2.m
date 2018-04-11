function convertFrameSynx2Mat_ver2(varargin)
% ------------------------------------------------------------------------------------------------
% convertFrameSynx2Mat()
% July 22, 2010
% Mariana Cardoso & Mark Bucklin
%
% This function is used to convert from 'DataFiles' generated by Mark Bucklin's MATLAB image
% acquisition software (a.k.a. FramesynX) to 'legacy' Mat Files, with a format that is compatible
% with GetFileInfo(). Input can be the experiment directory alone, or any other field of the
% 'setting' structure defined below in property-value pairs.
%
% EXAMPLES:
% >> convertFrameSynx2Mat()
% >> convertFrameSynx2Mat('Z:\YODA\YODA_2010_07_20\YOD6')
% >> convertFrameSynx2Mat('experimentDirectory','Z:\YODA\YODA_2010_07_20\YOD6')
% >> convertFrameSynx2Mat('runGetFileInfo',false,'exportRoot','Z:\')
% >> convertFrameSynx2Mat('dataProcessingFcn',@(data)spatialBinData(data,4))
% ------------------------------------------------------------------------------------------------
tic




% ------------------------------------------------------------------------------------------------
% DEFAULTS
% ------------------------------------------------------------------------------------------------
setting.exportRoot = '\\enigma\BigDas2\';
setting.experimentDirectory = pwd;
setting.runGetFileInfo = false;
setting.dataProcessingFcn = [];

% ------------------------------------------------------------------------------------------------
% LOAD FILES
% ------------------------------------------------------------------------------------------------
% Go to Directory if Not Specified
if nargin == 1
		setting.experimentDirectory = varargin{1};
end
if nargin>1
		for n = 1:2:nargin
				setting.(varargin{n}) = varargin{n+1};
		end
end
if ~isdir(setting.experimentDirectory)
		setting.experimentDirectory = uigetdir(pwd,'Go to experiment');
end
cd(setting.experimentDirectory);

% Concatenate Data Files
dataSetFileNames = concatenateDataFileSets();

% Open Data Sets
for n=1:numel(dataSetFileNames)
		load(dataSetFileNames{n}); % puts 'vidfiles' and 'behfiles' in workspace
end


% ------------------------------------------------------------------------------------------------
% EXTRACT INFORMATION AND DATA
% ------------------------------------------------------------------------------------------------
% Get Info Structures from Files
fprintf('Retrieving VideoFile info structures...\n');
info.video.trial = getInfo(vidfiles);
info.video.all = getInfo(vidfiles,'cat');
fprintf('Retrieving BehaviorFile info structures...\n');
info.behav.trial = getInfo(behfiles);
info.behav.all = getInfo(behfiles,'cat');

% Get Basic Info from DataFile Headers
nTrials = min(numel(behfiles),numel(vidfiles));
nChannels = sum(~isspace(vidfiles(1).channels));
nFrames = sum([vidfiles.numFrames]);
experimentName = behfiles(nTrials).experimentName;
trialNumbers = [behfiles.trialNumber];
trialNumbers(1) = trialNumbers(2) - 1;% (bugfix: deal with first trial number = 0)
firstTrialNumber = trialNumbers(1);

% Choose a Path to Export To
[~,oldpath] = strtok(behfiles(nTrials).rootPath,filesep);
exportedDataPath = fullfile(setting.exportRoot,oldpath,'Unshifted');
if ~isdir(exportedDataPath)
		mkdir(exportedDataPath)
		% e.g. \\enigma\BigDas2\YODA\YODA_2010_07_20\YOD2\Unshifted
end


% keyboard
% Determing the Framer Labels, Pattern and Order

% Introduce an Illumination Sequence
answer = inputdlg({'Enter the Correct Illumination Sequence:', 'Enter number to assign to wavelength'},...
								'Manual Illumination Sequence', 1, {'rggr', '1221'});
illumination_sequence =  answer{1};
labelPattern = str2num(answer{2}')';
clear answer;

temp_data = getData(vidfiles(1), 1:16);
channelset = repmat (illumination_sequence, [1, 16/round(length(illumination_sequence))]);

doing_alignment = true;
while doing_alignment == true
		% clear channelset_aux;
		imaqmontage(temp_data);
		aux_nframes = size(temp_data,4);
		nrows = ceil(sqrt(aux_nframes));
		ncols = floor(sqrt(aux_nframes));
		imres = size(temp_data,1);
		nframe = 1;
		for row = 1:nrows
				for col = 1:ncols
						if nframe > aux_nframes
								break
						end
						switch char(channelset(nframe))
								case 'r'
										textcol = [.8 0 0];
								case 'g'
										textcol = [0 .6 0];
								case 'b'
										textcol = [0 0 .8];
								otherwise
										textcol = [1 1 1];
						end
						text(imres*col-imres/8 , imres*row-imres/8 ,...
								upper(char(channelset(nframe))),...
								'FontSize',16,...
								'Color',textcol);
						nframe = nframe+1;
				end
		end
			
		% Query User and Shift if Necessary
		answer = questdlg('Are the frame labels correctly aligned?',...
				'Illumination Sequence Alignment','Yes','Shift Left','Shift Right','Yes');
		switch lower(answer)
				case 'shift left'
						channelset = circshift(channelset',-1)';
						illumination_sequence = circshift(illumination_sequence',-1)';
						labelPattern = circshift(labelPattern',-1)';
						clf
				case 'shift right'
						channelset = circshift(channelset',1)';
						illumination_sequence = circshift(illumination_sequence',1)';
						labelPattern = circshift(labelPattern',1)';
						clf
				case 'yes'
						close
						close
						doing_alignment = false;
		end
end
clear temp_data doing_alignment

frameLabels = repmat(labelPattern,1,ceil(nFrames/4));
frameLabels = frameLabels(1:nFrames);
if frameLabels(1) ~=frameLabels(2)
		frameLabels = frameLabels(2:end);
		nFrames = nFrames-1;
		firstFrame2Bin = 2;
else
		firstFrame2Bin = 1;
end
nFrames2Bin = floor(nFrames/8)*8;
% index = firstFrame2Bin : 4 : nFrames2Bin+firstFrame2Bin-1;
index = firstFrame2Bin : 4 : nFrames2Bin;

% ------------------------------------------------------------------------------------------------
% CREATE SYNCH FILES
% ------------------------------------------------------------------------------------------------
% Create Blank Synch-File Output Structure
SynchOutputPrototype = struct(...
		'fileSequence',struct('name',[],'first_frame',[],'last_frame',[]),...
		'frameArrivalTime',[],...
		'frameMean',[],...
		'frameSynch',[]);
SynchOutput = repmat(SynchOutputPrototype,nChannels,1);

% Fill in Synch Structure
for channum = 1:nChannels
		SynchOutput(channum) = SynchOutputPrototype;
		
		
% 		keyboard
		
		% Frame Arrival Time - time since start in msec
		SynchOutput(channum).frameArrivalTime = info.video.all.FrameTime(index+2) * 1000;
		
		% Frame Synch 5xN array with UDP Messages from BehavCtrl
		% FORMAT:
		% [ 0 ; StimState ; ExptState ; TrialNumber ; 0 ]
		% Stim State
		
		
		stimstate = zeros(floor(nFrames2Bin/4),1);
% 		condition_stim_on_1 = (info.behav.all.StimStatus(index+0) == 1 & isnan(info.behav.all.StimNumber((index+0))));
% 		condition_stim_on_2 = (info.behav.all.StimStatus(index+1) == 1 & ~isnan(info.behav.all.StimNumber((index+1))));
% 		condition_stim_on_3 = (info.behav.all.StimStatus(index+2) == 1 & isnan(info.behav.all.StimNumber((index+1))));
% 		condition_stim_on_4 = (info.behav.all.StimStatus(index+3) == 1 & ~isnan(info.behav.all.StimNumber((index+3))));
		
		stimstate(info.behav.all.StimStatus(index+2) == 1 & isnan(info.behav.all.StimNumber((index+2)))) = 100001; % Stim-On
		stimstate(info.behav.all.StimStatus(index+2) == 2) = 100002; % Stim-Shift
		stimstate(info.behav.all.StimStatus(index+2) == 0) = 100003; % Stim-Off
		stimNumbers = unique(info.behav.all.StimNumber(~isnan(info.behav.all.StimNumber)));
		for sn = stimNumbers(:)'
				code = 100003 + sn;
				stimstate(info.behav.all.StimNumber(index) == sn) = code; % Stim-Number
		end
		% Experiment State
		expstate = repmat(2002,[floor(nFrames2Bin/4),1]); % always unpaused
		% Trial Number
		trialnumber = info.behav.all.TrialNumber(index+2);
		% Put all together in frameSynch matrix
		SynchOutput(channum).frameSynch = [zeros(nFrames2Bin/4,1), stimstate(:), expstate(:), trialnumber(:), zeros(nFrames2Bin/4,1)]';
		
		% File Sequence = trial by trial info
		firstFrames = [1 ; find(diff(trialnumber)>0)+1];
		lastFrames = [firstFrames(2:end)-1 ; nFrames2Bin/4];
		for filenum = 1:nTrials
				a.name = sprintf('%s_%i_%0.5i_%0.5i.mat', ...
						experimentName, channum, trialNumbers(1), trialNumbers(filenum));
				a.first_frame = firstFrames(filenum);
				a.last_frame = lastFrames(filenum);
				SynchOutput(channum).fileSequence(filenum,1) = a;
		end
		
		% Save Synch File
		synchFileName{channum} = sprintf('%s_%i_%0.5i_%0.5i_SYNCH.mat', ...
				experimentName, channum, firstTrialNumber, firstTrialNumber);
		fname = fullfile(exportedDataPath,synchFileName{channum});
		fprintf('Saving SYNCH File: %s\n',fname);
		struct2save = SynchOutput(channum);
		save(fname,'-struct','struct2save')
end



% ------------------------------------------------------------------------------------------------
% CREATE MAT FILES
% ------------------------------------------------------------------------------------------------
MatFilePrototype = struct(...
		'first_image',[],...
		'images',[],...
		'soft',struct('XSize',[],'YSize',[]));

% Extract Data and Bin Frames
[leftoverData,tmp] = getData(vidfiles(1));
leftoverFrameNumbers = tmp.FrameNumber;

% leftoverData = leftoverData(:,:,:,2:end);
leftoverFrameNumbers = leftoverFrameNumbers(2:end);




clear tmp
firstDataFrameNumber = leftoverFrameNumbers(1);
binnedData = cell.empty;
frameMean = NaN(lastFrames(end),2);

for n = 1:nTrials
		% Get Data for Next Trial (Current Trial Data is in 'Leftovers')
		firstFrame2Bin4ThisTrial = index(firstFrames(n))+firstDataFrameNumber-1;
		lastFrame2Bin4ThisTrial = index(lastFrames(n))+3+firstDataFrameNumber-1;
		if n == nTrials
				rawData = double(leftoverData);
				rawFrameNumbers = leftoverFrameNumbers;
		else
				rawData = double(cat(4, leftoverData, getData(vidfiles(n+1))));
				tmp = getInfo(vidfiles(n+1));
				rawFrameNumbers = cat(1,leftoverFrameNumbers(:),tmp.FrameNumber(:));
		end
		
		rawFrameIndex = rawFrameNumbers - rawFrameNumbers(1) + 1;
		rawDataIndex = rawFrameIndex(...
				rawFrameNumbers>=firstFrame2Bin4ThisTrial...
				& rawFrameNumbers<=lastFrame2Bin4ThisTrial);
		
		% Temporal Binning Step! Add Consecutive Frames & Separate the Wavelengths
		binnedData{frameLabels(firstFrame2Bin)} = double(rawData(:,:,:,rawDataIndex(1):4:rawDataIndex(end)))/2 ...
				+ double(rawData(:,:,:,rawDataIndex(2):4:rawDataIndex(end)))/2;
		binnedData{frameLabels(firstFrame2Bin+2)} = double(rawData(:,:,:,rawDataIndex(3):4:rawDataIndex(end)))/2 ...
				+ double(rawData(:,:,:,rawDataIndex(4):4:rawDataIndex(end)))/2;
				
		% Keep Leftovers
		leftoverData = double(rawData(:,:,:,rawDataIndex(end)+1:end));
		leftoverFrameNumbers = rawFrameNumbers(rawFrameIndex(rawDataIndex(end)+1:end));
		
		% Fill Binned Data in MatFile Structures
		for channum = 1:nChannels
				
				data = binnedData{channum};
				%	data = double(binnedData{channum}); % Redundant

				
				% Process Data if a dataProcessingFcn is Specified (e.g. spatialBinData)
				if ~isempty(setting.dataProcessingFcn)
						try
								switch class(setting.dataProcessingFcn)
										case 'char'
												eval(setting.dataProcessingFcn)
										case 'function_handle'
												data = feval(setting.dataProcessingFcn,data); % example data size 256x256x1x347
										case 'cell'
												switch class(setting.dataProcessingFcn{1})
														case 'function_handle'
																data = feval(setting.dataProcessingFcn{1},data,setting.dataProcessingFcn{2:end});
														case 'char'
																for nFcn = 1:numel(setting.dataProcessingFcn)
																		eval(setting.dataProcessingFcn{nFcn});
																end
												end
								end
						catch
								fprintf('frameDataCallbackFcn Error\n');
						end
				end
				
				% Fill Structure
				MatFile = MatFilePrototype;
				MatFile.images = reshape(data,size(data,1)*size(data,2),[]);
				MatFile.first_image = MatFile.images(:,1);
				MatFile.soft.XSize = size(data,1);
				MatFile.soft.YSize = size(data,2);
				
				% Save Structures to Files
				fname = fullfile(exportedDataPath, SynchOutput(channum).fileSequence(n).name);
				fprintf('Saving: %s\n',fname);
				save(fname,'-struct','MatFile')
				
				% Calculate Mean Pixel Intensity and Save with SYNCH file
				frameMean(firstFrames(n):lastFrames(n),channum) = mean(MatFile.images,1);
		end
end

for channum = 1:nChannels
		SynchOutput(channum).frameMean = frameMean(:,channum);
		fname = fullfile(exportedDataPath,synchFileName{channum});
		fprintf('Adding Frame-Mean to SYNCH File: %s\n',fname);
		struct2save = SynchOutput(channum);
		save(fname,'-struct','struct2save')
end



% ------------------------------------------------------------------------------------------------
% RUN GETFILEINFO IF SPECIFIED
% ------------------------------------------------------------------------------------------------








fprintf('Conversion complete in %0.1f seconds\n',toc)






