classdef dataDumpMsg < event.EventData
      
     properties
					 savedData
     end
     
     methods
           function eventData = dataDumpMsg(varargin)
							 if nargin > 0
									 eventData.savedData = varargin{1};
							 end
           end
     end
end
