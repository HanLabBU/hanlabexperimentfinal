classdef ledSensorMsg < event.EventData
      
     
		
		properties
           channelLabel
		 end
		 
		 
		 
		 methods
           function eventData = ledSensorMsg(msg)
							 eventData.channelLabel = msg;
           end
		 end
		 
		 
end
