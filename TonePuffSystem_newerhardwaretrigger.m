classdef TonePuffSystem < SubSystem
   
   
   
   properties
	  experimentStartDelay = 2
	  nTrials = 15
	  interTrialIntervalRange = [30 35]
	  interTrialInterval
	  toneFrequency = 9500
	  toneVolume = .5
	  toneDelay = 0
	  toneDuration = .35
	  toneSignalGenFcn
	  puffDelay = .6
	  puffDuration = 0.1
	  puffSignalGenFcn
	  sineGenerator
	  chirpGenerator
	  dataLogger
   end
   properties % OBLIGATORY
	  experimentSyncObj
	  trialSyncObj
	  frameSyncObj
   end
   properties
	  % 	  toneObj
	  % 	  puffObj
	  stimulusSet
	  currentStimulusNumber = 0
	  currentTrialNumber = 0
	  trialStartTime
	  experimentEndTime
	  trialFirstFrameIdx
	  experimentLastFrame
	  trialFirstFrameBool
   end
   properties % NI-DAQ 
	  daqDeviceName = 'Dev2'
	  frameClkSession
	  frameClkChannel
	  frameClkFrequency = 20
	  frameClkCounterNum = 0
	  frameCountSession
	  frameCountChannel
	  frameCountListener
	  frameCountCounterNum = 1
	  % 	  trialTriggerObj
	  trialTriggerSession
	  trialTriggerChannelName = 'port0/line0'
	  trialTriggerChannel
	  stimOutSession	  
	  stimOutListener
	  stimOutFrequency = 100000	  
	  stimToneChannelNum = 0
	  stimToneChannel
	  stimPuffChannelNum = 1
	  stimPuffChannel
	  stimOutNumSamples
	  camInputSession
	  camInputChannel
	  camInputListener
	  camInputData
	  camInputTimeStamp
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
	  function obj = TonePuffSystem(varargin)
		 if nargin > 1
			for k = 1:2:length(varargin)
			   obj.(varargin{k}) = varargin{k+1};
			end
		 end
		 obj.defineDefaults()
	  end
	  function setup(obj)
		 obj.checkProperties()
		 obj.updateExperimentName()
		 obj.createSystemComponents()
		 obj.loadStandardStimulus();
		 obj.autoSaveFrequency = obj.nTrials+1;
		 % LOAD FIRST STIMULUS
		 if obj.currentStimulusNumber >= 1
			obj.stimOutSession.queueOutputData(obj.stimulusSet{obj.currentStimulusNumber});
			prepare(obj.stimOutSession);			
		 end
		 % LOAD TRIAL TRIGGER SEQUENCE
		 obj.trialTriggerSession.queueOutputData(obj.trialFirstFrameBool);
		 obj.trialTriggerSession.prepare
	  end
	  function defineDefaults(obj)
		 obj.defineDefaults@SubSystem;
		 % Override some defaults in parent class
		 obj.default.sessionPath =  fullfile(['F:\Data\',...
			'TonePuff_',datestr(date,'yyyy_mm_dd')]);
		 obj.default.autoSaveFrequency = 10;
	  end
	  function checkProperties(obj)
		 obj.savedDataFiles = TonePuffFile.empty(1,0);
		 obj.currentDataFileSet = TonePuffFile.empty(1,0);
		 obj.framesAcquired = 0;
		 obj.checkProperties@SubSystem;
	  end
	  function createSystemComponents(obj)
		 % (Required by SubSystem Parent Class)
		 obj.experimentRunning = false;
		 % FRAME-CLOCK OUTPUT (GLOBAL)
		 obj.frameClkSession = setGlobalFrameClock(...
			obj.frameClkFrequency,...
			obj.daqDeviceName,...
			obj.frameClkCounterNum);
		 obj.frameClkChannel = obj.frameClkSession.Channels(1);
		 frameClkString = [obj.frameClkChannel.Device.ID,'/',obj.frameClkChannel.Terminal];
		 % TRIAL-TRIGGER OUTPUT
		 obj.trialTriggerSession = daq.createSession('ni');
		 obj.trialTriggerChannel =  obj.trialTriggerSession.addDigitalChannel(...
			obj.daqDeviceName,...
			obj.trialTriggerChannelName,...
			'OutputOnly');
		 obj.trialTriggerSession.Rate = obj.frameClkFrequency;
		 obj.trialTriggerSession.addClockConnection('External',frameClkString, 'ScanClock')
		 trialTriggerString = [obj.daqDeviceName,'/','PFI7'];
		 % TONE & PUFF (ANALOG) OUTPUT
		 obj.stimOutSession = daq.createSession('ni');
		 stimoutchannels = obj.stimOutSession.addAnalogOutputChannel(...
			obj.daqDeviceName,...
			[obj.stimToneChannelNum, obj.stimPuffChannelNum],...
			'Voltage');			
		 obj.stimOutSession.Rate = obj.stimOutFrequency;
		 obj.stimToneChannel = stimoutchannels(1);
		 obj.stimPuffChannel = stimoutchannels(2);
		 obj.stimOutSession.addTriggerConnection('External', trialTriggerString, 'StartTrigger');
		 % 		 obj.stimOutSession.IsNotifyWhenScansQueuedBelowAuto = true;
		 % 		 obj.stimOutSession.NotifyWhenScansQueuedBelow = 1;
		 obj.stimOutSession.TriggersPerRun = obj.nTrials;
		 obj.stimOutSession.ExternalTriggerTimeout = 120;
		 % 		 obj.stimOutListener = obj.stimOutSession.addlistener('DataRequired',...
		 % 			@(src,evnt)loadNextStimFcn(obj,src,evnt));
		 % 		 obj.stimOutSession.TriggersPerRun = obj.nTrials;
		 % FRAME-RATE FUNCTION (CHANNEL)
		 obj.frameCountSession = daq.createSession('ni');
		 obj.frameCountChannel = obj.frameCountSession.addDigitalChannel(...
			obj.daqDeviceName,...
			'port0/line16',...
			'InputOnly');
		 obj.frameCountSession.Rate = obj.frameClkFrequency;
		 obj.frameCountSession.IsContinuous = true;
		 obj.frameCountListener = obj.frameCountSession.addlistener('DataAvailable', ...
			@(src,evnt)frameAcquiredFcn(obj,src,evnt));
		 obj.frameCountSession.NotifyWhenDataAvailableExceeds = 1;
		 obj.frameCountSession.addClockConnection('External', frameClkString, 'ScanClock');		 		
		 % INTER-TRIAL-INTERVAL
		 if isempty(obj.interTrialInterval)
			if numel(obj.interTrialIntervalRange) == 2
			   obj.interTrialInterval = diff(obj.interTrialIntervalRange) .* rand(obj.nTrials,1) + obj.interTrialIntervalRange(1);
			   cumitt = cat(1, obj.experimentStartDelay, cumsum(obj.interTrialInterval) + obj.experimentStartDelay);
			   obj.trialStartTime = cumitt(1:end-1);
			   obj.experimentEndTime = cumitt(end);
			   cumframes = round(obj.frameClkFrequency .* obj.trialStartTime);
			   obj.trialFirstFrameIdx = cumframes(1:end-1) + 1;
			   obj.experimentLastFrame = cumframes(end);
			   obj.trialFirstFrameBool = zeros(obj.experimentLastFrame, 1);
			   obj.trialFirstFrameBool(obj.trialFirstFrameIdx) = 1;
			else
			   warning('TonePuffSystem:NoInterTrialIntervalRange', 'No automatic generation of Inter-Trial Intervals without set range')
			end
		 end
		 if isempty(obj.experimentSyncObj) || ~isvalid(obj.experimentSyncObj)
			obj.experimentSyncObj = obj;
		 end
		 if isempty(obj.trialSyncObj) || ~isvalid(obj.trialSyncObj)
			obj.trialSyncObj = obj;
		 end
		 if isempty(obj.frameSyncObj)
			obj.frameSyncObj = obj;
		 end
	  end
   end
   methods % CONTROL
	  function start(obj)
		 % (Required by SubSystem Parent Class)
		 obj.updateExperimentName()
		 fprintf('STARTING TONE-PUFF-SYSTEM:\n\tSession-Path: %s\n',...
			obj.sessionPath);
		 if ~isdir(obj.sessionPath)
			mkdir(obj.sessionPath)
		 end
		 % DATALOGGER
		 obj.dataLogger = DataLogger;
		 obj.dataLogger.savePath = obj.sessionPath;
		 setup(obj.dataLogger)
		 obj.dataLogger.logObjectEvents(obj)
		 start(obj.dataLogger)
		 if isempty(obj.frameSyncListener)
			warning('TonePuffSystem:start:NoFrameSyncListener',...
			   'The Behavior-Control sysem is not connected to a camera, and will not record data every frame');
		 else
			obj.frameSyncListener.Enabled = true;
		 end
		 obj.trialStateListener.Enabled = true;
		 obj.experimentStateListener.Enabled = true;
		 obj.frameCountListener.Enabled = true;
		 obj.stimOutListener.Enabled = true;
		 obj.ready = true;
		 obj.experimentRunning = true;
		 if isempty(obj.currentDataFile)
			obj.currentDataFile = TonePuffFile(...
			   'rootPath',obj.currentDataSetPath,...
			   'experimentName',obj.currentExperimentName);
		 end
		 % QUEUE DATA
		 obj.stimOutSession.queueOutputData(obj.stimulusSet{obj.currentStimulusNumber});
		 prepare(obj.stimOutSession);
		 obj.trialTriggerSession.queueOutputData(obj.trialFirstFrameBool);
		 prepare(obj.trialTriggerSession);
		 % START OUTPUT
		 notify(obj, 'ExperimentStart')		 
		 startBackground(obj.frameCountSession);
		 % 		 startBackground(obj.trialTriggerSession);		 
		 startBackground(obj.frameClkSession);
		 % 		 startBackground(obj.camInputSession);
		 % 		 if obj.toneObj.sessionObj.ScansQueued < 1
		 % 		 obj.puffObj.prepareOutput();
		 % 		 obj.toneObj.prepareOutput();
		 % 		 end		 
		 fprintf('TonePuffSystem STARTED\n');
	  end
	  function stop(obj)
		 % (Required by SubSystem Parent Class)
		 % 		 if~isempty(obj.camInputSession)
		 % 			stop(obj.camInputSession)
		 % 		 end
		 try
			if ~isempty(obj.frameClkSession)
			   stop(obj.frameClkSession);
			end
			if ~isempty(obj.frameCountSession)
			   stop(obj.frameCountSession);
			end
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
				  obj.currentDataFile = TonePuffFile.empty(1,0);
			   end
			   obj.saveDataSet();
			   % 			obj.clearDataSet();
			   stop(obj.dataLogger)
			   % SAVE EXPERIMENT STRUCTURE
			   experimentStructure = struct(obj);
			   save(fullfile(obj.currentDataSetPath,'ExperimentStructure'),'experimentStructure')
			   notify(obj, 'ExperimentStop')
			   % SAVE FIRST FRAMES TO TEXT FILE
			   % 			   textfilepath  = fullfile(obj.currentExperimentName, ['first_frames_',obj.currentExperimentName,'.txt']);
			   % 			   fid = fopen(textfilepath, 'wt');
			   % 			   fprintf(fid, '%i\n',obj.trialFirstFrameIdx);
			   % 			   fclose(fid);			   
			   % 			if logical(obj.autoSyncTrialTime) && ~isempty(obj.autoSyncTimerObj)
			   % 			   obj.autoSyncTimerObj.stop();
			   % 			end
			   fprintf('Experiment Stopped\n');
			   
			end
		 catch me
			notify(obj,'ExperimentStop')
			keyboard
		 end
	  end
   end
   methods % TONE-PUFF SPECIFIC
	  function loadStandardStimulus(obj)
		 % SIGNAL DURATION & DELAY
		 obj.stimOutNumSamples = max(...
			ceil(obj.stimOutFrequency*obj.toneDuration)+ceil(obj.stimOutFrequency*obj.toneDelay),...
			ceil(obj.stimOutFrequency*obj.puffDuration)+ceil(obj.stimOutFrequency*obj.puffDelay) )...
			+ round(obj.stimOutFrequency/10);
		 % 		 obj.toneObj.outputNumSamples = M+10000;
		 % 		 obj.puffObj.outputNumSamples = M+1000;
		 % obj.puffObj.nextSignal = zeros(M,1);
		 % obj.puffObj.nextSignal(floor(obj.puffDelay*aFs) + (1:ceil(obj.puffDuration*aFs))) = 1;
		 % obj.puffObj.nextSignal((end-10):end) = 0; % important!!
		 obj.puffSignalGenFcn = @()4.*ones(floor(obj.puffDuration*obj.stimOutFrequency),1);		 
		 % SINE-WAVE
		 if isempty(obj.sineGenerator)
			obj.sineGenerator = dsp.SineWave;
		 else
			release(obj.sineGenerator);
		 end
		 obj.sineGenerator.SampleRate = obj.stimOutFrequency;
		 obj.sineGenerator.SamplesPerFrame = obj.stimOutFrequency*obj.toneDuration;
		 obj.sineGenerator.Frequency = obj.toneFrequency;
		 % CHIRP
		 if isempty(obj.chirpGenerator)
			obj.chirpGenerator = dsp.Chirp;
		 else
			release(obj.chirpGenerator);
		 end
		 obj.chirpGenerator.InitialFrequency = 1500;
		 obj.chirpGenerator.TargetFrequency = 2000;
		 obj.chirpGenerator.SampleRate = obj.sineGenerator.SampleRate;
		 obj.chirpGenerator.SamplesPerFrame = obj.sineGenerator.SamplesPerFrame;
		 % COMBINE
		 % 		 obj.toneVolume = .9;
		 obj.toneSignalGenFcn = @()obj.toneVolume.*obj.sineGenerator.step;
		 % 		 obj.toneSignalGenFcn= @()obj.toneVolume.*obj.sineGenerator.step.*obj.chirpGenerator.step;
		 % GENERATE
		 obj.currentStimulusNumber = 1;
		 toneOnIdx = round(obj.toneDelay * obj.stimOutFrequency) + 1;
		 puffOnIdx = round(obj.puffDelay * obj.stimOutFrequency) + 1;
		 toneSignal = feval(obj.toneSignalGenFcn);		 
		 puffSignal = feval(obj.puffSignalGenFcn);
		 nToneSamples = numel(toneSignal);
		 nPuffSamples = numel(puffSignal);
		 obj.stimOutNumSamples = max([obj.stimOutNumSamples, toneOnIdx+nToneSamples, puffOnIdx+nPuffSamples]);
		 stimOutSig = zeros(obj.stimOutNumSamples ,2);
		 stimOutSig(toneOnIdx:(toneOnIdx+nToneSamples-1), 1) = toneSignal(:);
		 stimOutSig(puffOnIdx:(puffOnIdx+nPuffSamples-1), 2) = puffSignal(:);
		 obj.stimulusSet{1} = stimOutSig;
	  end	  
	  function loadNextStimFcn(obj,~,~)
		 obj.stimOutSession.queueOutputData(obj.stimulusSet{obj.currentStimulusNumber});
		 prepare(obj.stimOutSession);
		 fprintf('New Stim Loaded\n')
	  end
   end
   methods % EVENT RESPONSE
	  function experimentStateChangeFcn(obj,~,evnt)
		 % (Required by SubSystem Parent Class)
		 fprintf('TonePuffSystem: Received ExperimentStateChange event\n')
		 switch evnt.EventName
			case 'ExperimentStart'
			   if ~logical(obj.experimentRunning)
				  start(obj)
			   end
			case 'ExperimentStop'
			   if logical(obj.experimentRunning)
				  stop(obj);
			   end
		 end
	  end
	  function trialStateChangeFcn(obj,~,~)
		 % (Required by SubSystem Parent Class)
		 fprintf('TonePuffSystem: Received TrialStateChange event\n')
		 persistent trialNumberLocal;
		 if isempty(trialNumberLocal)
			trialNumberLocal = 0;
		 end
		 obj.currentTrialNumber = trialNumberLocal;
		 fprintf('Queuing Trial %i\n', trialNumberLocal + 1)
		 obj.puffObj.queueOutput();
		 obj.toneObj.queueOutput();
		 try
			if ~isempty(obj.currentDataFile)
			   obj.currentDataFile.experimentName = obj.currentExperimentName;
			   if ~isempty(obj.currentDataFile.trialNumber)
				  % previous data-file -> save it
				  obj.saveDataFile();
				  % exits after creating new (blank) currentDataFile
				  % for next trial
			   end
			end
			trialNumberLocal = trialNumberLocal + 1;
			% prepare next DataFile with info for next trial
			% (or minute of recording)
			obj.currentDataFile.trialNumber = trialNumberLocal;
			obj.currentDataFile.stimulusNumber = obj.currentStimulusNumber;
			obj.currentDataFile.experimentName = obj.currentExperimentName;
			fprintf('Start of Trial: %i\n', trialNumberLocal);
		 catch me
			obj.lastError = me;
		 end
	  end
	  function frameAcquiredFcn(obj,src,evnt)
		 % (Required by SubSystem Parent Class)
		 try
			frameNum = obj.framesAcquired + 1;
			obj.framesAcquired = frameNum;
			% FIRST FRAME
			if isempty(obj.currentDataFile)
			   obj.currentDataFile = TonePuffFile(...
				  'rootPath',obj.currentDataSetPath,...
				  'experimentName',obj.currentExperimentName);%changed rootPath from sessionPath
			end
			
			% EVERY FRAME
			frameInfo.frameNumber = frameNum;
			frameInfo.triggerTime = evnt.TriggerTime;
			frameInfo.timeStamp = evnt.TimeStamps;
			frameInfo.trialNumber = obj.currentTrialNumber;
			frameInfo.highAccuracyTime = hat;
			frameInfo.firstFrame = 0;
			frameInfo.scansAcquired = evnt.Source.ScansAcquired;
			frameInfo.toneSamplesQueued = obj.toneObj.sessionObj.ScansQueued;
			frameInfo.toneSamplesOutput = obj.toneObj.sessionObj.ScansOutputByHardware;
			frameInfo.puffSamplesQueued = obj.puffObj.sessionObj.ScansQueued;
			frameInfo.puffSamplesOutput = obj.puffObj.sessionObj.ScansOutputByHardware;
			if any(frameNum == obj.trialFirstFrameIdx)
			   notify(obj, 'NewTrial')
			   frameInfo.firstFrame = 1;
			   if frameNum == obj.trialFirstFrameIdx(end) %last frame
				  stop(obj)
			   end
			else
			   % LOAD NEXT STIMULUS (+/-puff, +/-tone)
			   if obj.puffObj.sessionObj.ScansQueued < 1
				  obj.puffObj.prepareOutput();
			   end
			   if obj.toneObj.sessionObj.ScansQueued < 1
				  obj.toneObj.prepareOutput();
			   end
			end
			frameData = hat;
			if isclosed(obj.currentDataFile)
			   if ~issaved(obj.currentDataFile)
				  obj.saveDataFile;
			   end
			   obj.currentDataFile = TonePuffFile(...
				  'rootPath',obj.currentDataSetPath,...
				  'experimentName',obj.currentExperimentName);
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
		 
	  end
	  function set.frameSyncObj(obj,cam)
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
   methods
	  function delete(obj)
		 global CURRENT_EXPERIMENT_NAME
		 CURRENT_EXPERIMENT_NAME = [];
		 try
			obj.saveDataSet();
			stop(obj.frameClkSession);
			stop(obj.frameCountSession);
			delete(obj.frameClkSession);
			delete(obj.frameCountSession);
			close(obj.dataLogger.logFig)
			delete(obj.dataLogger)
			if isvalid(obj.toneObj)
			   delete(obj.toneObj);
			end
			if isvalid(obj.puffObj)
			   delete(obj.puffObj);
			end
		 catch me
			disp(me.message)
		 end
	  end
   end
   
end

