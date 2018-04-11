classdef FileViewer < dynamicprops
		
		
		
		
		
		
		properties
				behaviorFile
				videoFile
				trialCompleteThreshold
		end
		properties (Dependent, SetAccess = private) % Trial Info
				trialNumber
				firstFrame
				lastFrame
				nFrames
		end
		properties (Dependent, SetAccess = private) % Frame Info
				
		end
		
		
		
		
		
		
		methods
				function obj = FileViewer(varargin)
						if nargin > 1
								for k = 1:2:length(varargin)
										obj.(varargin{k}) = varargin{k+1};
								end
						end
				end
				function loadFiles(obj)
						[vfile,vdir] = uigetfile('Z:\','Choose a Camera-Session Mat File to Load');
						[bfile,bdir] = uigetfile('Z:\','Choose a Behavior-Session Mat File to Load');
						tmp = struct2cell(load(fullfile(vdir,vfile)));
						obj.videoFile = tmp{:};
						tmp = struct2cell(load(fullfile(bdir,bfile)));
						obj.behaviorFile = tmp{:};						
				end
		end
		methods % Get Methods
				
		end
		
		
		
		
		
		
		
		
		
		methods % Junk
				function randfunc(obj)
						greenframes = [];
						redframes = [];
						stim1frames = [];
						stim2frames = [];
						otherstimframes = [];
						for n = 1:length(behfile)
								% Get Behavior Interface Info (Trial Number, Stim Status, Stim Number)
								bhvinfo = getInfo(behfile(n));
								if isstruct(bhvinfo) ...
												&& any(~isnan(bhvinfo.StimNumber)) ...% Stim was shown
												&& sum(~isnan(bhvinfo.StimNumber)) > obj.stimulusOnThreshold
										% Get Video Info (Time and Channel)
										vidinfo = getInfo(vidfile(n));
										if isstruct(vidinfo)
												
												% Get Stim Frames
												stimnum = unique(bhvinfo.StimNumber(~isnan(bhvinfo.StimNumber)),'first');
												stimonframe = bhvinfo.FrameNumber(find(bhvinfo.StimStatus,1,'first'));
												switch stimnum
														case 1
																stim1frames = cat(1,stim1frames,bhvinfo.FrameNumber(bhvinfo.StimNumber == stimnum));
														case 2
																stim2frames = cat(1,stim2frames,bhvinfo.FrameNumber(bhvinfo.StimNumber == stimnum));
														otherwise
																otherstimframes = cat(1,otherstimframes,bhvinfo.FrameNumber(bhvinfo.StimNumber == stimnum));
												end
												
												% Get Red and Green Frames
												greenframes = cat(1,greenframes,vidinfo.FrameNumber(vidinfo.Channel=='g'));
												redframes = cat(1,redframes,vidinfo.FrameNumber(vidinfo.Channel == 'r'));
												
												% Get Data and Sum Red Frames and Green Frames for each stim
										end
								end
						end
				end
				function getinfo(obj)
				end
		end
		
		
		
		
		
end