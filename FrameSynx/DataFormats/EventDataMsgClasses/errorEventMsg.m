classdef errorEventMsg < event.EventData
      
     properties
				 message
				 
     end
     
     methods
           function eventData = errorEventMsg(varargin)
							 if nargin > 0
                 eventData.message = varargin{1};
							 end
           end
     end
end
%NOTE: this hasn't been used yet, was planned for ImageDataRecorder class