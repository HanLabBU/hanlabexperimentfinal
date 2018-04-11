classdef EyeCamSystem < SubSystem
   
   
   
   
   
   
   
   properties % OBLIGATORY
	  experimentSyncObj
	  trialSyncObj
	  frameSyncObj
   end
   properties	  
	  cameraObj
   end
   properties (Hidden)
	  lastError
   end
   
   
   
   
   events
	  ExperimentStart
	  ExperimentStop
	  NewTrial
	  NewStimulus
	  FrameAcquired
   end
   
   
   
   
   
   
   
   methods % SETUP
	  function obj = EyeCamSystem(varargin)
		 if nargin > 1
			for k = 1:2:length(varargin)
			   obj.(varargin{k}) = varargin{k+1};
			end
		 end
		 obj.defineDefaults()
		 obj.checkProperties()
		 obj.updateExperimentName()
		 obj.createSystemComponents()
	  end
	  function defineDefaults(obj)
		 persistent instancenum
		 if isempty(instancenum)
			instancenum = 1;
		 else
			instancenum = instancenum+1;
		 end
		 obj.defineDefaults@SubSystem;
		 obj.default.autoSaveFrequency = 10;
	  end
	  function checkProperties(obj)
		 obj.savedDataFiles = VideoFile.empty(1,0);
		 obj.currentDataFileSet = VideoFile.empty(1,0);
		 obj.framesAcquired = 0;
		 obj.checkProperties@SubSystem;
	  end
	  function createSystemComponents(obj)
		 % (Required by SubSystem Parent Class)
		 % CREATE CAMERA
% 		 obj.cameraObj =  Camera(...
% 			'camAdaptor', 'pointgrey',...
% 			'videoFormat',  'F7_Mono8_656x524_Mode4');
		 setup(obj.cameraObj);
		 obj.cameraObj.videoInputObj.FramesPerTrigger = 1;
		 obj.cameraObj.videoInputObj.LoggingMode = 'memory';
		 trigconfig = struct(...
			'TriggerType','hardware',...
			'TriggerCondition','RisingEdge',...
			'TriggerSource','externalTriggerMode1-Source0');
		 obj.cameraObj.triggerConfiguration = trigconfig;
		 obj.cameraObj.videoInputObj.FramesAcquiredFcn = @(src,evnt)frameAcquiredFcn(obj,src,evnt);
	  end
   end
   methods % CONTROL
	  function start(obj)
		 % (Required by SubSystem Parent Class)
		 obj.updateExperimentName()
		 fprintf('STARTING VRSYSTEM:\n\tSession-Path: %s\n',...
			obj.sessionPath);
		 if ~isdir(obj.sessionPath)
			mkdir(obj.sessionPath)
		 end
		 if isempty(obj.frameSyncListener)
			warning('EyeCamSystem:start:NoFrameSyncListener',...
			   'The Behavior-Control sysem is not connected to a camera, and will not record data every frame');
		 else
			obj.frameSyncListener.Enabled = true;
		 end
		 obj.trialStateListener.Enabled = true;
		 obj.experimentStateListener.Enabled = true;
		 obj.ready = true;
		 obj.experimentRunning = false;
		 fprintf('EyeCamSystem ready... waiting for ExperimentStart event from Virmen\n');
	  end
	  function stop(obj)
		 % (Required by SubSystem Parent Class)
		 if ~isempty(obj.frameSyncListener)
			obj.frameSyncListener.Enabled = false;
		 end
		 obj.trialStateListener.Enabled = false;
		 obj.experimentStateListener.Enabled = false;
		 if obj.experimentRunning
			obj.experimentRunning = false;
			if ~isempty(obj.currentDataFile) ...
				  && isopen(obj.currentDataFile) ...
				  && ~issaved(obj.currentDataFile)
			   obj.saveDataFile;
			   obj.currentDataFile = VideoFile.empty(1,0);
			end
			fprintf('Experiment Stopped\n');
		 end
		 
	  end
   end
   methods % EVENT RESPONSE
	  function experimentStateChangeFcn(obj,~,evnt)
		 % (Required by SubSystem Parent Class)
		 fprintf('EyeCamSystem: Received ExperimentStateChange event\n')
		 switch evnt.EventName
			case 'ExperimentStart'
			   stop(obj.cameraObj.histogramTimer)
			   stop(obj.cameraObj.autoRangeTimer)
			   if ~obj.experimentRunning
				  start(obj.cameraObj.videoInputObj)
			   end
			case 'ExperimentStop'
			   stop(obj.cameraObj);
			   obj.saveDataSet();
			   obj.clearDataSet();
		 end
	  end
	  function trialStateChangeFcn(obj,~,~)
		 % (Required by SubSystem Parent Class)
		 fprintf('EyeCamSystem: Received TrialStateChange event\n')
		 persistent trialNumberLocal;
		 if isempty(trialNumberLocal)
			trialNumberLocal = 0;
		 end
		 % 		 obj.currentTrialNumber = trialNumberLocal;
		 
		 try
			if ~isempty(obj.currentDataFile)
			   obj.currentDataFile.experimentName = obj.currentExperimentName;
			   obj.saveDataFile();
			end
			trialNumberLocal = trialNumberLocal + 1;
			% prepare next DataFile with info for next trial
			% (or minute of recording)
			obj.currentDataFile.experimentName = obj.currentExperimentName;
		 catch me
			obj.lastError = me;
		 end
	  end
	  function frameAcquiredFcn(obj, src, evnt)
		 % (Required by SubSystem Parent Class)
		 try
			frameNum = obj.framesAcquired + 1;
			obj.framesAcquired = frameNum;
			% FIRST FRAME
			if isempty(obj.currentDataFile)
			   obj.currentDataFile = VideoFile(...
				  'rootPath',obj.currentDataSetPath,...
				  'experimentName',obj.currentExperimentName,...
				  'bitDepth',8);
			end
			% EVERY FRAME
			[frameData, time, metadata] = getdata(src, 1, 'uint8');
			frameInfo.frameSavedTime = hat;
			frameInfo.frameAcquiredTime = time;
			frameInfo.frameAcquiredAbsTime = datenum(metadata.AbsTime);
			% 			frameInfo.frameAcquiredTime = evnt.Data.AbsTime;
			frameInfo.frameNumber = frameNum;
			frameInfo.frameNumFromCam = evnt.Data.FrameNumber;
			frameInfo.frameNumRelative = evnt.Data.RelativeFrame;
			frameInfo.memoryUsed = evnt.Data.FrameMemoryUsed;
			frameInfo.memoryLimit = evnt.Data.FrameMemoryLimit;
			if isclosed(obj.currentDataFile)
			   if ~issaved(obj.currentDataFile)
				  obj.saveDataFile;
			   end
			   obj.currentDataFile = VideoFile(...
				  'rootPath',obj.currentDataSetPath,...
				  'experimentName',obj.currentExperimentName,...
				  'bitDepth',8);
			end
			addFrame2File(obj.currentDataFile,frameData,frameInfo);
		 catch me
			obj.lastError = me;
		 end
	  end
   end
   methods % SET
	  function set.experimentSyncObj(obj,bhv)
		 if ~isempty(obj.experimentStateListener)
			obj.experimentStateListener.Enabled = false;
		 end
		 obj.experimentSyncObj = bhv;
		 obj.experimentStateListener = addlistener(obj.experimentSyncObj,...
			'ExperimentStart',@(src,evnt)experimentStateChangeFcn(obj,src,evnt));
		 addlistener(obj.experimentSyncObj,...
			'ExperimentStop',@(src,evnt)experimentStateChangeFcn(obj,src,evnt));
		 obj.experimentStateListener.Enabled = true;
	  end
	  function set.trialSyncObj(obj,bhv)
		 obj.trialSyncObj = bhv;
		 if ~isempty(obj.trialStateListener)
			obj.trialStateListener.Enabled = false;
		 end
		 obj.trialStateListener = addlistener(obj.trialSyncObj,...
			'NewTrial',@(src,evnt)trialStateChangeFcn(obj,src,evnt));
		 obj.trialStateListener.Enabled = false;
		 obj.autoSaveFrequency = bhv.autoSaveFrequency;
	  end
	  function set.frameSyncObj(obj,cam)
		 if isa(cam, 'Camera')
			if ~isempty(obj.frameSyncListener)
			   obj.frameSyncListener.Enabled = false;
			end
			obj.frameSyncObj = cam;
			% Define Listener
			obj.frameSyncListener = addlistener(obj.frameSyncObj,...
			   'FrameAcquired',@(src,evnt)frameAcquiredFcn(obj,src,evnt));
			obj.frameSyncListener.Enabled = false;
		 end
	  end
   end
   methods % CLEANUP
	  function delete(obj)
		 try
			obj.saveDataSet();
			delete(obj.cameraObj)
		 catch me
			disp(me.message)
		 end
	  end
   end
   
end

