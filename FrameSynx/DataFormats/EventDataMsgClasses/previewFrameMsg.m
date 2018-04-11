classdef previewFrameMsg < event.EventData
      
     properties
           previewEvent % fill with 'Data' structure from videoinput 'FramesAcquiredFcn' inputs
					 hImage
     end
     
     methods
           function eventData = previewFrameMsg(evnt,himage)
                 eventData.previewEvent = evnt;
									 eventData.hImage = himage;
           end
     end
end
