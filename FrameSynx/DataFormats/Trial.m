classdef Trial < hgsetget & dynamicprops
		
		
		
		
		
		properties
				trialNumber
				stimNumber
				numFrames
				firstFrame
				lastFrame
				startTime
		end
		properties %(SetAccess = protected)%Hidden % Frame-Sync Data
				frameNumberFS
				channelFS
				frameTimeFS
				stimStatusFS
				stimNumberFS
		end
		properties % Properties Resulting from Processing
				outcome
		end
		properties (Hidden, Dependent,Transient) %Aliases for Backwards Compatibility
				number
				frameTimes
		end
		properties (Dependent, SetAccess = protected, Transient)
				video
		end
		properties (Transient) % Linking Properties
				experimentObj
				previousTrial
				nextTrial
		end
		
		
		methods % CONSTRUCTOR and Loading Functions
				function obj = Trial(varargin)
						if nargin > 1
								for k = 1:2:length(varargin)
										obj.(varargin{k}) = varargin{k+1};
								end
						end
				end
		end
		methods % GET METHODS
				function tn = get.number(obj)
						tn = obj.trialNumber; % trialNumber Alias
				end
				function vd = get.video(obj)
						if ~isempty(obj.experimentObj) ...
										&& ~isempty(obj.experimentObj.dataFields)
								res = obj.experimentObj.resolution;
								nchannels = numel(obj.experimentObj.dataFields);
								nframes = obj.numFrames;
								dataFields = obj.experimentObj.dataFields;
								datatype = class(obj.experimentObj.(dataFields{1}));
								vd = zeros([res nchannels nframes],datatype);
								for n = 1:nchannels
										vd(:,:,n,:) = obj.experimentObj.(dataFields{n})(:,:,1,obj.frameNumberFS);
								end
						else
								vd = [];
						end
				end
				function ft = get.frameTimes(obj)
						ft = obj.frameTimeFS;
				end
		end
		
		
		
		
end









