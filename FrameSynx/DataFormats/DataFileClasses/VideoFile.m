classdef VideoFile < DataFile
   
   
   
   
   
   properties (SetObservable, GetObservable, AbortSet)% Header Data
	  % 				rootPath
	  % 				headerFileName
	  % 				dataFileName
	  % 				infoFileName
	  resolution
	  numChannels % NOTE: nothing is ever set here... delete?
	  channels
	  bitDepth
	  % 				numFrames
	  % 				firstFrame
	  % 				lastFrame
	  % 				startTime
	  % 				dataType
	  %         dataSize
   end
   properties (Hidden, SetAccess = protected)
	  % 				headerFormat
	  % 				headerMapObj
	  % 				dataFileID
	  % 				infoFileID
	  % 				infoFields
	  % 				infoFormat
	  % 				paddedProps
	  % 				filesOpen
	  % 				filesClosed
	  % 				default
   end
   
   
   
   
   
   
   
   methods % Constructor
	  function obj = VideoFile(varargin)
		 obj = obj@DataFile(varargin{:});
	  end
   end
   methods (Hidden) % Initialization
	  function defineDefaults(obj)
		 obj.defineDefaults@DataFile;
		 obj.default.headerFileName =  ['VideoHeader_',datestr(obj.default.startTime,'yyyy_mm_dd_HHMMSS'),...
			sprintf('_N%i',obj.instanceNumber),'.fhf'];
		 obj.default.dataFileName = ['VideoData_',datestr(obj.default.startTime,'yyyy_mm_dd_HHMMSS'),...
			sprintf('_N%i',obj.instanceNumber),'.fdf'];
		 obj.default.infoFileName = ['VideoFrameInfo_',datestr(obj.default.startTime,'yyyy_mm_dd_HHMMSS'),...
			sprintf('_N%i',obj.instanceNumber),'.fif'];
		 obj.default.bitDepth = 16;
		 obj.default.resolution = [0 0];
		 obj.default.numChannels = 0;
		 obj.default.channels = '**********';
	  end
	  function checkProperties(obj)
		 obj.paddedProps = {'channels'};
		 obj.checkProperties@DataFile;
	  end
   end
   methods % Functions for Saving & Loading
	  function checkFrameInfo(obj,info)
		 % Call Parent-Class Method to Update First/Last Frame-Numbers
		 obj.checkFrameInfo@DataFile(info);
		 % Make Resolution Equal Size of Data Input to addFrame2File()
		 obj.resolution = obj.dataSize;
		 % Update Channels in Video
		 if isfield(info,'Channel')%<<<<<<<<<<<<<<<<<<<<<<<<<<<<NEED TO FIX SOMETHING HERE
			if isempty(strfind(obj.channels,info.Channel))
			   prechans = obj.channels(obj.channels ~= '*');
			   obj.channels = cat(2,char(prechans),char(info.Channel));
			end
		 end
	  end
	  function varargout = getData(obj, varargin)
		 [data, info] = obj.getData@DataFile(varargin{:});
		 if obj(1).numChannels <= 1
			data = squeeze(data);
		 end
		 if nargout > 0
			varargout{1} = data;
			if nargout > 1
			   varargout{2} = info;
			end
		 end
	  end
   end
   methods % Cleanup and State-Check
	  function delete(obj)
		 obj.delete@DataFile;
	  end
	  function obj = saveobj(obj)
		 obj = saveobj@DataFile(obj);
	  end
   end
   methods (Static)
	  function obj = loadobj(obj)
		 obj = obj.loadobj@DataFile;
	  end
   end
   
   
   
   
   
end

% info structure passed to addFrame2File should have the following fields:
% {FrameNumber, Channel,














