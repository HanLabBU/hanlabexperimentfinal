classdef Experiment < hgsetget & dynamicprops
		
		
		
		
		
		
		properties % Data Files
				experimentName
				videoFile
				behaviorFile
				processedDataPath
		end
		properties % (SetAccess = protected)
				trialSet
				dataFields
				traceFields
		end
		properties % Experiment Header Info from Video-File
				numFrames
				firstFrame
				lastFrame
				startTime
				stopTime
				resolution
		end
		properties % Experiment Summary from Behavior-File
				channels
				channelLabels
				stimNumbers
		end	
		properties %TS: TRIAL-SEQUENCED
				numFramesTS
				firstFrameTS
				lastFrameTS
				startTimeTS
				stimStartTS
				stimStopTS
				stimShiftTS
				stimLengthTS
				stimNumberTS
				trialNumberTS
				outcomeTS
		end
		properties % FS: FRAME-SEQUENCED
				frameNumberFS
				channelFS
				frameTimeFS
				trialNumberFS
				stimStatusFS
				stimNumberFS
		end
		properties (SetAccess = protected) % Working Variables and Storage
				videoFileInfo
				behaviorFileInfo
				frameDecimationSequence
				frameDecimationStartFrame
				frameDecimationMatMap
		end
		properties % Data References
				tracePropMetaHandles
				dataPropMetaHandles
				dataPropMemMapFiles
				dataPropMemMapFileNames
				dataPropMemMapFileProps
		end
		properties % BehavCtrl File Data
				behavCtrlWasUsed
				behavCtrlBhvFile
				behavCtrlEyeFile
				behavCtrlBhvFileEvents
				behavCtrlEyeFileData
		end
		properties % Settings
				setting
				filepaths
		end
		
		
		
		
		
		
		
		methods % CONSTRUCTOR
				function obj = Experiment(varargin)
						if nargin > 1
								for k = 1:2:length(varargin)
										obj.(varargin{k}) = varargin{k+1};
								end
						end
						obj.defineSettings();
				end
				function defineSettings(obj)
						obj.setting.creationMode = 'manual';
						obj.setting.channelOptions =  {
								'i','infrared';...
								'f','farinfrared';...
								'n','nearinfrared';...
								'r','red';...
								'o','orange';...
								'y','yellow';...
								'g','green';...
								'b','blue';...
								'u','ultraviolet'};
						obj.setting.addSequenceRepeats = true;
						obj.setting.nFramesPreTrigger = 15;
						obj.setting.nFramesPostTrigger = 45;
						obj.setting.stimLengthMinFrames = [];
						obj.setting.trialLengthMinFrames = [];
				end
				function setPath(obj)
						fpath3 = obj.experimentName;
						if isempty(fpath3)
								fpath3 = datestr(now,'HHMM');
						end
						fpath2 = sprintf('Processed_Data_%s',datestr(now,'yyyy_mmmdd'));
						fpath1 = 'Z:\Processed Data';
						fpath = fullfile(fpath1,fpath2,fpath3);
						if ~isdir(fpath)
								[success,message] = mkdir(fpath);
								if ~success
										warning(message)
										fpath = uigetdir(userpath,'Browse for Processed Data Folder');
								end
						end
						obj.processedDataPath = fpath;
						fprintf('Processed data will be saved to: %s\n',fpath);
				end
		end
		methods % DATA IMPORT SUBFUNCTIONS
				function makeTrialSet(obj)
						% Work Through Sequenced/MultiChannel Trial Info
						stimstarts = find(diff(obj.stimStatusFS) == 1) + 1;
						stimshifts = find(diff(obj.stimStatusFS) == 2) + 1;
						stimstops = find(diff(obj.stimStatusFS) < 0) + 1;
						stimstarts = stimstarts(stimstarts<stimstops(end));
						stimshifts = stimshifts(stimshifts<stimstops(end));
						ntrials = length(obj.trialNumberTS);
						obj.stimLengthTS = NaN(ntrials,1);
						obj.stimNumberTS = NaN(ntrials,1);
						obj.stimStartTS = NaN(ntrials,1);
						obj.stimShiftTS = NaN(ntrials,1);
						obj.stimStopTS = NaN(ntrials,1);
						if ~isempty(stimstarts)
								stimstart_trials = obj.frames2TrialNumbers(stimstarts);
								obj.stimLengthTS(stimstart_trials) = stimstops-stimstarts;
								obj.stimNumberTS(stimstart_trials) = obj.stimNumberFS(stimstarts);
								obj.stimStartTS(stimstart_trials) = stimstarts;
								obj.stimStopTS(stimstart_trials) = stimstops;
						end
						if ~isempty(stimshifts)
								stimshift_trials = obj.frames2TrialNumbers(stimshifts);
								obj.stimShiftTS(stimshift_trials) = stimshifts;
						end
						% Clear Previous Trial-Sets
						if ~isempty(obj.trialSet)
								delete(obj.trialSet);
						end
						obj.trialSet = Trial.empty(0,1);
						if ~obj.behavCtrlWasUsed || isempty(obj.outcomeTS)
								% Determine Minimum Settings for Trial-Outcome
								[~,i1,~] = unique(obj.trialNumberFS,'first'); % i1 = obj.firstFrameTS;
								[~,i2,~] = unique(obj.trialNumberFS,'last'); % i2 = obj.lastFrameTS
								nframesvec = i2-i1;
								if ~isempty(obj.setting.stimLengthMinFrames)
										stim_length_min = obj.setting.stimLengthMinFrames;
								else
										stim_length_min = mode(obj.stimLengthTS)-1; % (1-frame tolerance)
								end
								if ~isempty(obj.setting.trialLengthMinFrames)
										trial_length_min = obj.setting.trialLengthMinFrames;
								else
										trial_length_min = max(mode(nframesvec)-1, stim_length_min); % (1-frame tolerance)
								end
								fprintf('Stimulus Length Minimum: %i frames\n',stim_length_min)
								fprintf('Trial Length Minimum: %i frames\n',trial_length_min)
						end
						% Calculate Property Values for All Trials in Set
						for n=1:ntrials
								frx = obj.trialNumberFS == obj.trialNumberTS(n); % Frames belonging to current trial
								sftrial = Trial(...
										'trialNumber',obj.trialNumberTS(n),...
										'frameNumberFS',find(frx),...
										'channelFS',obj.channelFS(:,find(frx)),...
										'frameTimeFS',obj.frameTimeFS(frx),...
										'stimStatusFS',obj.stimStatusFS(frx),...
										'stimNumberFS',obj.stimNumberFS(frx));
								sftrial.stimNumber = mode(sftrial.stimNumberFS(~isnan(sftrial.stimNumberFS)));
								sftrial.numFrames = numel(sftrial.frameNumberFS);
								sftrial.firstFrame = obj.firstFrameTS(n); % or sftrial.frameNumberF(1)
								sftrial.lastFrame = obj.lastFrameTS(n); % or sftrial.frameNumberF(end)
								sftrial.startTime = obj.startTimeTS(n); % or sftrial.frameTimeF(1)
								% Determine Trial Outcome
								if isempty(obj.outcomeTS)
										% Determine based on estimate
										trial_condition = false; stim_condition = false;
										if sftrial.numFrames >= trial_length_min
												trial_condition = true;
										end
										if sum(logical(sftrial.stimStatusFS)) >= stim_length_min
												stim_condition = true;
										end
								else
										% Determing based on outcome info from BehavCtrl
										trial_condition = obj.outcomeTS(n);
										stim_condition = ~isnan(sftrial.stimNumber);
								end
								if  trial_condition && stim_condition
										sftrial.outcome = 'Complete Stim';
								elseif trial_condition && ~stim_condition
										sftrial.outcome = 'Complete Blank';
								else
										sftrial.outcome = 'Incomplete';
								end
								obj.trialSet(n) = sftrial;
						end
				end
				function mapData(obj,propname,memmapInput)
						switch class(memmapInput)
								case 'memmapfile'
										% Copy Properties from Input memmapfile (memmapInput)
										fname = memmapInput.Filename;
										fileProps = properties(memmapInput);
										fileProps = fileProps(~strcmp(fileProps,'filename'))';
										for n = 1:length(fileProps)
												fileProps{2,n} = memmapInput.(fileProps{1,n});
										end
								case 'struct'
										fname = memmapInput.fname;
										fileProps = memmapInput.fileProps;
						end
						obj.dataPropMemMapFileNames.(propname) = fname;
						obj.dataPropMemMapFileProps.(propname) = fileProps;
						% Create New Memory-Map Object
						obj.dataPropMemMapFiles.(propname) = memmapfile(fname, fileProps{:});
						try
								obj.(propname) = reshape(obj.dataPropMemMapFiles.(propname).Data,...
										obj.resolution(1),obj.resolution(2),1,[]);
						catch me
								fclose('all');
								if strcmpi(class(memmapInput),'memmapfile')
										obj.(propname) = reshape(obj.memmapInput.Data,...
												obj.resolution(1),obj.resolution(2),1,[]);
								end
						end
				end
				function addTrace(obj,propname,tracedata)
						try
								obj.(propname) = tracedata;
						catch me
								me.stack(1)
								keyboard
						end
								
				end
				function linkTrials(obj)
						if isempty(obj.trialSet)
								obj.makeTrialSet();
						end
						ntrials = numel(obj.trialSet);
						for n = 1:ntrials
								obj.trialSet(n).experimentObj = obj;
								if n>1
										obj.trialSet(n).previousTrial = obj.trialSet(n-1);
								end
								if n<ntrials
										obj.trialSet(n).nextTrial = obj.trialSet(n+1);
								end
						end
				end
		end
		methods % UTILITY FUNCTIONS
				function nc = numChannels(obj)
						nc = numel(obj.channelLabels);
				end
				function trialNumbers = frames2TrialNumbers(obj,framenumbers,varargin)
						% given a short sequence of frame-numbers for some event (e.g. stimulus-on) and a vector
						% of the first frame for each trial number, this function will return the trial-numbers
						% associated with each frame
						if nargin==4
								firstframes = varargin{1};
								lastframes = varargin{2};
						else
								firstframes = obj.firstFrameTS;
								lastframes = obj.lastFrameTS;
						end
						trialNumbers = NaN(length(framenumbers),1);
						for n = 1:length(framenumbers)
								trialNumbers(n) = find(framenumbers(n)>=firstframes & framenumbers(n)<=lastframes,1,'first');							
						end
				end
		end
		methods % CLEANUP AND SAVING
				function delete(obj)
						for n = 1:numel(obj.dataFields)
								obj.(obj.dataFields{n}) = [];
								obj.dataPropMemMapFiles.(obj.dataFields{n}) = [];
						end
				end
				function obj = saveobj(obj)
						for n = 1:numel(obj.dataFields)
								obj.(obj.dataFields{n}) = [];
								obj.dataPropMemMapFiles.(obj.dataFields{n}) = [];
						end
				end
		end
		methods (Static) % LOADING
				function obj = loadobj(obj)
						newdatapath = [];
						for n = 1:numel(obj.dataFields)
								propname = obj.dataFields{n};
								% Re-Add Transient Dynamic Data Properties
								vprop = addprop(obj,propname);
								vprop.SetAccess = 'private';
								vprop.Transient = true;
								obj.dataPropMetaHandles.(propname) = vprop;
								% Confirm Processed Data Path
								if isempty(newdatapath)
										fname = obj.dataPropMemMapFileNames.(propname);
								else
										fname = fullfile(obj.processedDataPath,propname);
								end
								if ~(exist(fname,'file')==2)
										newdatapath = uigetdir(obj.processedDataPath,'Locate Processed-Data Directory');
										if isdir(newdatapath)
												obj.processedDataPath = newdatapath;
										else
												warning('Experiment:loadobj:CannotMapData',...
														'Can not map %s in %s\n',propname,newdatapath);
										end
										fname = fullfile(obj.processedDataPath,propname);
								end
								% Re-Map Memory Mapped File
								memmapStruct.fname = fname;
								memmapStruct.fileProps = obj.dataPropMemMapFileProps.(propname);
								fprintf('Mapping %s\n',propname);
								obj.mapData(propname,memmapStruct);
						end
						% Re-Connect Trials to Data in Experiment-Object and to Each Other
						obj.linkTrials();
				end
		end
		
		
		
		
		
		
		
		
end











