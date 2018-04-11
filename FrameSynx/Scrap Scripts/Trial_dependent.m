classdef Trial < hgsetget & dynamicprops
		
		
		
		
		
		
		properties (Dependent, SetAccess = protected) % Directly Files
				trialNumber
				stimNumber
				numFrames
				firstFrame
				lastFrame
				startTime
		end
		properties (Dependent, SetAccess = protected) % Processed 		
				
		end
		properties (Dependent, SetAccess = protected, Hidden) % From File Info Structure
				
		end
		properties (Hidden)
				behaviorFile
				videoFile
		end
		
		
		
		methods % CONSTRUCTOR and Loading Functions
				function obj = Trial(behfile,vidfile)
						obj.behaviorFile = behfile;
						obj.videoFile = vidfile;
						if behfile.trialNumber ~= vidfile.trialNumber
								error('Trial Numbers Do Not Match')
						end
				end
		end
		methods % Direct From File GET Methods
				function tn = get.trialNumber(obj)
						tn = obj.behaviorFile.trialNumber;
				end
				function sn = get.stimNumber(obj)
						sn = obj.behaviorFile.stimNumber;
				end
				function nf = get.numFrames(obj)
						nf = min([obj.videoFile.numFrames obj.behaviorFile.numFrames]);
				end
				function ff = get.firstFrame(obj)
						ff = obj.videoFile.firstFrame;
				end
				function lf = get.lastFrame(obj)
						lf = obj.videoFile.lastFrame;
				end
				function st = get.startTime(obj)
						st = min([obj.videoFile.startTime obj.behaviorFile.startTime]);
						st = datevec(st);
				end
		end
		
		methods % Set/Get Methods
				function set.video(obj,vid)
						try
						vidinfo = whos('vid');
						obj.vidFormat = vidinfo.class;
						if isempty(obj.trialFilePath)
								obj.trialFilePath = ['trial_',num2str(obj.trialNumber),'_',...
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
						chans = unique(obj.videoFile.Channel);
				end
				function num = get.numChannels(obj)
						num = length(unique(obj.videoFile.Channel));
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
						[ind,column] = find(obj.videoFile.Channel==chanlabel);						
						vid = obj.video(:,:,1,ind);
				end
		end
		
		
		
		
end











