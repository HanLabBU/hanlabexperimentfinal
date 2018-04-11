classdef ImageDataRecorder < hgsetget
		
		
		
		properties (Hidden)
				cameraObj
				camReadyListener
				camTriggerListener
				camStopListener
				camErrorListner
				newFrameListener
		end
		properties
				imageDataDirectory
		end
		properties (SetAccess = protected)
				imageInfo
				imageData				
				nNotedFrames
				nAcquiredFrames				
		end
		
		
		
		
		events
				Error
				InfoAcquired
				DataAcquired
		end
		
		
		
		methods
				function obj = ImageDataRecorder(camobj)
						if nargin < 1
								warning('No camera passed to ImageDataRecorder class')
						end
						obj.cameraObj = camobj;
						obj.imageDataDirectory = camobj.imageDataDirectory;
						obj.nNotedFrames = 0;
						obj.nAcquiredFrames = 0;
						createListeners(obj)
				end
		end
		methods (Hidden)
				function createListeners(obj)
						obj.camReadyListener = addlistener(obj.cameraObj,...
								'CameraReady', @(vidObject,event)camReadyFcn(obj,vidObject,event));
						obj.camTriggerListener = addlistener(obj.cameraObj,...
								'CameraLogging', @(vidObject,event)camTriggerFcn(obj,vidObject,event));
						obj.camStopListener = addlistener(obj.cameraObj,...
								'CameraStopped', @(vidObject,event)camStoppedFcn(obj,vidObject,event));
						obj.camErrorListner = addlistener(obj.cameraObj,...
								'CameraError', @(vidObject,event)camErrorFcn(obj,vidObject,event));
						obj.newFrameListener = addlistener(obj.cameraObj,...
								'FrameAcquired', @(vidObject,event)newFrameFcn(obj,vidObject,event));
				end
				function camReadyFcn(obj,vidObject,event)
						if ~isdir(obj.imageDataDirectory)
								notify(obj,'Error')
						end						
				end
				function camTriggerFcn(obj,vidObject,event)
						
				end
				function camStoppedFcn(obj,vidObject,event)
						
				end
				function camErrorFcn(obj,vidObject,event)
						
				end
				function newFrameFcn(obj,vidObject,event)
						try
								fCount = obj.nNotedFrames + 1;
								obj.imageInfo.FrameCount(fCount) = fCount;
								obj.imageInfo.FrameNumber(fCount) = event.Data.FrameNumber;
								obj.imageInfo.AbsTime(fCount) = event.Data.AbsTime;
								notify(obj, 'InfoAcquired'); %TODO: add msg with frame info?
								obj.imageData(fCount) = getNextFrame(obj);
								notify(obj, 'DataAcquired');
						catch me
								warning(me.message)
								notify(obj,'Error');
						end
						obj.nNotedFrames = fCount;
				end				
		end
		
		
		
		
end














