classdef DataProcessor < hgsetget & dynamicprops
		
		
		
		
		
		
		properties % Data Files
				experimentName
				videoFile
				behaviorFile
				processedDataPath
				exportedDataPath
		end
		properties % (SetAccess = protected)
				trialSet
				experimentObj
				dataFields
				traceFields
				resolution
		end
		properties (Dependent, SetAccess = protected) % Experiment Header Info from Video-File
				numFrames
				firstFrame
				lastFrame
				startTime
				stopTime
		end
		properties (Dependent, SetAccess = protected) % Experiment Summary from Behavior-File
				channels
				channelLabels
				stimNumbers
				trialNumberT
		end
		% HIDDEN PROPERTIES
		properties (SetAccess = protected)%, Hidden) % Trial Header Info from Video-File
				numFramesT
				firstFrameT
				lastFrameT
				startTimeT
				outcomeT
		end
		properties (SetAccess = protected)%, Hidden) % Concatenated Frame Info
				frameNumberF
				channelF
				frameTimeF
				absTimeF
				trialNumberF
				stimStatusF
				stimNumberF
		end
		properties % FS: Frame-Sequenced Info (Multi-Channel)
				frameNumberFS
				channelFS
				frameTimeFS
				trialNumberFS
				stimStatusFS
				stimNumberFS
		end
		properties %TS:Trial-Sequenced Info (Multi-Channel)
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
		properties (SetAccess = protected) % Working Variables and Storage
				videoFileInfo
				behaviorFileInfo
				missingVideoFileFrames
				missingBehaviorFileFrames
				maxCommonFrame
				mislabeledZeroFrames
				mislabeledSpaceFrames
				estimatedSequenceLength
				estimatedSequenceStrength
				singleChannelTrialSet
				illuminationSequence
				frameDecimationSequence
				frameDecimationStartFrame
				frameDecimationMatMap
				metaDynamicPropHandles
				videoMemoryObj
				savedSynchFiles
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
				pathIsSet
				usePreviouslyProcessedData
		end
		
		
		
		
		
		
		
		methods % CONSTRUCTOR
				function obj = DataProcessor(varargin)
						if nargin > 1
								for k = 1:2:length(varargin)
										obj.(varargin{k}) = varargin{k+1};
								end
						end
						% Settings
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
								'u','ultraviolet';...
								'x','mono'};
						obj.setting.addSequenceRepeats = true;
						obj.setting.nFramesPreTrigger = 15;
						obj.setting.nFramesPostTrigger = 45;
						obj.setting.stimLengthMinFrames = [];
						obj.setting.trialLengthMinFrames = [];
						obj.setting.behaviorEventAlignment = 'BehavCtrl';
						obj.setting.Val_MatFormat = 5;
						obj.setting.imageShiftingMethod = 'BergenLK'; % ECC, BergenLK
						obj.setting.readEyeFile = false;
						obj.pathIsSet = false;
						obj.usePreviouslyProcessedData = false;
						% Setup
						if isempty(obj.videoFile) ...
										|| isempty(obj.behaviorFile) ...
										|| isempty(obj.behavCtrlBhvFile)
								% 										|| isempty(obj.behavCtrlEyeFile)
								obj.loadFiles();
						end
						obj.readFiles();
						% Examine and Fix Channel Issues (zeroes -> spaces)
						if any(~isletter(obj.channelF))
								obj.fixChannelLabels();
						end
						% Fix Frame-Assignment to Accomodate Multi-Wavelength Sequences
						if ~obj.ismultichannel
								obj.trialSet = obj.singleChannelTrialSet;
								obj.frameNumberFS = obj.frameNumberF;
								obj.channelFS = obj.channelF;
								obj.frameTimeFS = obj.frameTimeF;
								obj.trialNumberFS = obj.trialNumberF;
								obj.stimStatusFS = obj.stimStatusF;
								obj.stimNumberFS = obj.stimNumberF;
								obj.numFramesTS = obj.numFramesT;
								obj.firstFrameTS = obj.firstFrameT;
								obj.lastFrameTS = obj.lastFrameT;
								obj.startTimeTS = obj.startTimeT;
								obj.trialNumberTS = obj.trialNumberT;
								obj.makeSingleChannelTrials();
						else
								obj.fixFrameAssignment()
								obj.makeMultiChannelTrials()
						end
						obj.makeDataProps();
				end
				function setPath(obj)
						if ~isempty(obj.processedDataPath)
								response = questdlg(sprintf(...
										'Do you want to use the following directory for processed data? \n %s',...
										obj.processedDataPath),...
										'Previously Set Processed-Data Path');
								if strcmpi(response,'yes')
										return
								end
						end
						fpath3 = obj.experimentName;
						fpath2 = 'Temporary Raw Data';
						fpath1 = obj.videoFile(1).rootPath;						
						% 						if isempty(fpath3)
						% 								fpath3 = datestr(now,'HHMM');
						% 						end
						% 						fpath2 = sprintf('Processed_Data_%s',datestr(now,'yyyy'));
						% 						fpath1 = 'Z:\Processed Data';
						response = questdlg(sprintf(...
								'Do you want to use the following directory for processed data? \n %s',...
								...%fullfile(fpath1,fpath2,fpath3)),...
								fullfile(fpath1,fpath2)),...
								'Previously Set Processed-Data Path');
						if strcmpi(response,'yes')
							% 								fpath = fullfile(fpath1,fpath2,fpath3);
							fpath = fullfile(fpath1,fpath2);
						else
								fpath = uigetdir(userpath,'Specify a Processed Data Folder');
						end
						if ~isdir(fpath)
								[success,message] = mkdir(fpath);
								if ~success
										warning(message)
										fpath = uigetdir(userpath,'Specify a Valid Processed Data Folder');
								end
						end
						obj.processedDataPath = fpath;
						obj.pathIsSet = true;
						fprintf('Processed data will be saved to: %s\n',fpath);
				end
		end
		methods % DATA IMPORT
				function loadFiles(obj)
						if isempty(obj.videoFile)
								[vfile,vdir] = uigetfile('Z:\','Choose a Camera-Session Mat File to Load');
								tmp = struct2cell(load(fullfile(vdir,vfile)));
								obj.videoFile = tmp{:};
						end
						if isempty(obj.behaviorFile)
								[bfile,bdir] = uigetfile('Z:\','Choose a Behavior-Session Mat File to Load');
								tmp = struct2cell(load(fullfile(bdir,bfile)));
								obj.behaviorFile = tmp{:};
						end
						if obj.behaviorFile(1).numFrames == 0 ...
								|| obj.videoFile(1).numFrames == 0
							obj.behaviorFile = obj.behaviorFile(2:end);
							obj.videoFile = obj.videoFile(2:end);
						end
						if isempty(obj.behavCtrlBhvFile)
								[sfile,sdir] = uigetfile('.bhv','Choose a Bhv File (from BehavCtrl');
								obj.behavCtrlBhvFile.name = sfile;
								obj.behavCtrlBhvFile.path = sdir;
								try
										[header trials] = readBhvFile(fullfile(sdir,sfile));
										obj.behavCtrlBhvFile.header = header;
										obj.behavCtrlBhvFile.trials = trials;
								catch me
										warning('DataProcessor:loadFiles:readBhvFile',...
												'Problem reading BehavCtrl file: %s',me.message)
								end
						end
						if isempty(obj.behavCtrlEyeFile)
								efile = [strtok(sfile,'.'),'.eye'];
								edir = sdir;
								if ~(exist(fullfile(edir,efile), 'file')==2)
										[efile,edir] = uigetfile('.eye','Choose an Eye File (from BehavCtrl)');
								end
								obj.behavCtrlEyeFile.name = efile;
								obj.behavCtrlEyeFile.path = edir;
								try
										if obj.setting.readEyeFile
												[header trials] = readEyeFile(fullfile(edir,efile),'Val_MatFormat',obj.setting.Val_MatFormat);
												obj.behavCtrlEyeFile.header = header;
												obj.behavCtrlEyeFile.trials = trials;
										end
								catch me
										warning('DataProcessor:loadFiles:readEyeFile',...
												'Problem reading BehavCtrl Eye file: %s',me.message)
								end
						end
				end
				function readFiles(obj)
						% Get Experiment Info from Behavior-File
						obj.experimentName = obj.behaviorFile(min(...
								[2 numel(obj.behaviorFile)])).experimentName;
						% Get Trial Header Info from Video-File
						obj.numFramesT = cat(1,obj.videoFile.numFrames);
						obj.firstFrameT = cat(1,obj.videoFile.firstFrame);
						obj.lastFrameT = cat(1,obj.videoFile.lastFrame);
						obj.startTimeT = cat(1,obj.videoFile.startTime);
						% Align Behavior & Video File Frames
						vinfo = getInfo(obj.videoFile,'cat');
						binfo = getInfo(obj.behaviorFile,'cat');
						obj.videoFileInfo = vinfo;
						obj.behaviorFileInfo = binfo;
						bhv_frame_numbers = binfo.FrameNumber + vinfo.FrameNumber(1) - binfo.FrameNumber(1);
						obj.maxCommonFrame = max(intersect(vinfo.FrameNumber,bhv_frame_numbers));
						vid_frame_numbers = vinfo.FrameNumber(vinfo.FrameNumber <= obj.maxCommonFrame);
						bhv_frame_numbers = bhv_frame_numbers(bhv_frame_numbers <= obj.maxCommonFrame);
						obj.frameNumberF = union(vid_frame_numbers,bhv_frame_numbers);
						% Assign Info to Frames
						if isfield(vinfo,'Channel')
								obj.channelF(vinfo.FrameNumber) = char(vinfo.Channel);
						else
								obj.channelF(vinfo.FrameNumber) = 'x';
						end
						obj.frameTimeF(vinfo.FrameNumber) = vinfo.FrameTime;
						obj.absTimeF(vinfo.FrameNumber) = vinfo.AbsTime;
						% Try to Read from Bhv File, Otherwise use UDP Information
						success = obj.alignFramesWithBhvFile();
						if success
								obj.behavCtrlWasUsed = true;
						else
								warning('DataProcessor:readFiles:BhvFileFrameAlignmentFailure',...
										'Problem reading BehavCtrl file')
								obj.trialNumberF(bhv_frame_numbers) = binfo.TrialNumber(1:numel(bhv_frame_numbers));
								obj.stimStatusF(bhv_frame_numbers) = binfo.StimStatus(1:numel(bhv_frame_numbers));
								obj.stimNumberF(bhv_frame_numbers) = binfo.StimNumber(1:numel(bhv_frame_numbers));
								obj.behavCtrlWasUsed = false;
						end
						try
								obj.alignFramesWithEyeFile();
						catch me
								warning('DataProcessor:readFiles:EyeFileFrameAlignmentFailure',...
										'Problem reading BehavCtrl Eye file: %s',me.message)
						end
						% Record Missing Frames (for debugging/informational purposes?)
						[~,ia,ib] = setxor(vid_frame_numbers,bhv_frame_numbers);
						obj.missingVideoFileFrames = vid_frame_numbers(ia);
						obj.missingBehaviorFileFrames = bhv_frame_numbers(ib);
				end
				function success = alignFramesWithBhvFile(obj)
						try
								% Make Sure Bhv file (from BehavCtrl) is Loaded
								if isempty(obj.behavCtrlBhvFile)% || isempty(obj.behavCtrlEyeFile)
										obj.loadFiles();
								end
								if ~isfield(obj.behavCtrlBhvFile,'header')
									error('DataProcessor:alignFramesWithBhvFile:NoHeaderError',...
										'Error reading .bhv file from BehavCtrl');									
								end
								header = obj.behavCtrlBhvFile.header;
								if isempty(obj.experimentName)
										obj.experimentName = header.ExperimentName;
								end
								trials = obj.behavCtrlBhvFile.trials;
								time_zero = trials(1).head.StartTime;
								% Extract Events from Bhv File
								events = cat(2,trials.events);
								eventTimes = cat(1,events.Time);
								eventTimes = eventTimes - time_zero;
								eventTimes = eventTimes/1000; % (relative times in sec)
								eventNames = {events.Event}';
								trialHeads = cat(1,trials.head);
								% Get Stimulus Numbers
								stimNumbers = NaN(size(trials));
								for n = 1:numel(trials)
										if isfield(trials(n).stim,'STIMULUS_BLANK')
												stimNumbers(n) = 0;
												continue
										end
										if isfield(trials(n).stim,'STM_FILE')
												stimNumbers(n) = str2double(trials(n).stim.STM_FILE.N);
										else
												stimNumbers(n) = NaN;
										end
								end
								trialStartTimes = cat(1,trialHeads.StartTime);
								trialStartTimes = trialStartTimes - trialStartTimes(1);
								trialStartTimes = trialStartTimes/1000;
								trialNumbers = cat(1,trialHeads.TrialNumber);
								% Assign Frame Numbers to Each Event
								frameTimes = obj.videoFileInfo.FrameTime;
								frameRate = 1/mean(diff(frameTimes));
								eventFrames = round(eventTimes * frameRate)+1;
								trialStartFrames = round(trialStartTimes * frameRate) + 1;
								% Determine if the Camera Started after a Delay (frameshift)
								behaviorFileTrialStartFrames = [1 ; find(diff(obj.behaviorFileInfo.TrialNumber)>0)+1];
								mincommontrials = min(length(trialStartFrames),length(behaviorFileTrialStartFrames));
								camlags = trialStartFrames(1:mincommontrials) - behaviorFileTrialStartFrames(1:mincommontrials);
								offset = round(mean([mean(camlags) mode(camlags)]));
								% Shift and Warn if there is a Consistent Offset
								if abs(offset>1)
										warning('DataProcessor:alignFramesWithBhvFile:CameraLag',...
												'Video data lag behind data from BehavCtrl by %i frames (at full frame rate)',offset);
								end
								trialStartFrames = trialStartFrames - offset;
								trialStartFrames(trialStartFrames<1) = 1;
								obj.behavCtrlBhvFileEvents.TrialStart = trialStartFrames;
								eventFrames = eventFrames - offset;
								eventFrames(eventFrames<1) = 1;
								% Extract Event Timing from All Events
								possemptyeventnames = eventNames;
								eventNames = cell.empty(0,1);
								m = 1;
								for n = 1:numel(possemptyeventnames)
										if ~isempty(possemptyeventnames{n})
												eventNames{m} = possemptyeventnames{n};
												m = m+1;
										end
								end
								eventTypes = unique(eventNames);
								for n = 1:numel(eventTypes)
										thisType = strcmp(eventTypes{n},eventNames);
										thisName = eventTypes{n};
										thisName = thisName(4:end);
										obj.behavCtrlBhvFileEvents.(thisName) = eventFrames(thisType);
										% behavCtrlBhvFileEvents Fields:
										%           FixationPeriod StartReward  StimulusShift StimulusShow
								end
								% Construct Frame-Synchronized Vectors
								% Trial Numbers
								frameNumbers = obj.videoFileInfo.FrameNumber;
								frameSyncSize = numel(frameNumbers);
								obj.trialNumberF = obj.event2FrameSync(trialStartFrames,trialNumbers,frameSyncSize);
								% Stim Numbers
								% 						stimonoff = obj.behavCtrlBhvFileEvents.StimulusShow; %includes fix 2
								% 						stimonoff(2:2:end) = obj.behavCtrlBhvFileEvents.StimulusShift % doesn't include fix2
								% 						bs = obj.event2FrameSync(stimonoff,status,frameSyncSize);
								% 						obj.stimStatusF = bs;
								% 						stimstarts = obj.behavCtrlBhvFileEvents.StimulusShow(1:2:end);
								% Go Through Trial-by-Trial to Extract Stim-On due to sometimes paired MsgShowStimulus
								stimstarts = NaN(size(trialStartTimes));
								stimshifts = NaN(size(trialStartTimes));
								stimstops = NaN(size(trialStartTimes));
								for n = 1:numel(trials)
										tevents = trials(n).events;
										if ~isempty(tevents)
												teventnames = cell2mat({tevents.Event}');
												teventframes = round((cat(1,tevents.Time) - time_zero)/1000 * frameRate) - offset;
												stimon_index = strmatch('MsgStimulusShow',teventnames);
												stimshift_index = strmatch('MsgStimulusShift',teventnames);
												if any(stimshift_index)
														stimshifts(n) = teventframes(min(stimshift_index)); % or use a second stimstart msg?
												end								
												if any(stimon_index)
														stimstarts(n) = teventframes(min(stimon_index));
														if numel(stimon_index) > 1
																stimstops(n) = teventframes(max(stimon_index));
														else
																stimstops(n) = max(stimstarts(n)+1, stimshifts(n));
														end
												end				
										end
								end
								if isfield(obj.behavCtrlBhvFileEvents,'StimulusShow')
										stimonoff = union(stimstarts,stimstops);
										status = false(sum(~isnan(stimonoff)),1);
										status(1:2:end) = true;
										bs = obj.event2FrameSync(stimonoff,status,frameSyncSize);%stim-status
										if isempty(stimNumbers)
												stimNumbers = ~isnan(stimstarts);
										end
										fs = obj.event2FrameSync(stimstarts,stimNumbers,frameSyncSize);%stim-number
										fs(~bs) = NaN;
										obj.stimNumberF = fs;
										obj.stimStatusF = bs;
								else
										obj.stimNumberF = NaN(frameSyncSize,1);
										obj.stimStatusF = false(frameSyncSize,1);
								end
								% Assign Trial Outcomes from BehavCtrl Data
								behavCtrlOutcomes = cat(1,trialHeads.Outcome);
								obj.outcomeTS = behavCtrlOutcomes == 0; % 0=complete?
								success = true;
						catch me
								beep
								me.message
								me.stack(1)
								success = false;
						end
				end
				function alignFramesWithEyeFile(obj)
						if obj.setting.readEyeFile
								d = cat(2,obj.behavCtrlEyeFile.trials.data);
								p = cat(2,d.points);
								pfields = fields(p);
								for n =1:numel(pfields)
										obj.behavCtrlEyeFileData.(pfields{n}) = cat(2,p.(pfields{n}));
								end
						end
				end
				function fixChannelLabels(obj)
						try
								obj.channelF = char(obj.channelF); %(to make sure it ischar)
								original_length = length(obj.channelF);
								% Change Zeros to Spaces (ascii-32) and Record in Hidden Props
								obj.mislabeledZeroFrames = find(obj.channelF == char(0));
								obj.mislabeledSpaceFrames = find(obj.channelF == ' ');
								obj.channelF(obj.channelF == 0) = ' ';
								% Attempt a Guess at Illumination Sequence/Pattern
								%    -> for various sequence-length guesses (n) find the difference between supposed
								%    repeats in the sequence... if sequence is reshaped so that only repeats are next to
								%    each other, then the derivative is minimized (error is in spaces)
								rawlabels = obj.channelF(1:min([5000 length(obj.channelF)]));
								rawlabels(isspace(rawlabels)) = '^'; % (to lessen effect of spaces)
								max_sequence_length = 30;
								discrep = zeros(max_sequence_length,1);
								for n=1:max_sequence_length
										a_trim = rawlabels(1:floor(numel(rawlabels)/n)*n);
										a_reshape = reshape(a_trim,n,[]);
										difmat = a_reshape(:,2:end) - a_reshape(:,1:end-1);
										discrep(n) = sum(abs(difmat(:)));
								end
								[~,seqlength] = min(discrep(:));
								obj.estimatedSequenceLength = seqlength;
								n=1;
								% Find a Segment of Sequence with No Spaces (from recording errors)
								while n<length(obj.channelF)-seqlength
										illumination_sequence = obj.channelF(n:n+seqlength-1);
										if any(isspace(illumination_sequence))
												n=n+seqlength;
										else
												break
										end
								end
								% Query User About Sequence Correctness
								if strcmpi(obj.setting.creationMode,'manual')
										answer = questdlg(sprintf('Is this the correct illumination sequence: %s',illumination_sequence),...
												'Illumination Sequence','Yes','No','Yes');
										if strcmpi(answer,'No')
												illumination_sequence = char(inputdlg('Enter the Correct Illumination Sequence:',...
														'Manual Illumination Sequence',1,{illumination_sequence}));
												use_manual_labels = true;
										else
												use_manual_labels = false;
										end
								end
								obj.illuminationSequence = illumination_sequence;
								seqlength = length(illumination_sequence);
								obj.estimatedSequenceLength = seqlength;
								% Compare the Raw Channel Array (with spaces) To a Repeated Sequence
								nrepeats = floor(numel(obj.channelF)/seqlength);
								rawseq = obj.channelF(1:nrepeats*seqlength);
								[~,longdim] =max(size(obj.channelF));
								repmatsize = ones(1,2);
								repmatsize(longdim) = nrepeats+1;
								repseq = repmat(illumination_sequence,repmatsize);
								if use_manual_labels
										obj.channelF = repseq(1:original_length);
										obj.checkChannelLabels();
								else
										% If All Differences are Accounted For by Spaces -> Good Predictor
										% 										guess_spaces = find(repseq(1:numel(rawseq)) - rawseq);
										% 										actual_spaces = find(isspace(rawseq));
										% 										obj.estimatedSequenceStrength = ...
										% 												sum(intersect(guess_spaces,actual_spaces) - guess_spaces);%(good if 0)
										% Fill in Spaces
										repseq = repmat(repseq,[1 2]);
										tofill = find(isspace(obj.channelF));
										obj.channelF(tofill) = repseq(tofill);
								end
						catch me
								disp(me.message)
								disp(me.stack(1))
								keyboard
						end
				end
				function checkChannelLabels(obj)
						data = getData(obj.videoFile(1),1:20);
						while true
								channelset = obj.channelF(1:20);
								imaqmontage(data)
								nframes = size(data,4);
								nrows = ceil(sqrt(nframes));
								ncols = floor(sqrt(nframes));
								imres = size(data,1);
								nframe = 1;
								for row = 1:nrows
										for col = 1:ncols
												if nframe > nframes
														break
												end
												switch char(channelset(nframe))
														case 'r'
																textcol = [.8 0 0];
														case 'g'
																textcol = [0 .6 0];
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
										'Illumination Sequence Alignment','Yes','No: Shift Labels','Yes');
								switch lower(answer(1))
										case 'n'
												obj.illuminationSequence = circshift(obj.illuminationSequence',-1)';
												obj.channelF = circshift(obj.channelF',-1)';
												clf
										case 'y'
												close
												break
								end
						end
				end
				function makeSingleChannelTrials(obj)
						% Work Through Sequenced/MultiChannel Trial Info
						stimstarts = find(diff(obj.stimStatusFS) == 1) + 1;
						stimshifts = find(diff(obj.stimStatusFS) == 2) + 1;
						stimstops = find(diff(obj.stimStatusFS) < 0) + 1;
						if ~isempty(stimstops)
								stimstarts = stimstarts(stimstarts<stimstops(end));
								stimshifts = stimshifts(stimshifts<stimstops(end));
						end
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
						if ~isempty(obj.singleChannelTrialSet)
								delete(obj.singleChannelTrialSet);
						end
						obj.singleChannelTrialSet = Trial.empty(0,1);
						ntrials = length(obj.trialNumberT);
						% Calculate Property Values for All Trials in Set
						for n=1:ntrials
								frx = obj.trialNumberF == obj.trialNumberT(n);
								try
										sftrial = Trial(...
												'trialNumber',obj.trialNumberT(n),...
												'frameNumberFS',obj.frameNumberF(frx),...
												'channelFS',obj.channelF(frx),...
												'frameTimeFS',obj.frameTimeF(frx),...
												'stimStatusFS',obj.stimStatusF(frx),...
												'stimNumberFS',obj.stimNumberF(frx));
										sftrial.stimNumber = mode(sftrial.stimNumberFS(~isnan(sftrial.stimNumberFS)));
										sftrial.numFrames = numel(sftrial.frameNumberFS);
										sftrial.firstFrame = sftrial.frameNumberFS(1);
										sftrial.lastFrame = sftrial.frameNumberFS(end);
										sftrial.startTime = sftrial.frameTimeFS(1);
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
										obj.singleChannelTrialSet(n) = sftrial;
								catch me
										fprintf('error in Experiment > makeSingleChannelTrials\n')
								end
						end
						obj.trialSet = obj.singleChannelTrialSet;
				end
				function fixFrameAssignment(obj)
						try
								% Find Best First Frame to Start On
								% (so first frame contains whole sequence in case of repeats?)
								sl = numel(obj.illuminationSequence);
								s = repmat(' ',[sl sl]);
								for n = 1:sl
										s(n,:) = circshift(obj.illuminationSequence',-n+1);
								end
								nchanges = sum(abs(diff(double(s),1,2))>0,2);
								[~,firstframe] = min(nchanges);
								obj.frameDecimationSequence = s(firstframe,:);
								obj.frameDecimationStartFrame = firstframe;
								% Generate New Trial Sections
								num_block_frames = floor((obj.maxCommonFrame-firstframe+1)/sl)-1;
								space_index = firstframe:sl:num_block_frames*sl;
								mat_index = uint32(reshape(firstframe:num_block_frames*sl+firstframe-1,sl,[]));
								obj.frameDecimationMatMap = mat_index;
								obj.frameNumberFS = obj.frameNumberF(space_index );
								obj.channelFS = obj.channelF(mat_index);
								obj.frameTimeFS = obj.frameTimeF(space_index );
								obj.trialNumberFS = obj.trialNumberF(space_index );
								obj.stimStatusFS = mode(double(obj.stimStatusF(mat_index)),1);
								obj.stimNumberFS = mode(obj.stimNumberF(mat_index),1);
								obj.trialNumberTS = unique(obj.trialNumberFS)';
								obj.numFramesTS = sum(bsxfun(@eq, obj.trialNumberTS(:) ,...
										repmat(obj.trialNumberFS(:)',[numel(obj.trialNumberTS) 1])),2);
								[trial_ind, ~] = find(bsxfun(@eq,obj.trialNumberTS(:) ,...
										repmat(obj.trialNumberFS(:)',[numel(obj.trialNumberTS) 1])));
								[~,obj.firstFrameTS,~] = unique(trial_ind,'first');
								[~,obj.lastFrameTS,~] = unique(trial_ind,'last');
								obj.startTimeTS = obj.frameTimeFS(obj.firstFrameTS);
						catch me
								me.message
								me.stack(1)
								beep
								keyboard
						end
				end
				function makeMultiChannelTrials(obj)
						% Work Through Sequenced/MultiChannel Trial Info
						stimstarts = find(diff(obj.stimStatusFS) == 1) + 1;
						stimshifts = find(diff(obj.stimStatusFS) == 2) + 1;
						stimstops = find(diff(obj.stimStatusFS) < 0) + 1;
						if ~isempty(stimstops)
								stimstarts = stimstarts(stimstarts<stimstops(end));
								stimshifts = stimshifts(stimshifts<stimstops(end));
						end
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
						ntrials = length(obj.trialNumberTS);
						% Determine Minimum Settings for Trial-Outcome
						[~,i1,~] = unique(obj.trialNumberFS,'first');
						[~,i2,~] = unique(obj.trialNumberFS,'last');
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
						if ~obj.behavCtrlWasUsed
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
				function makeDataProps(obj)
						for n = 1:obj.numChannels
								chanlabel = obj.channelLabels(n);
								% Make chanFrameNumbers Property
								mprop = addprop(obj,sprintf('%sFrameNumbers',obj.channels{n}));
								mprop.SetAccess = 'private';
								obj.metaDynamicPropHandles{n,1} = mprop;
								obj.makeFrameNumbers(chanlabel);
								% 								mprop.GetMethod =
								% 								@(obj)channelFrameNumbers(obj,obj.channelLabels(n));
								% Make chanVidFrameInfo Property
								vinfoprop = addprop(obj,sprintf('%sVidFrameInfo',obj.channels{n}));
								vinfoprop.SetAccess = 'private';
								obj.metaDynamicPropHandles{n,2} = vinfoprop;
								obj.makeVidFrameInfo(chanlabel);
								% 								vinfoprop.GetMethod = @(obj)channelVidFrameInfo(obj,obj.channelLabels(n));
								% Make chanBhvFrameInfo Property
								binfoprop = addprop(obj,sprintf('%sBhvFrameInfo',obj.channels{n}));
								binfoprop.SetAccess = 'private';
								obj.metaDynamicPropHandles{n,3} = binfoprop;
								obj.makeBhvFrameInfo(chanlabel);
								% 								binfoprop.GetMethod = @(obj)channelBhvFrameInfo(obj,obj.channelLabels(n));
								% Make DataProps
								vprop = addprop(obj,sprintf('%sData',obj.channels{n}));
								vprop.SetAccess = 'private';
								vprop.Transient = true;
								obj.metaDynamicPropHandles{n,4} = vprop;
								obj.dataFields{n} = vprop.Name;
								obj.makeData(chanlabel);
								% 								vprop.Dependent = true;
								% 								vprop.GetMethod = @(obj)channelData(obj,obj.channelLabels(n));
								% Make TraceProps
								tprop = addprop(obj,sprintf('%sTrace',obj.channels{n}));
								tprop.SetAccess = 'protected';
								obj.metaDynamicPropHandles{n,5} = tprop;
								obj.traceFields{n} = tprop.Name;
								obj.makeTrace(chanlabel);
								% Make Triggered Average PropsSt
								sprop = addprop(obj,sprintf('%sTriggeredAverage',obj.channels{n}));
								sprop.SetAccess = 'protected';
								obj.metaDynamicPropHandles{n,6} = sprop;
								obj.makeTriggeredAverage(chanlabel);
						end
				end
				function makeFrameNumbers(obj,chanlabel)
						if nargin<2
								for n = 1:length(obj.channelLabels)
										obj.makeFrameNumbers(obj.channelLabels(n))
								end
								return
						end
						% Returns the frame numbers associated with chanlabel (e.g. 'r')
						% If the seqeuence has repeats (e.g. 'rrgg'  -> rrggrrggrrggrrgg...) then the output
						% will have multiple rows representing each repeat in the sequence
						propname = sprintf('%sFrameNumbers',obj.channels{strfind(obj.channelLabels(:)',chanlabel)});
						sequence_index = find(obj.frameDecimationSequence==chanlabel);
						if ~isempty(sequence_index)
								obj.(propname) = obj.frameDecimationMatMap(sequence_index,:);
						end
				end
				function makeVidFrameInfo(obj,chanlabel)
						if nargin<2
								for n = 1:length(obj.channelLabels)
										obj.makeVidFrameInfo(obj.channelLabels(n))
								end
								return
						end
						try
								propname = sprintf('%sVidFrameInfo',obj.channels{strfind(obj.channelLabels(:)',chanlabel)});
								obj.(propname) = getInfo(obj.videoFile,'cat','FrameNumber',...
										obj.channelFrameNumbers(chanlabel));
						catch
								obj.(propname) = [];
						end
				end
				function makeBhvFrameInfo(obj,chanlabel)
						if nargin<2
								for n = 1:length(obj.channelLabels)
										obj.makeBhvFrameInfo(obj.channelLabels(n))
								end
								return
						end
						try
								fnumbers = obj.channelFrameNumbers(chanlabel) ...
										+ obj.behaviorFileInfo.FrameNumber(1) - 1; % (b/c some behavior files don't begin at FrameNumber=1)
								propname = sprintf('%sBhvFrameInfo',obj.channels{strfind(obj.channelLabels(:)',chanlabel)});
								obj.(propname) = getInfo(obj.behaviorFile,'cat',...
										'FrameNumber',fnumbers);
						catch
								obj.(propname) = [];
						end
				end
				function makeData(obj,chanlabel)
						% --------------------------------------------------------------------------------------
						% PROCEDURE: Read from video-files and save the video data using one of a variety of
						% methods. If the OS is 64-bit, it will be written to a file memory-mapped using virtual
						% address space.
						% --------------------------------------------------------------------------------------
						% --------------------------------------------------------------------------------------
						% Call Recursively if chanlabel is not Specified
						if nargin<2
								for n = 1:length(obj.channelLabels)
										obj.makeData(obj.channelLabels(n))
								end
								return
						end
						% Check for Prior Existence of Processed Data
						% --------------------------------------------------------------------------------------
						propname = obj.dataFields{strfind(obj.channelLabels(:)',chanlabel)};
						try
								isempty(obj.(propname));
						catch % re-add the dynamic prop (redData or greenData) if lost between saving
								vprop = addprop(obj,propname);
								vprop.SetAccess = 'private';
								vprop.Transient = true;
						end
						% Search for Previously-Saved Processed-Data Files (Large)
						% --------------------------------------------------------------------------------------
						if isfield(obj.filepaths,propname) && exist(obj.filepaths.(propname),'file') == 2
								fname = obj.filepaths.(propname);%(previously saved in this class instance)
						else
								if ~obj.pathIsSet
										obj.setPath();
								end
								if isempty(obj.processedDataPath)
										obj.processedDataPath = uigetdir(obj.processedDataPath,'Processed-Data Directory');
								end
								fname = fullfile(obj.processedDataPath,propname);
						end
						obj.filepaths.(propname) = fname; %(save processed-data path)
						% --------------------------------------------------------------------------------------
						% Read Data from Smaller Files and Write to Large File
						% --------------------------------------------------------------------------------------
						if exist(fname,'file') == 2 % (previous file exists)
								obj.usePreviouslyProcessedData = ...
										strcmpi('yes',questdlg('Do you want to use previously processed data?'));
						end
						if ~obj.usePreviouslyProcessedData
								% ----------------------------------------------------------------------------------
								% Initialize some Variables
								framenumbers = obj.channelFrameNumbers(chanlabel);%(a method -> non-binned frame numbers)
								szf = size(framenumbers); % for temporal binning
								nrepeats = szf(1); % (e.g. if LED sequence is rrgg, nrepeats = 2 for chanlabel 'r' and 'g')
								lastdata = [];
								nframes_written = 0;
								framenumbers_acquired = [];
								fprintf('Writing %s to File: %s\n',propname,fname);
								% --------------------------------------------------------------------------------------
								% Check for Missing Frames
								info = getInfo(obj.videoFile,'cat','FrameNumber',framenumbers);
								total_frames = obj.numFrames;%TRYING<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
								[missing_frames, missing_frame_index] = setdiff(framenumbers(:),info.FrameNumber(:));
								if ~isempty(missing_frames)
										warning('DataProcessor:makeData:MissingFrames',...
												'The following frames are missing from the set of video-files:\n%s\n',num2str(missing_frames))
								end
								binSpatially = false;
								if obj.videoFile(1).dataSize(1) > 256
									if strcmpi('Yes',questdlg('Bin images spatially to 256x256?','Spatial Binning','Yes','No','Yes'))
										binSpatially = true;
									end
								end
								% --------------------------------------------------------------------------------------
								% Read Data from One VideoFile at a Time -> Write
								fid = fopen(fname,'wb');
								for n = 1:numel(obj.videoFile)
										[data,info] = getData(obj.videoFile(n),'FrameNumber',framenumbers);
										framenumbers_acquired = cat(1,framenumbers_acquired,info.FrameNumber(:));
										% --------------------------------------------------------------------------------------
										% Write Data from Current File and Any Leftover Data from Previous Trial
										% (mid-sequence data)
										data = cat(4,lastdata,data);
										frames_this_file = nrepeats*floor(size(data,4)/nrepeats);
										% ------------------------------------------------------------------------------
										% Chop Off and Save Frames for Temporal Binning with Next Trial
										if frames_this_file < size(data,4)
												lastdata = data(:,:,:,frames_this_file+1:size(data,4));
												data = data(:,:,:,1:frames_this_file);
										else
												lastdata = [];
										end
										% ------------------------------------------------------------------------------
										% Temporal Binning Step
										if szf(1) > 1 && obj.setting.addSequenceRepeats % repeated frames in sequence ('rrgg')
												szd = size(data);
												data = uint16(sum(reshape(data,szd(1),szd(2),szf(1),[]),3));
										end
										% ------------------------------------------------------------------------------
										% Spatial Binning if 1024x1024
										if binSpatially
											data = obj.spatialBinData(data,4);
											datatype = 'uint32';
											obj.resolution = [size(data,1) size(data,2)];
										else
											obj.resolution = obj.videoFile(1).dataSize;
											datatype = obj.videoFile(1).dataType;
										end
										% ------------------------------------------------------------------------------
										% Write Data to File
										fwrite(fid,data(:),datatype);
										nframes_written = nframes_written + size(data,4);
										fprintf('%i of %i frames written to %s\n',nframes_written, total_frames,fname);
								end
								fclose(fid);
						else
							datatype_options = {'uint8','uint16','uint32'};							
							datatype = datatype_options{menu('Choose a datatype',datatype_options)};
							obj.resolution = obj.videoFile(1).dataSize;
						end
						% --------------------------------------------------------------------------------------
						% Create a Memory Map to the Large File
						% --------------------------------------------------------------------------------------
						fprintf('Mapping video data (%s) to virtual memory.\n',propname);
						obj.videoMemoryObj.(propname) = memmapfile(fname,...
								'Format',datatype,...
								'Writable',true);
						try % Reshape a Reference to the Memory-Mapped Data
								obj.(propname) = reshape(obj.videoMemoryObj.(propname).Data,...
										obj.resolution(1),obj.resolution(2),1,[]);
						catch me
								fclose('all');
								obj.(propname) = reshape(obj.videoMemoryObj.(propname).Data,...
										obj.resolution(1)/4,obj.resolution(2)/4,1,[]);
						end
				end
				function makeTrace(obj,chanlabel)
					try
						if nargin<2
								for n = 1:length(obj.channelLabels)
										obj.makeTrace(obj.channelLabels(n))
								end
								return
						end
						maptrace = false;
						propname = sprintf('%sTrace',obj.channels{strfind(obj.channelLabels(:)',chanlabel)});
						dataname = sprintf('%sData',obj.channels{strfind(obj.channelLabels(:)',chanlabel)});
						if maptrace
								fname = fullfile(obj.processedDataPath,propname);
								fprintf('Writing %s to File: %s\n',propname,fname);
								fid = fopen(fname,'wb');
								fwrite(fid,mean(reshape(obj.(dataname),prod(obj.videoFile(1).resolution),[]),1), 'double')
								fclose(fid);
								obj.videoMemoryObj.(propname) = memmapfile(fname,...
										'Format','double');
								obj.(propname) = obj.videoMemoryObj.(propname).Data;
						else
								obj.(propname) = mean(reshape(obj.(dataname),...
									prod([size(obj.(dataname),1) size(obj.(dataname),2)]),[]));
						end
					catch me
						fprintf('error making trace: %s',me.message)
					end
				end
				function makeTriggeredAverage(obj,chanlabel)
						if nargin<2
								for n = 1:length(obj.channelLabels)
										obj.makeTriggeredAverage(obj.channelLabels(n))
								end
								return
						end
						try
								if isempty(obj.outcomeTS)
										obj.checkTrialOutcomes();
								end
								propname = sprintf('%sTriggeredAverage',obj.channels{strfind(obj.channelLabels(:)',chanlabel)});
								dataname = sprintf('%sData',obj.channels{strfind(obj.channelLabels(:)',chanlabel)});
								trialstarts = obj.firstFrameTS;
								stimstarts = obj.stimStartTS;
								stimshifts = obj.stimShiftTS;
								stimstops = obj.stimStopTS;
								stimnums = obj.stimNumberTS;
								prestim = -obj.setting.nFramesPreTrigger;
								poststim = obj.setting.nFramesPostTrigger;
								stimrelative_index = prestim:poststim-1;
								stim = unique(stimnums(~isnan(stimnums)));
								obj.(propname) = [];
								for n=1:numel(stim)
										ind = stimnums == stim(n);
										ind = ind & stimstarts+poststim <=size(obj.(dataname),4);
										ind = ind & (stimstarts + min(prestim(:))) > 0;
										ind = ind(:) & obj.outcomeTS(1:numel(ind));
										firstframe = stimstarts(ind);
										[X,Y] = meshgrid(firstframe, stimrelative_index );
										index_mat = X+Y;
										obj.(propname).(sprintf('stim%i',stim(n))) = ...
												mean(reshape(obj.(dataname)(:,:,:,index_mat),...
												[obj.resolution 1 size(index_mat)]),5);
								end
						catch me
							keyboard
							obj.(propname).(sprintf('stim%i',stim(n))) = ...
												mean(reshape(obj.(dataname)(:,:,:,index_mat),...
												[obj.resolution/4 1 size(index_mat)]),5);
								fprintf('%s failed to complete...\n',propname)
						end
				end
				function checkTrialOutcomes(obj)
						if obj.behavCtrlWasUsed()
								warning('Attempting to determine trial outcomes from timing info');
						end
						stimlengths = obj.stimLengthTS;
						if ~isempty(obj.setting.stimLengthMinFrames)
								stim_min = obj.setting.stimLengthMinFrames;
						else
								warning('Stimulus on minimum not set')
								stim_min = mode(stimlengths)-1; % (1-frame tolerance)
						end
						obj.outcomeTS = stimlengths >= stim_min ;
				end
		end
		methods % DATA PROCESSING
				function shiftData(obj)
						% Create new Files for Shifted Data
						for n = 1:numel(obj.dataFields)
								propname = sprintf('%s_Shifted',obj.dataFields{n});								
								unshiftedDataFilename = obj.videoMemoryObj.(obj.dataFields{n}).Filename;
								fname = fullfile(obj.processedDataPath,propname);
								if ~(exist(fname,'file')==2)
										copyfile(unshiftedDataFilename,fname,'f');
								end
								obj.videoMemoryObj.(propname) = memmapfile(fname,...
										'Format',obj.videoFile(1).dataType,...
										'Writable',true);
								obj.dataFields{n} = propname;
								vprop = addprop(obj,propname);
								vprop.SetAccess = 'private';
								vprop.Transient = true;
								obj.metaDynamicPropHandles{n,length(obj.metaDynamicPropHandles)+1} = vprop;
								obj.filepaths.(propname) = fname;
								obj.(propname) = reshape(obj.videoMemoryObj.(propname).Data,...
										obj.resolution(1),obj.resolution(2),1,[]);
						end
						switch lower(obj.setting.imageShiftingMethod)
								case 'ecc'
										obj.shiftDataECC();
								case 'bergenlk'
										obj.shiftDataBergen();
						end
						obj.(propname) = reshape(obj.videoMemoryObj.(propname).Data,...
										obj.resolution(1),obj.resolution(2),1,[]);
						obj.makeTriggeredAverage();
				end
				function shiftDataECC(obj)
						try
								if isempty(obj.dataFields)
										return
								end
								try
								matlabpool open
								catch me
										if ~strcmp(me.identifier,'distcomp:interactive:OpenConnection')
												error('Problem with parallel matlab');
										end
								end
								for df = 1:numel(obj.dataFields)
										dataname = obj.dataFields{df};
										% Make Template
										template = double(obj.(dataname)(:,:,:,1));
										imsize = [size(template,1) size(template,2)];
										% Get ROI (default is central 75%)
										hfig = imagesc(template);
										hax = gca;
										hm = msgbox('Choose a region to use for motion-correction');
										waitfor(hm);
										rectObj = imrect(hax);
										setPosition(rectObj,...
												[size(template,2)/8    size(template,1)/8 ...
												size(template,2)*3/4 size(template,1)*3/4] );
										setFixedAspectRatioMode(rectObj,true);
										wait(rectObj);
										roi_mask = rectObj.createMask();
										sz = sqrt(sum(roi_mask(:)));
										[roi_I roi_J] = find(roi_mask);
										roi_rows = min(roi_I):max(roi_I);
										roi_cols = min(roi_J):max(roi_J);
										roi_size = [numel(roi_rows) numel(roi_cols)];
										close(gcf);
										
										% Loop To Save Memory? -> Check Memory
										[~,smem] = memory;
										ramavailGB = smem.SystemMemory.Available/2^30;
										framesizeGB = 8 * numel(template) /2^30;
										leap_size = round(ramavailGB/(framesizeGB*2^4));
										first_frame = 1;
										seed = zeros(2,3);
										num_iterations = 4;
										num_levels = 4;
										template = template(roi_rows,roi_cols);
										while first_frame < size(obj.(dataname),4)
												last_frame = min(first_frame + leap_size, size(obj.(dataname),4));
												data = obj.(dataname)(roi_rows,roi_cols,:,first_frame:last_frame);
												alignedData = zeros([imsize 1 size(data,4)],'uint16');
												n_frames = max(size(data,4),last_frame-first_frame+1);
												fprintf('Aligning Frames %i to %i\n',first_frame,last_frame);
												tic
												% Align Images Using Outside Functions
												parfor n = 1:n_frames
														results = ecc(double(data(:,:,:,n)), template, num_levels, num_iterations, 'affine', seed);
														alignedData(:,:,:,n) = imresize(uint16(cat(4,results().image)),imsize);
												end
												fprintf('%i Frames Aligned in %f Seconds\n',n_frames,toc)
												% Write Aligned Data back to Memory-Mapped File
												ind = (1+(first_frame - 1)*prod(imsize)) : (last_frame*prod(imsize));
												obj.videoMemoryObj.(dataname).Data(ind) = alignedData(:);
												first_frame = last_frame + 1;
										end
								end
								matlabpool close
						catch me
								disp(me.message)
								disp(me.stack(1))
								beep
								keyboard
								matlabpool close
						end
				end
				function shiftDataBergen(obj)
						try
								if isempty(obj.dataFields)
										return
								end
								matlabpool open
								for df = 1:numel(obj.dataFields)
										n_iterations = 4;
										n_pyramids = 4;
										dataname = obj.dataFields{df};
										% Make Template
										template = double(obj.(dataname)(:,:,:,1));
										imsize = size(template);
										
										% Get ROI (default is central 75%)
										hfig = imagesc(template);
										hax = gca;
										hm = msgbox('Choose a region to use for motion-correction');
										waitfor(hm);
										rectObj = imrect(hax);
										setPosition(rectObj,...
												[size(template,2)/8    size(template,1)/8 ...
												size(template,2)*3/4 size(template,1)*3/4] );
										setFixedAspectRatioMode(rectObj,true);
										wait(rectObj);
										roi_mask = rectObj.createMask();
										sz = sqrt(sum(roi_mask(:)));
										[roi_I roi_J] = find(roi_mask);
										roi_rows = min(roi_I):max(roi_I);
										roi_cols = min(roi_J):max(roi_J);
										roi_size = [numel(roi_rows) numel(roi_cols)];
										close(gcf);
										
										% Loop To Save Memory? -> Check Memory
										[~,smem] = memory;
										ramavailGB = smem.SystemMemory.Available/2^30;
										framesizeGB = 8 * numel(template) /2^30;
										leap_size = round(ramavailGB/(framesizeGB*2^4));
										first_frame = 1;
										template = template(roi_rows,roi_cols);
										total_frames = size(obj.(dataname),4);
										while first_frame < size(obj.(dataname),4)
												last_frame = min(first_frame + leap_size, size(obj.(dataname),4));
												data = obj.(dataname)(roi_rows,roi_cols,:,first_frame:last_frame);
												alignedData = zeros([imsize 1, size(data,4)],'uint16');
												n_frames = max(size(data,4),last_frame-first_frame+1);
												% 												M = zeros([3 3 n_frames]);
												fprintf('Aligning Frames %i to %i  (of %i)\n',first_frame,last_frame,total_frames);
												tic
												% Align Images Using Outside Functions
												parfor n = 1:n_frames
														% INPUTS: alignImages(im1, im2, iterations, levels, model, option, mask)
														[~, imOut] = alignImages(template,double(data(:,:,:,n)),...
																n_iterations, n_pyramids, 'projective');
														alignedData(:,:,:,n) = imresize(uint16(imOut),imsize);
												end
												% Write Aligned Data back to Memory-Mapped File
												ind = (1+(first_frame - 1)*prod(imsize)) : (last_frame*prod(imsize));
												obj.videoMemoryObj.(dataname).Data(ind) = alignedData(:);
												first_frame = last_frame + 1;
												proc_time = toc;
												proc_fps = n_frames/proc_time;
												fprintf('%i Frames Aligned in %f Seconds  (%0.1f fps)\n',n_frames,proc_time,proc_fps)
										end
								end
								matlabpool close
						catch me
								disp(me.message)
								disp(me.stack(1))
								beep
								keyboard
								matlabpool close
						end
				end
				
		end
		methods % DATA EXPORT
				function export2LegacyFormat(obj)
						if isempty(obj.exportedDataPath)
								obj.exportedDataPath = fullfile(fileparts(obj.processedDataPath),'Mat');
						end
						obj.exportedDataPath = uigetdir(obj.exportedDataPath, ...
								'Choose a Directory for Exported .mat Files');
						obj.exportSynchFile();
						obj.exportMatFiles();
				end
				function exportSynchFile(obj)
						if isempty(obj.exportedDataPath)
								obj.exportedDataPath = obj.processedDataPath;
								obj.exportedDataPath = uigetdir(obj.exportedDataPath, ...
										'Choose a Directory for Exported .mat Files');
						end
						%% Create Blank Synch-File Output Structure
						SynchOutputPrototype = struct(...
										'fileSequence',struct('name',[],'first_frame',[],'last_frame',[]),...
										'frameArrivalTime',[],...
										'frameMean',[],...
										'frameSynch',[]);
								obj.savedSynchFiles = repmat(SynchOutputPrototype,...
										[1, length(obj.channelLabels)]);
									try % New Channel-Number Assignment to Keep with ContImage Convention (Red = 1 ; Green = 2)
									%% Get Channel-To-Number Conversion from User (Default to ContImage Default)
									defaultChannelNumbers = num2str(numel(obj.channelLabels):-1:1)';
									defaultChannelNumbers = cellstr(defaultChannelNumbers(~isspace(defaultChannelNumbers)));
									output = inputdlg(obj.channels,'Designate Channel Numbers...',1,defaultChannelNumbers);
									for n = 1:numel(obj.channelLabels)
										channelNumberAssignment(n) = str2num(output{n});
									end
									catch
										channelNumberAssignment = 1:length(obj.channelLabels);
									end
						for channelNumber = channelNumberAssignment
								%% Define Synch-File Output Structure
								SynchOutput = SynchOutputPrototype;													
								%% File Sequence = trial object info
								trialset = obj.trialSet;
								firstTrialNumber = trialset(1).trialNumber;
								for n = 1:length(trialset)
										a.name = sprintf('%s_%i_%0.5i_%0.5i.mat', ...
												obj.experimentName, channelNumber, firstTrialNumber, trialset(n).trialNumber);
										a.first_frame = trialset(n).firstFrame;
										a.last_frame = trialset(n).lastFrame;
										SynchOutput.fileSequence(n,1) = a;
								end																
								%% Frame Arrival Time - time since start in msec
								SynchOutput.frameArrivalTime = obj.frameTimeFS * 1000;								
								%% Frame Mean -
								SynchOutput.frameMean = obj.(obj.traceFields{channelNumber});								
								%% Frame Synch 5xN array with UDP Messages from BehavCtrl
								% FORMAT:
								% [ 0 ; StimState ; ExptState ; TrialNumber ; 0 ]
								% Stim State
								nframes = length(obj.trialNumberFS);
								stimstate = zeros(nframes,1);
								stimstate(obj.stimStatusFS==1 & isnan(obj.stimNumberFS)) = 100001; % Stim-On
								stimstate(obj.stimStatusFS == 2) = 100002; % Stim-Shift
								stimstate(obj.stimStatusFS == 0) = 100003; % Stim-Off
								for sn = obj.stimNumbers(:)'
										code = 100003 + sn;
										stimstate(obj.stimNumberFS == sn) = code; % Stim-Number
								end
								% Experiment State
								expstate = repmat(2002,[nframes,1]); % always unpaused
								% Trial Number
								trialnumber = obj.trialNumberFS;
								% Put all together in frameSynch matrix
								SynchOutput.frameSynch = [zeros(nframes,1), stimstate(:), expstate(:), trialnumber(:), zeros(nframes,1)]';								
								%% Save
								synchFileName = sprintf('%s_%i_%0.5i_%0.5i_SYNCH.mat', ...
												obj.experimentName, channelNumber, firstTrialNumber, firstTrialNumber);
								fname = fullfile(obj.exportedDataPath,synchFileName);
								fprintf('Saving: %s\n',fname);
								if fname
										save(fname,'-struct','SynchOutput')
								end
								obj.savedSynchFiles(channelNumber) = SynchOutput;
						end
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
				end
				function exportMatFiles(obj)
						if isempty(obj.exportedDataPath)
								obj.exportedDataPath = obj.processedDataPath;
								obj.exportedDataPath = uigetdir(obj.exportedDataPath, ...
										'Choose a Directory for Exported .mat Files');
						end
						try
						if isempty(obj.savedSynchFiles)
								obj.exportSynchFile();
						end
						%% Define Mat-File Output Structure
						MatFilePrototype = struct(...
								'first_image',[],...
								'images',[],...
								'soft',struct('XSize',[],'YSize',[]));%,...
						% 								'frames',[],...
						% 								'type',[],...
						% 								'mat_version',[]);
						for channelNumber = 1:length(obj.channelLabels)
								fileSequence = obj.savedSynchFiles(channelNumber).fileSequence;
								nPixels = size(obj.(obj.dataFields{channelNumber}),1) ...
										* size(obj.(obj.dataFields{channelNumber}),2);
								%% Fill MatFile Structures with Images
								for n = 1:length(fileSequence)
										MatFile = MatFilePrototype;										
										MatFile.images = double(reshape(obj.(obj.dataFields{channelNumber})( ...
												:,:,:, fileSequence(n).first_frame:fileSequence(n).last_frame), ...
												nPixels,[]));
										MatFile.first_image = MatFile.images(:,1);
										MatFile.soft.XSize = obj.resolution(1);
										MatFile.soft.YSize = obj.resolution(2);
										%% Save Structures to Files
										fname = fullfile(obj.exportedDataPath, fileSequence(n).name);
										fprintf('Saving: %s\n',fname);
										if fname
												save(fname,'-struct','MatFile')
										end
								end
						end
						catch me
								beep
								me.message
								me.stack(1)
								keyboard
						end
				end
				function varargout = exportExperimentObject(obj)
						% Delete Previously Constructed Experiment Objects
						if ~isempty(obj.experimentObj)
								try delete(obj.experimentObj); end
						end
						% Create Experiment Object and Mirror Common Non-Dynamic Properties
						experimentProps = properties('Experiment')';
						dataProcessorProps = properties('DataProcessor');
						for n = 1:length(experimentProps)
								if ismember(experimentProps{1,n},dataProcessorProps)
										try
												experimentProps{2,n} = obj.(experimentProps{1,n});
										catch me
												fprintf('Error during experiment export: %s',me.message);
										end
								end
						end
						obj.experimentObj = Experiment(experimentProps{:});
						% Add Data in Dynamic Properties
						for prop_number = 1:numel(obj.metaDynamicPropHandles)
								metaDynamicProp = obj.metaDynamicPropHandles{prop_number};
								switch metaDynamicProp.Name
										case obj.dataFields % video-data
												vprop = addprop(obj.experimentObj,metaDynamicProp.Name);
												vprop.SetAccess = 'private';
												vprop.Transient = true;
												obj.experimentObj.dataPropMetaHandles.(metaDynamicProp.Name) = vprop;
												% Call mapData() Function
												obj.experimentObj.mapData(vprop.Name,obj.videoMemoryObj.(vprop.Name));
										case obj.traceFields % video-trace
												tprop = addprop(obj.experimentObj,metaDynamicProp.Name);
												tprop.SetAccess = 'protected';
												obj.experimentObj.tracePropMetaHandles = tprop;
												% Call addTrace() Function
												obj.experimentObj.addTrace(tprop.Name,obj.(tprop.Name));
								end
						end
						% Call Trial Linking Function
						obj.experimentObj.linkTrials()
						% Return Experiment-Object
						if nargout > 0
								varargout{1} = obj.experimentObj;
						else
								varargout{1} = [];
						end
				end
				function varargout = exportExperimentStruct(obj)
						experimentProps = properties('Experiment')';
						variablename = lower(obj.experimentName);
						for n = 1:length(experimentProps)
								try
										experiment.(variablename).(experimentProps{1,n}) = obj.(experimentProps{1,n});
								catch me
										fprintf('Error during experiment export: %s',me.message);
								end
						end
						if nargout > 0
								varargout{1} = experiment.(variablename);
						else
								fname = ['Experiment_',datestr(obj.startTime,'yyyy_mm_dd_'),obj.experimentName,'.mat'];
								if isempty(obj.exportedDataPath)
										fpath = obj.processedDataPath;
								else
										fpath = obj.exportedDataPath;
								end
								[fname,fpath] = uiputfile(fullfile(fpath,fname), ...
										'Choose a Directory for Exported .mat Files');
								save(fullfile(fpath,fname),'-struct','experiment')
						end
				end
		end
		methods % DATA PRESENTATION
				function showFrameViewer(obj)
						if numel(obj.dataFields)>1
								dataname = questdlg('Choose a channel to display:',...
										'Frame-Viewer: Choose a Channel',obj.dataFields{:},obj.dataFields{1})
						else
								dataname = obj.dataFields{1};
						end
						keyboard
				end
		end
		methods % DEPENDENT PROPERTY GET METHODS
				function nf = get.numFrames(obj)
						if ~isempty(obj.numFramesTS)
								nf = sum(obj.numFramesTS);
						else
								nf = sum(obj.numFramesT);
						end
				end
				function ff = get.firstFrame(obj)
						if ~isempty(obj.firstFrameTS)
								ff = min(obj.firstFrameTS);
						else
								ff = min(obj.firstFrameT);
						end
				end
				function lf = get.lastFrame(obj)
						if ~isempty(obj.lastFrameTS)
								lf = max(obj.lastFrameTS);
						else
								lf = max(obj.lastFrameT);
						end
				end
				function st = get.startTime(obj)
						st = datevec(min(obj.absTimeF(obj.absTimeF>0)));
				end%(frame 'absTime' doesn't match trial 'startTime')
				function st = get.stopTime(obj)
						st = datevec(max(obj.absTimeF));
				end
				% 				function rs = get.resolution(obj)
				% 					if ~isempty(obj.dataFields)
				% 						rs = [size(obj.(obj.dataFields{end}),1) size(obj.(obj.dataFields{end}),2)];
				% 					else
				% 						rs = obj.videoFile(1).resolution;
				% 					end
				% 				end
				function ch = get.channelLabels(obj)
						if ~isempty(obj.channelFS)
								ch = unique(obj.channelFS);
						else
								ch = unique(obj.channelF);
						end
						ch = ch(:);
				end
				function ch =  get.channels(obj)
						ch = cell(1,obj.numChannels);
						for n=1:obj.numChannels
								try
										ch{n} = obj.setting.channelOptions{strmatch(obj.channelLabels(n),obj.setting.channelOptions(:,1)),2};
								catch % if channel-label doesn't match anything in settings structure
										ch{n} = obj.channelLabels(n);
								end
						end
				end
				function tn = get.trialNumberT(obj)
						if ~isempty(obj.trialNumberFS)
								tn = unique(obj.trialNumberFS);
						else
								tn = unique(obj.trialNumberF);
						end
				end
				function sn = get.stimNumbers(obj)
						if ~isempty(obj.stimNumberTS)
								sn = unique(obj.stimNumberTS(~isnan(obj.stimNumberTS)));
						else
								sn = unique(obj.stimNumberF(~isnan(obj.stimNumberF)));
						end
				end
		end
		methods % REFERENCE & UTILITY FUNCTIONS
				function fn = channelFrameNumbers(obj,chanlabel)
						% Returns the frame numbers associated with chanlabel (e.g. 'r')
						% If the seqeuence has repeats (e.g. 'rrgg'  -> rrggrrggrrggrrgg...) then the output
						% will have multiple rows representing each repeat in the sequence
						sequence_index = find(obj.frameDecimationSequence==chanlabel);
						if ~isempty(sequence_index)
								fn = obj.frameDecimationMatMap(sequence_index,:);
						else
								fn = 1:obj.numFrames;
						end
				end
 				function trialNumbers = frames2TrialNumbers(obj,framenumbers,varargin)
						% given a short sequence of frame-numbers for some event (e.g. stimulus-on) and a vector
						% of the first frame for each trial number, this function will return the trial-numbers
						% associated with each frame
						%  Old Code:
						% 						c = union(framenumbers,firstframes);
						% 						trialNumbers = find(ismember(c,framenumbers));
						% 						trialNumbers = trialNumbers - [1:numel(trialNumbers)];
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
% 						trialNumbers(length(framenumbers)) = n+1;
				end
		end
		methods % STATUS CHECK FUNCTIONS
				function mw = ismultichannel(obj)
						mw = max([obj.estimatedSequenceLength numel(obj.channelLabels)]) > 1;
				end
				function nc = numChannels(obj)
						nc = numel(obj.channelLabels);
				end
		end
		methods (Static)% USEFUL UTILITY FUNCTIONS
				function frameSyncVector = event2FrameSync(eventstart,labels,sz)
						try
								frameSyncVector = zeros(sz,1);
								ind = 1:sz;
								for n = 1:numel(labels)-1
										frameSyncVector(ind>=eventstart(n)&ind<eventstart(n+1)) = labels(n);
								end
								frameSyncVector(ind>=eventstart(end)) = labels(end);
						catch me
								beep
								me.message
								me.stack(1)
								keyboard
						end
				end
				function bin_data = spatialBinData(data,binfactor)
					nrows = size(data,1)/binfactor;
					ncols = size(data,2)/binfactor;
					try
						bin_data = reshape(...
							sum(...
							reshape(...
							reshape(...
							sum(...
							reshape(...
							data,...
							binfactor,[]),...
							1),...
							nrows,[])',...
							binfactor,[]),...
							1),...
							ncols,[])';
					catch
						bin_data = data;
					end
				end
		end
		
		
		
		
		
		
		
end











