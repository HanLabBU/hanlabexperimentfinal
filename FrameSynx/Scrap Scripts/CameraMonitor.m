classdef CameraMonitor < hgsetget
		
		
		
		properties (Hidden)
				cameraObj
				timerObj
				camReadyListener
				camTriggerListener
				camStopListener
				camErrorListner
				newFrameListener
				dataLoggedListener
		end
		properties
				imageDataDirectory
				timerPeriod
				memoryLeftMinimum
				memoryUsedMaximum
		end
		properties (SetAccess = protected)
				imageInfo
				imageData				
				nNotedFrames
				nAcquiredFrames
		end
		properties (Hidden, SetAccess = protected)
				imageInfoPrototype
		end
		
		
		
		
		events
				Error
				InfoAcquired
				DataAcquired
		end
		
		
		
		methods
				function obj = CameraMonitor(camobj)
						if nargin < 1
								warning('CameraMonitor:CameraMonitor',...
										'No camera passed to CameraMonitor class')
						end
						obj.cameraObj = camobj;
						obj.imageDataDirectory = camobj.imageDataDirectory;
						obj.nNotedFrames = 0;
						obj.nAcquiredFrames = 0;
						obj.timerPeriod = 1;
						obj.memoryLeftMinimum = 300; %in MB
						obj.memoryUsedMaximum = 500;
						obj.timerObj = timer( ...
								'ExecutionMode','fixedSpacing',...
								'TimerFcn',@(src,event)checkCamStatusFcn(obj,src,event),...
								'BusyMode','Queue',...
								'Period',obj.timerPeriod,...
								'Name','CameraMonitorTimer');
						obj.imageInfoPrototype = struct(...
								'FrameCount',[],...
								'FrameNumber',[],...
								'AbsTime',[]);
						obj.imageInfo = repmat(obj.imageInfoPrototype,[10000 1]); %preallocate for 10 minutes
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
% 						obj.newFrameListener = addlistener(obj.cameraObj,...
% 								'FrameAcquired', @(vidObject,event)newFrameFcn(obj,vidObject,event));
						obj.dataLoggedListener = addlistener(obj.cameraObj,...
								'DataLogged',@(vidObject,event)dataLoggedFcn(obj,vidObject,event));
				end
				function camReadyFcn(obj,vidObject,event)
						if ~isdir(obj.imageDataDirectory)
								notify(obj,'Error')
						end
				end
				function camTriggerFcn(obj,vidObject,event)
						if strcmp(obj.timerObj.Running,'off')
								start(obj.timerObj)
						end
				end
				function camStoppedFcn(obj,vidObject,event)
						if strcmp(obj.timerObj.Running,'on')
								stop(obj.timerObj)
						end
				end
				function camErrorFcn(obj,vidObject,event)
						notify(obj,'Error');%TODO: make a central listener for error calls
				end
				function newFrameFcn(obj,vidObject,event)
						try
								fCount = obj.nNotedFrames + 1;
% 								obj.imageInfo(fCount).FrameCount = fCount;
% 								obj.imageInfo(fCount).FrameNumber = event.Data.FrameNumber;
% 								obj.imageInfo(fCount).AbsTime = event.Data.AbsTime;
%THE ABOVE TWO LINES TAKE SOMETHING LIKE 14 MSECS PER FRAME
								notify(obj, 'InfoAcquired'); %TODO: add msg with frame info?
% 								if fCount == length(obj.imageInfo) % prealocating for speed
% 										obj.imageInfo = cat(1,obj.imageInfo,...
% 												repmat(obj.imageInfoPrototype,[10000 1]));
% 								end
						catch me
								warning(me.message)
								notify(obj,'Error');
						end
						obj.nNotedFrames = fCount + 1;
				end
				function dataLoggedFcn(obj,vidObject,event)
% 						obj.dataLoggedSwitch = true;
				end
				function checkCamStatusFcn(obj,src,event)
						imem = imaqmem;
						imemleft = imem.FrameMemoryLimit - imem.FrameMemoryUsed;
						imemusedMB = imem.FrameMemoryUsed/1000000;
						imemleftMB = imemleft/1000000;
						if imemleftMB < obj.memoryLeftMinimum ...
										|| imemusedMB > obj.memoryUsedMaximum
								saveData(obj.cameraObj);%TODO: add support for also saving frame-info
								warning('CameraMonitor:checkCamStatusFcn',...
										'Image Memory Used: %f MB',...
										imemusedMB);
								sprintf('Memory Left: %2.2f MB',imemleftMB)
						end
						mem = memory;
						memmaxavailMB = mem.MaxPossibleArrayBytes/1000000;
						if obj.memoryUsedMaximum > memmaxavailMB -25
								obj.memoryUsedMaximum = memmaxavailMB-25;
						end
						notify(obj,'DataAcquired')
				end
		end
		
		
		
		
end














