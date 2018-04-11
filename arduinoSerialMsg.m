classdef arduinoSerialMsg < event.EventData
      
     
		
		properties
           serialMsg
		 end
		 
		 
		 
		 methods
           function eventData = arduinoSerialMsg(msg)
							 eventData.serialMsg = msg;
           end
		 end
		 
		 
end
