classdef stimMsg < event.EventData
   
   properties
      stimNumber
   end
   
   methods
      function eventData = stimMsg(stimnum)
      eventData.stimNumber = stimnum;
      end
   end
   
end
