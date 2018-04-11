classdef behavMsg < event.EventData
      
     properties
           udpMessage
     end
     
     methods
           function eventData = behavMsg(msg)
                 eventData.udpMessage = msg;
           end
     end
end
