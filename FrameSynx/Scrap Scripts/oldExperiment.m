classdef Experiment < hgsetget & dynamicprops
		
		
		
		
		
		properties
				% Settings
				exptFilePath
				exptFileName
				exptType
				exptNotes
				
				% Frame Data
				frameSyncData
				firstTrialNumber
				
				% Trial-Set Data
				trialSet
				completeTrials
				trialSetFileNames
				
				% Processed Data
				rawTrace
				stimTriggeredAvg
		end
		properties
				nFramesPreTrigger
				nFramesPostTrigger
				channelSequence
				channels
				channelLabels
		end
		properties (Dependent, SetAccess = protected)
				% Stimulus Record and Derivatives
				stimRecord
				stimRecordNaN
				stimRecordComplex
				stimRecordIndexed
				
				stimTally
				stimTallyComplete
				stimTallyAbort
				
				stimNumbers
				numStimTypes %includes blanks
				trialLengthMinimum
				blankIndex
				incompleteTrials
				
				% Settings
				stimOnMinimum %in frames
				
				% Processed Output
				blankSubtractedAvg
		end
		properties (Dependent, Transient, SetAccess = protected, Hidden)
				relativeTrialNumber
				currentTrialNumber
				currentStimIndex %buffer trialNumber, in order presented
				nAccountedTrials
		end
		properties (Transient, SetAccess = protected, Hidden)
				% Handles
				dataGeneratorObj
				mainAx
				trialFilePath
				dataListener
				
				% Configuration Settings
				saveMethod
				
				% other
				frameSyncDataPrototype
				frameSyncPreallocTimer
		end
		
		
		
		
		
		
		
		methods % Constructor
				function obj = Experiment(varargin)
						if nargin > 1
								for k = 1:2:length(varargin)
										obj.(varargin{k}) = varargin{k+1};
								end
						end
						if isempty(obj.rawTrace)
								obj.rawTrace = [];
						end
						if isempty(obj.stimTriggeredAvg)
								obj.stimTriggeredAvg = cell(5,1);
						end
						if isempty(obj.saveMethod)
								obj.saveMethod = 'Experiment';% 'Trial' or 'Experiment'
						end
						if isempty(obj.dataGeneratorObj)
								warndlg('No DataMaker object passed to new Experiment object')
						else
								if isempty(obj.exptFilePath)
										obj.exptFilePath = obj.dataGeneratorObj.experimentFilePath;
								end
								if isempty(obj.exptFileName)
										obj.exptFileName = obj.dataGeneratorObj.experimentFileName;
								end
								if isempty(obj.firstTrialNumber)&&~isempty(obj.dataGeneratorObj.currentTrialNumber)
										obj.firstTrialNumber = obj.dataGeneratorObj.currentTrialNumber + 1;
								end
								if isempty(obj.channelSequence)
										obj.channelSequence = obj.dataGeneratorObj.channelSequence;
								end
								if isempty(obj.channels)
										obj.channels = obj.dataGeneratorObj.channels;
								end
								if isempty(obj.channelLabels)
										obj.channelLabels = obj.dataGeneratorObj.channelLabels;
								end								
								if isempty(obj.nFramesPreTrigger)
										obj.nFramesPreTrigger = obj.dataGeneratorObj.nFramesPreTrigger;
								end
								if isempty(obj.nFramesPostTrigger)
										obj.nFramesPostTrigger = obj.dataGeneratorObj.nFramesPostTrigger;
								end
								if isempty(obj.mainAx)
										obj.mainAx = obj.dataGeneratorObj.mainAx;
								end
								obj.dataListener = addlistener(obj.dataGeneratorObj,'NewData',...
										@(src,evnt)newImageDataFcn(obj,src,evnt));
						end
						obj.frameSyncDataPrototype = struct(...
								'FrameNumber',0,... 
								'AbsTime',now,...
								'HatTime',hat,...
								'Channel',{'**'},...
								'StimStatus',0,...
								'StimNum',NaN,...
								'TrialNumber',0,...
								'ValidData',false);
						% FRAMESYNC NOTES:
						% removed ExpState
						% removed StimState -> use StimStatus instead (0=off, 1=on, 2=shift, ...)
						% added     ValidData ->
						
						% Preallocate SyncFieldData
						syncfields = fields(obj.frameSyncDataPrototype);
						for n = 1:length(syncfields)
								obj.frameSyncData.(syncfields{n}) = ...
										repmat(obj.frameSyncDataPrototype.(syncfields{n}),[110000,1]);
						end
						%                   obj.montageFig = figure;
						obj.frameSyncPreallocTimer = timer(...
								'Period',60,...
								'ExecutionMode','fixedSpacing',...
								'TimerFcn',@(src,evnt)frameSyncPreallocate(obj,src,evnt));
						start(obj.frameSyncPreallocTimer)
				end
				function delete(obj)
						delete(obj.trialSet)
						stop(obj.frameSyncPreallocTimer);
						delete(obj.frameSyncPreallocTimer);
				end
				function deactivate(obj)
						delete(obj.dataListener)
						stop(obj.frameSyncPreallocTimer);
				end
		end
		
		methods % Property Get Methods
				function stimvector = get.stimRecord(obj)
						if ~isempty(obj.trialSet)
								stimvector = eval('[obj.trialSet.stimulus]');
								stimvector = stimvector(:);
						else
								stimvector = [];
						end
				end
				function complexrec = get.stimRecordComplex(obj)
						complexrec = obj.stimRecord.*obj.completeTrials ...
								+ 1i*(obj.stimRecord.*obj.incompleteTrials);
				end
				function nanrec = get.stimRecordNaN(obj)
						nanrec = obj.stimRecord;
						nanrec(obj.incompleteTrials) = nan;
				end
				function buffnumrec = get.stimRecordIndexed(obj)
						buffnumrec = zeros(size(obj.stimRecord));
						for n = 1:length(obj.stimNumbers)
								buffnumrec(obj.stimNumbers(n) == obj.stimRecord) = n;
						end
				end
				function relTrNum = get.relativeTrialNumber(obj)
						if isempty(obj.firstTrialNumber)
								if isempty(obj.currentTrialNumber)
										relTrNum = [];
								else
										relTrNum = obj.currentTrialNumber;
								end
						else
								relTrNum = obj.currentTrialNumber - obj.firstTrialNumber +1;
						end
				end
				function currTrNum = get.currentTrialNumber(obj)
						try
								tmp = obj.dataGeneratorObj.currentTrialNumber;
						catch
								tmp = obj.trialSet(end).trialNumber+1;
						end
						if isempty(tmp)
								currTrNum = 1;
						else
								currTrNum = tmp;
						end
				end
				function ntrials = get.nAccountedTrials(obj)
						ntrials = length(obj.trialSet);
				end
				function stimnums = get.stimNumbers(obj) %In order of first presented
						if ~isempty(obj.trialSet)
								%                         [Xs, sortVec] = sort(obj.adjustedStimRecord(:));
								%                         uniqVals(sortVec) = ([1; diff(Xs)] ~= 0);
								%                         stimnums = obj.adjustedStimRecord(uniqVals);
								%alternate
								[~,ix] = unique(obj.stimRecord,'first');
								stimnums = obj.stimRecord(sort(ix));
								stimnums = stimnums(~isnan(stimnums));
						else
								stimnums = [];
						end
				end
				function numstims = get.numStimTypes(obj)
						numstims = length(obj.stimNumbers);
				end
				function logindex = get.incompleteTrials(obj)
						logindex = ~obj.completeTrials;
				end
				function tally = get.stimTally(obj)
						tally = zeros(length(obj.stimNumbers),1);
						for n = 1:length(obj.stimNumbers)
								tally(n) = sum(obj.stimRecord==obj.stimNumbers(n));
						end
				end
				function tally = get.stimTallyComplete(obj)
						tally = zeros(length(obj.stimNumbers),1);
						for n = 1:length(obj.stimNumbers)
								tally(n) = sum(obj.stimRecordNaN==obj.stimNumbers(n));
						end
				end
				function tally = get.stimTallyAbort(obj)
						tally = zeros(length(obj.stimNumbers),1);
						for n = 1:length(obj.stimNumbers)
								tally(n) = sum(imag(obj.stimRecordComplex) == obj.stimNumbers(n));
						end
				end
				function buffernumber = get.currentStimIndex(obj)
						if ~isempty(obj.nAccountedTrials)
								buffernumber = obj.stimRecordIndexed(obj.nAccountedTrials);
						else % BUG: something is asking for the stimIndex early
								buffernumber = 1;%NOTE: this was recently changed (april 16)
						end
				end
				function nframes = get.stimOnMinimum(obj)
						nframes = obj.dataGeneratorObj.stimOnMinimum;
						
				end
				function nframes = get.trialLengthMinimum(obj)
						nframes = obj.dataGeneratorObj.trialLengthMinimum;
				end
				function ind = get.blankIndex(obj)
						ind = find(obj.stimNumbers==0);
				end
				function blanksub = get.blankSubtractedAvg(obj)
						if ~isempty(obj.blankIndex)...
										&& ~isempty(obj.currentStimIndex)...
										&& ~isempty(obj.stimTriggeredAvg{obj.blankIndex})...
										&& ~isempty(obj.stimTriggeredAvg{obj.currentStimIndex})
								blanksub = obj.stimTriggeredAvg{obj.currentStimIndex} ./ ...
										obj.stimTriggeredAvg{obj.blankIndex};
						else
								blanksub = [];
						end
				end
		end
		
		methods % Property Set Methods
% 				function set.frameSyncData(obj, fsdata)
% 						persistent n
% 						% 						if isempty(obj.frameSyncData)
% 						% 								obj.frameSyncData = fsdata;
% 						% 								return
% 						% 						end
% 						% 						if ~isempty(obj.frameSyncData(end).FrameNumber)
% 						% increase preallocation size of frame data array
% 						if n < 10000
% 								obj.frameSyncData = fsdata;
% 								n = n+1;
% 						else
% 								obj.frameSyncData = cat(1,fsdata,...
% 										repmat(obj.frameSyncDataPrototype,[10000 1]));
% 								n = 1;
% 						end
% 				end
		end
		
		methods % Data Processing Functions
				function newImageDataFcn(obj,src,evnt)
						addTrial(obj,...
								obj.dataGeneratorObj.previousTrialObj,...
								obj.dataGeneratorObj.currentImageData)
				end
				function addTrial(obj,trialObj,imageData)
						try
								if isempty(obj.nAccountedTrials)
										trialSetIndex = 1;
								else
										trialSetIndex = obj.nAccountedTrials + 1;
								end
								trialObj.numberInSet = trialSetIndex;
								fillTrialData(trialObj)
								addDynamicProps(trialObj)
								saveTrialObject(trialObj)
								makeTraceData(trialObj)
								shouldComputeSTA = checkTrialOutcome(trialObj);
								if shouldComputeSTA
										% 										triggeredVid = resizeVidToTrigger(trialObj);
% 										avgVidIntoBuffer(resizeVidToTrigger(trialObj))
								end
								% 								obj.nAccountedTrials = trialSetIndex;
						catch me
								beep
								warning(me.message)
								save(fullfile(obj.exptFilePath,num2str(obj.currentTrialNumber)),imageData)
						end
						function fillTrialData(trialObj)
								if ~isempty(imageData.time)
										trialObj.frameTimes = imageData.time;
								end
								obj.trialFilePath = ...
										fullfile(obj.exptFilePath,'TrialFiles',...
										[obj.exptFileName,'_',sprintf('%0.5i',trialObj.trialNumber)]);
								trialObj.experimentName = obj.exptFileName;
								trialObj.trialFilePath = obj.trialFilePath;
								% Assign Video and Sync Data to Trial Object
								syncfields = fields(obj.frameSyncData);
								trialframeslogical = obj.frameSyncData.TrialNumber == trialObj.trialNumber;
								for n = 1:length(syncfields)
										trialObj.frameSyncData.(syncfields{n}) = ...
												obj.frameSyncData.(syncfields{n})(trialframeslogical,:);
								end					
								if size(imageData.vid,3) > 1
										trialObj.video = imageData.vid(:,:,1,:); %TODO: change for multi-channel
								else
										trialObj.video = imageData.vid;
								end
						end
						function addDynamicProps(trialObj)
								for n = 1:length(obj.channelLabels)
										mprop = addprop(trialObj,sprintf('%s_video',obj.channels{n}));
										mprop.Dependent = true;
										mprop.GetMethod = @(tobj)parseChannels(tobj,obj.channelLabels{n});
								end
						end
						function saveTrialObject(trialObj)
								% Add Trial Object to Array in Experiment Class
								obj.trialSetFileNames{trialSetIndex,1} = obj.trialFilePath;
								switch lower(obj.saveMethod(1:5))
										case 'exper'
												if isempty(obj.trialSet)
														obj.trialSet = trialObj;
												else
														obj.trialSet(trialSetIndex,1) = trialObj;
												end
										case 'trial'
												save(obj.trialFilePath ,'trialObj');
								end
						end
						function makeTraceData(trialObj)
								% Process Data
								if ~isempty(obj.rawTrace)
										obj.rawTrace = [obj.rawTrace ; trialObj.trace];
								else
										obj.rawTrace = trialObj.trace;
								end
						end
						function completestim = checkTrialOutcome(trialObj)
								if ~isempty(trialObj.stimOnFrame) && ~isnan(trialObj.stimOnFrame) %not blank
										if (trialObj.stimOffFrame-trialObj.stimOnFrame) < obj.stimOnMinimum
												trialObj.outcome = 'EarlyAbort';
										else
												trialObj.outcome = 'CompleteStim';
										end
								else % no stim-trialNumber from bhvcontrol
										% 										trialObj.stimOnFrame = NaN;
										% 										trialObj.stimOffFrame = NaN;
										if trialObj.framesDuration < obj.trialLengthMinimum
												trialObj.outcome = 'NoAttempt';
										else
												trialObj.outcome = 'CompleteBlank';
										end
								end
								switch lower(trialObj.outcome)
										case 'noattempt'
												completestim = false;
												obj.completeTrials(trialSetIndex,1) = false;
												if isempty(trialObj.stimulus)
														trialObj.stimulus = NaN;
												end
										case 'earlyabort'
												completestim = false;
												obj.completeTrials(trialSetIndex,1) = false;
										case 'completeblank'
												completestim = false;
												obj.completeTrials(trialSetIndex,1) = true;
												if isempty(trialObj.stimulus)
														trialObj.stimulus = 0;
												end
										case 'completestim'
												completestim = true;
												obj.completeTrials(trialSetIndex,1) = true;
								end
						end
						function rawVidSource = resizeVidToTrigger(trialObj)
								try
										firstFrame = trialObj.firstFrame;
										stimTrigFirstFrame = trialObj.stimOnFrame - obj.nFramesPreTrigger + firstFrame;
										stimTrigLastFrame = trialObj.stimOnFrame + obj.nFramesPostTrigger + firstFrame;
										n = trialSetIndex -1; %subtracted one to get last Trial
										rawVidSource = trialObj.video;
										if stimTrigFirstFrame < 1 % First Trial, want data before start
												rawVidSource = cat(4,...
														rawVidSource(:,:,:,size(rawVidSource,4)+stimTrigFirstFrame:end),...
														rawVidSource);
												stimTrigLastFrame = stimTrigLastFrame - stimTrigFirstFrame + 1;
												stimTrigFirstFrame = 1;
										else
												while stimTrigFirstFrame < firstFrame % Want Data from a Trial before
														n = n - 1;
														rawVidSource = cat(4,obj.trialSet(n).video,rawVidSource);%concatenate with Trial before
														firstFrame = obj.trialSet(n).firstFrame;%todo: check for error in case rolling back goes past first frame
												end
										end
										rawVidSource = rawVidSource(:,:,:,...
												stimTrigFirstFrame-firstFrame+1 : ...
												stimTrigLastFrame-firstFrame);
								catch
										warning('SuperImage:Experiment:TriggeredAvgResizeError',...
												'Error resizing Trial-video to pre- and post-trigger specifications')
										rawVidSource = [];
								end
						end
						function avgVidIntoBuffer(triggeredVid)
								try
										if isempty(triggeredVid)
												warning('SuperImage:Experiment:TrigAvgError','Error averaging Trial into buffer')
												return
										end
										if size(obj.stimTriggeredAvg,1)<obj.currentStimIndex %TODO: change 1 to channelnum
												obj.stimTriggeredAvg{obj.currentStimIndex} = [];
										end
										if isempty(obj.stimTriggeredAvg{obj.currentStimIndex})
												obj.stimTriggeredAvg{obj.currentStimIndex} = double(triggeredVid);
										else
												n = obj.stimTallyComplete(obj.currentStimIndex);
												obj.stimTriggeredAvg{obj.currentStimIndex} = ...
														(n-1)/n.*obj.stimTriggeredAvg{obj.currentStimIndex} + ...
														1/n.*double(triggeredVid);
										end
								catch me
										beep
										stop(imaqfind)
										warning(me.message)
								end
						end
				end
				function stimdif = stimDifference(obj,varargin) % imaqmontage( stimDifference(TWK4,1,2))
						try
								if length(varargin)>=2
										for n=1:length(varargin)
												stimset(n) = varargin{n};
										end
								else
										stimset(1) = obj.stimNumbers(1);
										stimset(2) = obj.stimNumbers(2);
								end
								if ~isempty(obj.stimTriggeredAvg{stimset(1)}) ...
												&& ~isempty(obj.stimTriggeredAvg{stimset(2)})
										stimdif = obj.stimTriggeredAvg{obj.stimNumbers==stimset(1)} ...
												- obj.stimTriggeredAvg{obj.stimNumbers==stimset(2)};
								else
										stimdif = [];
								end
						catch me
								warning(me.message)
						end
				end
				function stimdif = stimRatio(obj,varargin) % imaqmontage( stimDifference(TWK4,1,2))
						try
								if length(varargin)>=2
										for n=1:length(varargin)
												stimset(n) = varargin{n};
										end
								else
										stimset(1) = obj.stimNumbers(1);
										stimset(2) = obj.stimNumbers(2);
								end
								if ~isempty(obj.stimTriggeredAvg{stimset(1)}) ...
												&& ~isempty(obj.stimTriggeredAvg{stimset(2)})
										stimdif = obj.stimTriggeredAvg{obj.stimNumbers==stimset(1)} ...
												./ obj.stimTriggeredAvg{obj.stimNumbers==stimset(2)};
								else
										stimdif = [];
								end
						catch me
								warning(me.message)
						end
				end
				function frameSyncPreallocate(obj,src,evnt)
						if sum(obj.frameSyncData.ValidData) > length(obj.frameSyncData.ValidData)-1000
								syncfields = fields(obj.frameSyncData);
								for n = 1:length(syncfields)
										obj.frameSyncData.(syncfields{n}) = cat(1, ...
												obj.frameSyncData.(syncfields{n}), ... 
												repmat(obj.frameSyncDataPrototype.(syncfields{n}),[1000,1]));
								end
						end
				end
				function trimSyncData(obj)						
						syncfields = fields(obj.frameSyncData);
						for n = 1:length(syncfields)
								obj.frameSyncData.(syncfields{n}) = ...
										obj.frameSyncData.(syncfields{n})(obj.frameSyncData.ValidData,:);
						end
				end
		end
		
		
		
		
		
		
		
		
end





