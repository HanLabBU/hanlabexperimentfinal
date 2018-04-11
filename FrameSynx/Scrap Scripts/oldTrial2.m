classdef Trial < hgsetget & dynamicprops
		
		
		
		
		properties
				% Names, Paths, and Info
				number
				numberInSet
				experimentName
				trialFilePath
				defaultSaveMethod %= 'tomemorymap' % or 'toobject' or 'todisk' or 'tomat' or 'tohybrid'
				videoMemoryObj
				
				% Frame Info
				frameTimes %note: redundant, should be folded into frameSyncData
				frameSyncData
				
				% Stimulus Info
				stimulus
				stimName %note: get stimName from user defined edit boxes matched to numbers
				
				% Trial Type Info
				outcome % EarlyAbort, CompleteStim, NoAttempt, CompleteBlank
		end
		properties (Dependent)
				video
		end
		properties (Dependent, SetAccess = protected)
				videoPath
				
				% Frame Assigment from frameSyncData
				firstFrame
				lastFrame
				stimOnFrame
				stimShiftFrame
				stimOffFrame
				
				% Duration
				stimDuration
				numFrames
				timeDuration
				framesDuration
				
				% Properties Extracted from frameSyncData
				stimFrames
				channels
				numChannels
				
				% Processed Data Properties
				trace
		end
		properties (SetAccess = protected)
				rawVid
				metaInfo
				vidFormat = 'uint16';%TODO: get this from camera
		end
		
		
		
		
		methods % Constructor
				function obj = Trial(tnumber)
						try
						if nargin<1
								disp('Must specify a Trial number when instantiating a Trial');
								disp(tnumber)
						else
								obj.number = tnumber;
						end
						catch me
								warning(me.message)
								disp('error in Trial')
						end
						obj.defaultSaveMethod = 'todisk';
				end
		end
		
		methods % Frame Assigment Get Methods
				function firstframe = get.firstFrame(obj)
						firstframe = obj.frameSyncData.FrameNumber(1);
				end
				function lastframe = get.lastFrame(obj)
						lastframe = obj.frameSyncData.FrameNumber(end);
				end
				function son = get.stimOnFrame(obj)
						son = find(obj.frameSyncData.StimStatus == 1, 1, 'first');
						%NOTE: Making change here -> turning stimOnFrame into NaN if no value is found!!
						if isempty(son)
								son = NaN;
						end
				end
				function ssf = get.stimShiftFrame(obj)
						ssf = find(obj.frameSyncData.StimStatus == 2, 1, 'first');
						% NOTE: Making same change here-> empty stimShiftFrame becomes NaN (april 6)
						if isempty(ssf)
								ssf = NaN;
						end
				end
				function sof = get.stimOffFrame(obj)
						stimstates = unique(obj.frameSyncData.StimStatus);
						sof = find(obj.frameSyncData.StimStatus == stimstates(end), 1, 'last');
				end
				function sframes = get.stimFrames(obj)
						sframes =  find(obj.frameSyncData.StimStatus ~= zero);
				end
		end
		
		methods % Set/Get Methods
				function set.video(obj,vid)
						try
						vidinfo = whos('vid');
						obj.vidFormat = vidinfo.class;
						if isempty(obj.trialFilePath)
								obj.trialFilePath = ['trial_',num2str(obj.number),'_',...
										datestr(now,'mmmdd_HHMMSSPM')];
						end
						switch lower(obj.defaultSaveMethod(3:5))
								case 'obj'
										obj.rawVid = vid;
								case {'dis','hyb'}
										fname = obj.videoPath;
										vidSize = size(vid);
										vidDimensions = size(vidSize,2);
										fid = fopen(fname,'wb');%big-endian?
										fwrite(fid,[vidDimensions,vidSize],'uint16');
										fwrite(fid,vid(:),obj.vidFormat);
										fclose(fid);
										
										% File Format: [vidDimensions dim1 dim2 ... videodata.........
										% e.g.    4 256 256 1 150 1423 1402 1404 1399 ....
								case 'mem'
										fname = obj.videoPath;
										vidSize = size(vid);
										vidDimensions = size(vidSize,2);
										fid = fopen(fname,'wb');%big-endian?
										fwrite(fid,[vidDimensions,vidSize],'uint16');
										fwrite(fid,vid(:),obj.vidFormat);
										fclose(fid);
										obj.videoMemoryObj = memmapfile(fname,...
												'Format',{...
												'uint16' [1 1] 'vidDimensions';...
												'uint16' [1 vidDimensions] 'vidSize';...
												'uint16' vidSize  'video'});
								case 'mat'
										save(obj.videoPath,'vid');
						end
						catch me
								beep
								warning(me.message)
						end
				end
				function vid = get.video(obj)
						switch lower(obj.defaultSaveMethod(3:5))
								case 'obj' % as Trial objects
										vid = obj.rawVid;
								case 'dis' % stupid buk files
										if isempty(obj.videoPath)
												vid = [];
										else
												fid = fopen(obj.videoPath,'r');
												try
														vidDimensions = fread(fid,1,'uint16');
														vidSize = fread(fid,vidDimensions,'uint16');
														vid = fread(fid,prod(vidSize),['*',obj.vidFormat]);
												catch me
														warning(me.message)
												end
												fclose(fid);
												try
														vid = reshape(vid,vidSize');
												catch me
														warning(me.message)
												end
										end
								case 'mem'
										if isempty(obj.videoMemoryObj)
												vid = [];
										else
												try
														vid = obj.videoMemoryObj.Data.video;
												catch me
														beep														
													  disp('if you end up here, write a new way to reset the videomemoryObject file location');
														warning(me.message)
												end
										end
								case 'hyb'
										try
												fname = obj.videoPath;
												memmapobject = Camera.mapVidFileStatic(fname,obj.vidFormat);
												vid = memmapobject.Data.video;
										catch me
												beep
												warning(me.message)
										end
								case 'mat' %slow mat files
										tmp = load(obj.videoPath);
										vid = tmp.vid;
										clear tmp
						end
				end
				function videosavepath = get.videoPath(obj)
						if ~isempty(obj.trialFilePath)
								videosavepath = [obj.trialFilePath,'_raw_video.buk'];
						else
								videosavepath = [];
						end
				end
				function frames = get.numFrames(obj)
						if ~isempty(obj.lastFrame) && ~isempty(obj.firstFrame)
								frames = obj.lastFrame - obj.firstFrame + 1;
						elseif ~isempty(obj.trace)
								frames = length(obj.trace);
						else
								frames = 0;
						end
				end
				function ttime = get.timeDuration(obj)
						ttime = obj.frameTimes(end) - obj.frameTimes(1);
				end
				function ftime = get.framesDuration(obj)
						ftime = obj.numFrames;
				end
				function chans = get.channels(obj)
						chans = unique(obj.frameSyncData.Channel);
				end
				function num = get.numChannels(obj)
						num = length(unique(obj.frameSyncData.Channel));
				end
				function trace = get.trace(obj)
						if ~isempty(obj.video)
								trace = squeeze(squeeze(squeeze(mean(mean(mean(obj.video,1),2),3))));
						else
								trace = [];
						end
				end
		end
		methods %parsing frames
				function vid = parseChannels(obj,chanlabel)
						[ind,column] = find(obj.frameSyncData.Channel==chanlabel);						
						vid = obj.video(:,:,1,ind);
				end
		end
		
		
end





%TODO: account for changes in the savepath of the video









% Utility Functions










