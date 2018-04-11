classdef newFrameMsg < event.EventData
  
  properties
	 Data % fill with 'Data' structure from videoinput 'FramesAcquiredFcn' inputs
	 image
  end
  
  methods
	 function eventData = newFrameMsg(varargin)
		if nargin > 0
		  eventData.Data = varargin{1};
		end
		if nargin > 1
		  eventData.image = varargin{2};
		end
	 end
  end
end
