classdef DataPostProcessor < hgsetget & dynamicprops
		
		
		
		
		
		
		properties % Data Files
				experimentName
				videoFile
				behaviorFile
				processedDataPath
		end
		properties % (SetAccess = protected)
				trialSet
				dataFields				
		end
		properties (Dependent, SetAccess = protected) % Experiment Header Info from Video-File
				numFrames
				firstFrame
				lastFrame
				startTime
				stopTime
				resolution
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
				stimStartTS
				stimStopTS
				stimShiftTS
				stimLengthTS
				stimNumberTS
				trialNumberTS
		end
		properties (SetAccess = protected, Hidden) % Working Variables and Storage
				missingVideoFileFrames
				missingBehaviorFileFrames
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
								'u','ultraviolet'};
						obj.setting.addSequenceRepeats = true;
						obj.setting.nFramesPreTrigger = 15;
						obj.setting.nFramesPostTrigger = 45;
						obj.setting.stimLengthMinFrames = [];
						obj.setting.trialLengthMinFrames = [];
						% Setup
						if isempty(obj.videoFile) || isempty(obj.behaviorFile)
								obj.loadFiles();
						end
						obj.readFiles();
						% Examine and Fix Channel Issues (zeroes -> spaces)
						if any(~isletter(obj.channelF))
								obj.fixChannelLabels();
						end
						obj.makeSingleChannelTrials();
						% Fix Frame-Assignment to Accomodate Multi-Wavelength Sequences
						if ~obj.ismultichannel
								obj.trialSet = obj.singleChannelTrialSet;
						else
								obj.fixFrameAssignment()
								obj.makeMultiChannelTrials()
						end
						obj.makeDataProps();
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
		methods % DATA IMPORT
				function loadFiles(obj)
						[vfile,vdir] = uigetfile('Z:\','Choose a Camera-Session Mat File to Load');
						[bfile,bdir] = uigetfile('Z:\','Choose a Behavior-Session Mat File to Load');
						tmp = struct2cell(load(fullfile(vdir,vfile)));
						obj.videoFile = tmp{:};
						tmp = struct2cell(load(fullfile(bdir,bfile)));
						obj.behaviorFile = tmp{:};
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
						vinfo = getInfo(obj.videoFile);%info-struct array
						binfo = getInfo(obj.behaviorFile);
						vidframenumber = cat(1,vinfo.FrameNumber);
						bhvframenumber = cat(1,binfo.FrameNumber);
						bhvframenumber = bhvframenumber-bhvframenumber(1)+1; % avoid consecutive experiment error
						obj.frameNumberF = union(vidframenumber,bhvframenumber);
						% 						[~, vindex, bindex] = intersect(vidframenumber,bhvframenumber);
						% Concatentate Frame-Info (along trials)
						channel = cat(1,vinfo.Channel);
						frametime = cat(1,vinfo.FrameTime);
						abstime = cat(1,vinfo.AbsTime);
						trialnumber = cat(1,binfo.TrialNumber);
						stimstatus = cat(1,binfo.StimStatus);
						stimnumber = cat(1,binfo.StimNumber);
						% Assign Info to Frames
						obj.channelF(vidframenumber) = char(channel);
						obj.frameTimeF(vidframenumber) = frametime;
						obj.absTimeF(vidframenumber) = abstime;
						obj.trialNumberF(bhvframenumber) = trialnumber;
						obj.stimStatusF(bhvframenumber) = stimstatus;
						obj.stimNumberF(bhvframenumber) = stimnumber;
						% Record Missing Frames (for debugging/informational purposes?)
						[~,ia,ib] = setxor(vidframenumber,bhvframenumber);
						obj.missingVideoFileFrames = vidframenumber(ia);
						obj.missingBehaviorFileFrames = bhvframenumber(ib);
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
										'Illumination Sequence Alignment','Yes','Shift Left','Shift Right','Yes');
								switch lower(answer)
										case 'shift left'
												obj.illuminationSequence = circshift(obj.illuminationSequence',-1)';
												obj.channelF = circshift(obj.channelF',-1)';
												clf
										case 'shift right'
												obj.illuminationSequence = circshift(obj.illuminationSequence',1)';
												obj.channelF = circshift(obj.channelF',1)';
												clf
										case 'yes'
												close
												break
								end
						end
				end
				function makeSingleChannelTrials(obj)
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
												'frameNumberF',obj.frameNumberF(frx),...
												'channelF',obj.channelF(frx),...
												'frameTimeF',obj.frameTimeF(frx),...
												'stimStatusF',obj.stimStatusF(frx),...
												'stimNumberF',obj.stimNumberF(frx));
										sftrial.stimNumber = mode(sftrial.stimNumberF(~isnan(sftrial.stimNumberF)));
										sftrial.numFrames = numel(sftrial.frameNumberF);
										sftrial.firstFrame = sftrial.frameNumberF(1);
										sftrial.lastFrame = sftrial.frameNumberF(end);
										sftrial.startTime = sftrial.frameTimeF(1);
										obj.singleChannelTrialSet(n) = sftrial;
								catch me
% 										keyboard
fprintf('error in Experiment > makeSingleChannelTrials\n')
								end
						end
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
						num_block_frames = floor((obj.numFrames-firstframe+1)/sl)-1;
						space_index = firstframe:sl:num_block_frames*sl;
						mat_index = uint32(reshape(firstframe:num_block_frames*sl+firstframe-1,sl,[]));
						obj.frameDecimationMatMap = mat_index;
						obj.frameNumberFS = obj.frameNumberF(space_index );
						obj.channelFS = obj.channelF(mat_index);
						obj.frameTimeFS = obj.frameTimeF(space_index );
						obj.trialNumberFS = obj.trialNumberF(space_index );
						obj.stimStatusFS = mode(obj.stimStatusF(mat_index),1);
						obj.stimNumberFS = mode(obj.stimNumberF(mat_index),1);
						obj.trialNumberTS = unique(obj.trialNumberFS)';
						obj.numFramesTS = sum(bsxfun(@eq, obj.trialNumberTS ,...
								repmat(obj.trialNumberFS,[numel(obj.trialNumberTS) 1])),2);
						[trial_ind, ~] = find(bsxfun(@eq,obj.trialNumberTS,...
								repmat(obj.trialNumberFS,[numel(obj.trialNumberTS) 1])));
						[~,obj.firstFrameTS,~] = unique(trial_ind,'first');
						[~,obj.lastFrameTS,~] = unique(trial_ind,'last');
						catch me
								keyboard
						end
				end
				function makeMultiChannelTrials(obj)
						% Work Through Sequenced/MultiChannel Trial Info
						stimstarts = find(  diff(obj.stimStatusFS)>0  & obj.stimStatusFS(2:end)==1 );
						stimshifts =  find(  diff(obj.stimStatusFS)>0  & obj.stimStatusFS(2:end)==2 );
						stimstops =  find(  diff(obj.stimStatusFS)<0  & obj.stimStatusFS(2:end)==0 );
						stimstarts = stimstarts(stimstarts<stimstops(end));
						stimshifts = stimshifts(stimshifts<stimstops(end));
						obj.stimLengthTS = stimstops-stimstarts;
						obj.stimNumberTS = obj.stimNumberFS(stimstarts+1);
						obj.stimStartTS = stimstarts;
						obj.stimShiftTS = stimshifts;
						obj.stimStopTS = stimstops;
						
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
						fprintf('Stimulus Length Minimum: %i frames\n',stim_length_min)
						fprintf('Trial Length Minimum: %i frames\n',trial_length_min)
						% Calculate Property Values for All Trials in Set
						for n=1:ntrials
								frx = obj.trialNumberFS == obj.trialNumberTS(n);
								sftrial = Trial(...
										'trialNumber',obj.trialNumberTS(n),...
										'frameNumberF',obj.frameNumberFS(frx),...
										'channelF',obj.channelFS(:,find(frx)),...
										'frameTimeF',obj.frameTimeFS(frx),...
										'stimStatusF',obj.stimStatusFS(frx),...
										'stimNumberF',obj.stimNumberFS(frx));
								sftrial.stimNumber = mode(sftrial.stimNumberF(~isnan(sftrial.stimNumberF)));
								sftrial.numFrames = numel(sftrial.frameNumberF);
								sftrial.firstFrame = sftrial.frameNumberF(1);
								sftrial.lastFrame = sftrial.frameNumberF(end);
								sftrial.startTime = sftrial.frameTimeF(1);
								% Determine Trial Outcome
								trial_condition = false; stim_condition = false;
								if sftrial.numFrames >= trial_length_min 
										trial_condition = true;
								end
								if sum(logical(sftrial.stimStatusF)) >= stim_length_min
										stim_condition = true;
								end
								if  trial_condition & stim_condition
										sftrial.outcome = 'Complete Stim';
								elseif trial_condition & ~stim_condition
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
								mprop.Dependent = true;
								mprop.SetAccess = 'private';
								obj.metaDynamicPropHandles{n,1} = mprop;
								obj.makeFrameNumbers(chanlabel);
								% 								mprop.GetMethod = @(obj)channelFrameNumbers(obj,obj.channelLabels(n));
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
								obj.makeTrace(chanlabel);
								% Make Triggered Average Props
								sprop = addprop(obj,sprintf('%sTriggeredAverage',obj.channels{n}));
								sprop.SetAccess = 'protected';
								obj.metaDynamicPropHandles{n,6} = sprop;
								obj.makeTriggeredAverage(chanlabel);
						end
				end
		end
		methods % DATA IMPORT SUBFUNCTIONS
				function makeFrameNumbers(obj,chanlabel)
						% Returns the frame numbers associated with chanlabel (e.g. 'r')
						% If the seqeuence has repeats (e.g. 'rrgg'  -> rrggrrggrrggrrgg...) then the output
						% will have multiple rows representing each repeat in the sequence
						propname = sprintf('%sFrameNumbers',obj.channels{strfind(obj.channelLabels,chanlabel)});
						sequence_index = find(obj.frameDecimationSequence==chanlabel);
						if ~isempty(sequence_index)
								obj.(propname) = obj.frameDecimationMatMap(sequence_index,:);
						end
				end
				function makeVidFrameInfo(obj,chanlabel)
						try
								propname = sprintf('%sVidFrameInfo',obj.channels{strfind(obj.channelLabels,chanlabel)});
								obj.(propname) = getInfo(obj.videoFile,'cat','FrameNumber',...
										obj.channelFrameNumbers(chanlabel));
						catch
								obj.(propname) = [];
						end
				end
				function makeBhvFrameInfo(obj,chanlabel)
						try
								propname = sprintf('%sBhvFrameInfo',obj.channels{strfind(obj.channelLabels,chanlabel)});
								obj.(propname) = getInfo(obj.behaviorFile,'cat',...
										'FrameNumber',obj.channelFrameNumbers(chanlabel));
						catch
								obj.(propname) = [];
						end
				end
				function makeData(obj,chanlabel)
						% Procedure: Read from video-files and save the video data using one of a variety of
						% methods. If the OS is 64-bit, it will be written to a file memory-mapped using virtual
						% address space.
						propname = sprintf('%sData',obj.channels{strfind(obj.channelLabels,chanlabel)});
						try
								isempty(obj.(propname));
						catch % re-add the dynamic prop (redData or greenData) if lost between saving
								vprop = addprop(obj,propname);
								vprop.SetAccess = 'private';
								vprop.Transient = true;
						end
						% Write File
						% Get Info for a File Header
						if isfield(obj.filepaths,propname) ...
								&& exist(obj.filepaths.(propname),'file') == 2
								fname = obj.filepaths.(propname);
						else
								obj.setPath
								fname = fullfile(obj.processedDataPath,propname);
						end
						obj.filepaths.(propname) = fname;
						if ~(exist(fname,'file') == 2)
								% 						fid = fopen(fname,'w+t'); % (open for writing text)
								% 						sampdata = getData(obj.videoFile(1),1:3);
								% 						precision = class(sampdata);
								% 						resolution = [size(sampdata,1) size(sampdata,2)];
								% 						record_date = datevec(obj.videoFile(1).startTime);
								% 						experiment_name = obj.behaviorFile(2).experimentName;
								% Write Header
								% 						fprintf(fid,'Name: %s\n',experiment_name);
								% 						fprintf(fid,'Data-Set: %s\n',propname);
								% 						fprintf(fid,'Date: %s\n',record_date);
								% 						fprintf(fid,'Resolution: %s\n',resolution);
								% 						fprintf(fid,'Precision:  %s\n',precision);
								% 						fprintf(fid,'Data begins at offset byte 512. Use  >> fset(fid,512,''bof''), data = fread(fid,''uint16'')\n');
								% 						fseek(fid,500,'bof');
								% 						fprintf(fid,'DATA:\n');
								% 						fclose(fid);
								% 						% Write Data
								% 						fid = fopen(fname,'ab');
								% 						fseek(fid,512,'bof');
								fid = fopen(fname,'wb');
								framenumbers = obj.channelFrameNumbers(chanlabel);
								szf = size(framenumbers);
								nrepeats = szf(1);
								lastdata = [];
								nframes_written = 0;
								framenumbers_acquired = [];
								fprintf('Writing %s to File: %s\n',propname,fname);
								% Account for Missing Frames
								info = getInfo(obj.videoFile,'cat','FrameNumber',framenumbers);
								total_frames = size(obj.frameDecimationMatMap,2);
								[missing_frames, missing_frame_index] = setdiff(framenumbers(:),info.FrameNumber(:))
								for n = 1:numel(obj.videoFile)
										[data,info] = getData(obj.videoFile(n),'FrameNumber',framenumbers);
										framenumbers_acquired = cat(1,framenumbers_acquired,info.FrameNumber(:));
										% Check for Missing Frames
										[missing_from_file1,ind1] = intersect(info.FrameNumber(:)+1,missing_frames(:));
										[missing_from_file2,ind2]  = intersect(missing_frames(:), info.FrameNumber(:)-1);
										try
												if ~isempty(missing_from_file1) % Replace Frame with a Copy of Next Frame
														data = cat(4,data(:,:,:,1:ind1-1),data(:,:,:,ind1),data(:,:,:,min(ind1+1,size(data,4)):end));
												elseif ~isempty(missing_from_file2) % Replace Frame with Previous Frame Copy
														data = cat(4,data(:,:,:,1:max(ind2,1)), data(:,:,:,ind2), data(:,:,:,ind2+1:end));
												end
										catch me
												keyboard
										end
										data = cat(4,lastdata,data);
										frames_this_file = nrepeats*floor(size(data,4)/nrepeats);
										if frames_this_file < size(data,4)
												lastdata = data(:,:,:,frames_this_file+1:size(data,4));
												data = data(:,:,:,1:frames_this_file);
										else
												lastdata = [];
										end
										if szf(1) > 1 && obj.setting.addSequenceRepeats % repeated frames in sequence ('rrgg')
												szd = size(data);
												data = uint16(sum(reshape(data,szd(1),szd(2),szf(1),[]),3));
										end
										fwrite(fid,data(:),obj.videoFile(1).dataType);
										nframes_written = nframes_written + size(data,4);
										fprintf('Written %i of %i frames\n',nframes_written, total_frames);
								end
								fclose(fid);
						end
						% Create a Memory Map
						obj.videoMemoryObj.(propname) = memmapfile(fname,...
								'Format',obj.videoFile(1).dataType);
						try
								obj.(propname) = reshape(obj.videoMemoryObj.(propname).Data,...
										obj.resolution(1),obj.resolution(2),1,[]);
						catch me
								fclose('all');
								obj.(propname) = reshape(obj.videoMemoryObj.(propname).Data,...
										obj.resolution(1),obj.resolution(2),1,[]);
						end
				end
				function makeTrace(obj,chanlabel)
						maptrace = false;
						propname = sprintf('%sTrace',obj.channels{strfind(obj.channelLabels,chanlabel)});
						dataname = sprintf('%sData',obj.channels{strfind(obj.channelLabels,chanlabel)});
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
								obj.(propname) = mean(reshape(obj.(dataname),prod(obj.videoFile(1).resolution),[]));
						end
				end
				function makeTriggeredAverage(obj,chanlabel)
						try
								propname = sprintf('%sTriggeredAverage',obj.channels{strfind(obj.channelLabels,chanlabel)});
								dataname = sprintf('%sData',obj.channels{strfind(obj.channelLabels,chanlabel)});
								stimstarts = obj.stimStartTS;
								stimshifts = obj.stimShiftTS;
								stimstops = obj.stimStopTS;
								stimlengths = obj.stimLengthTS;
								stimnums = obj.stimNumberTS;
								prestim = -obj.setting.nFramesPreTrigger;
								poststim = obj.setting.nFramesPostTrigger;
								if ~isempty(obj.setting.stimLengthMinFrames)
										stim_min = obj.setting.stimLengthMinFrames;
								else
										stim_min = mode(stimlengths)-1; % (1-frame tolerance)
								end
								stimrelative_index = prestim:poststim-1;
								stim = unique(stimnums);
								for n=1:numel(stim)
										ind = stimnums == stim(n);
										ind = ind & stimlengths == stim_min | stimlengths == stim_min+1;
										ind = ind & stimstarts+stim_min+poststim <=size(obj.(dataname),4);
										ind = ind & (stimstarts + min(prestim(:))) > 0;
										firstframe = stimstarts(ind);
										[X,Y] = meshgrid(firstframe, stimrelative_index );
										index_mat = X+Y;
										obj.(propname).(sprintf('stim%i',n)) = ...
												mean(reshape(obj.(dataname)(:,:,:,index_mat),...
												[obj.resolution 1 size(index_mat)]),5);
								end
						catch me
								keyboard
								fprintf('%s failed to complete...\n',propname)
						end

				end
		end
		methods % DEPENDENT PROPERTY GET METHODS
				function nf = get.numFrames(obj)
						nf = sum(obj.numFramesT);
				end
				function ff = get.firstFrame(obj)
						ff = min(obj.firstFrameT);
				end
				function lf = get.lastFrame(obj)
						lf = max(obj.lastFrameT);
				end
				function st = get.startTime(obj)
						st = datevec(min(obj.absTimeF(obj.absTimeF>0)));
				end%(frame 'absTime' doesn't match trial 'startTime')
				function st = get.stopTime(obj)
						st = datevec(max(obj.absTimeF));
				end
				function rs = get.resolution(obj)
						rs = obj.videoFile(1).resolution;
				end
				function ch = get.channelLabels(obj)
						ch = unique(obj.channelF);
				end
				function ch =  get.channels(obj)
						ch = cell(1,obj.numChannels);
						for n=1:obj.numChannels
								ch{n} = obj.setting.channelOptions{strmatch(obj.channelLabels(n),obj.setting.channelOptions(:,1)),2};
						end
				end
				function tn = get.trialNumberT(obj)
						tn = unique(obj.trialNumberF);
				end
				function sn = get.stimNumbers(obj)
						sn = unique(obj.stimNumberF(~isnan(obj.stimNumberF)));
				end
		end
		methods % HIDDEN REFERENCE FUNCTIONS
				function fn = channelFrameNumbers(obj,chanlabel)
						% Returns the frame numbers associated with chanlabel (e.g. 'r')
						% If the seqeuence has repeats (e.g. 'rrgg'  -> rrggrrggrrggrrgg...) then the output
						% will have multiple rows representing each repeat in the sequence
						sequence_index = find(obj.frameDecimationSequence==chanlabel);
						if ~isempty(sequence_index)
								fn = obj.frameDecimationMatMap(sequence_index,:);
						end
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
		
		
		
		
		
		
		
		
end











