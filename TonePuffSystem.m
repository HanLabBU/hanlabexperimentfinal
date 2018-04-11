classdef TonePuffSystem < SubSystem
   
   
   
   properties
	  experimentStartDelay = 10
	  frameClkFrequency = 20
	  nTrials = 30 %Eyeblink = 20 Laser = 15 Training =60
	  interTrialIntervalRange = [30 35] %Eyeblink = 30 35 Laser = 20 25
	  interTrialInterval
	  toneFrequency = 9500
	  toneVolume = 0.3
	  toneDelay = 0
	  toneDuration = .35 %0.35
	  puffDelay = 0.6
	  puffDuration =0.1 %Eyeblink = .100 Laser = 5
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
	  toneObj@NiClockedTriggeredOutput scalar
	  puffObj@NiClockedTriggeredOutput scalar
	  strobeObj@NiClockedTriggeredOutput scalar
	  stimulusSet@cell vector
	  currentStimulusNumber = 0
	  currentTrialNumber = 0
	  frameClkSession@daq.ni.Session
	  frameClkChannel
	  frameCounterSession
	  frameCounterChannel
	  frameCounterListener
	  stimulusSampleFrequency = 100000
	  daqDeviceName = 'Dev2'
	  daqCounterOutNum = 0
	  daqCounterInNum = 1
	  daqToneChannel = 'ao0'
	  daqPuffChannel = 'port0/line0'
	  daqStrobeChannel % unused
	  trialStartTime
	  trialFirstFrame
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
		 obj.puffObj.prepareOutput();
		 obj.toneObj.prepareOutput();

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
		 % todo: use daqfind?
		 % FRAME-CLOCK OUTPUT (GLOBAL)
		 obj.frameClkSession = setGlobalFrameClock(...
			obj.frameClkFrequency,...
			obj.daqDeviceName,...
			obj.daqCounterOutNum);
		 obj.frameClkChannel = obj.frameClkSession.Channels(1);
		 % TONE (ANALOG) OUTPUT
		 obj.toneObj = NiClockedTriggeredOutput(...
			'deviceId', obj.daqDeviceName,...
			'type', 'analog',...
			'channelId', obj.daqToneChannel,...
			'signalRate',obj.stimulusSampleFrequency);
		 setup(obj.toneObj);
		 % PUFF (DIGITAL) OUTPUT
		 obj.puffObj = NiClockedTriggeredOutput(...
			'deviceId', obj.daqDeviceName,...
			'type', 'digital',...
			'channelId', obj.daqPuffChannel,...
			'signalRate',obj.stimulusSampleFrequency);
		 setup(obj.puffObj);
		 % LINK CLOCK-RATES AND USE FRAME-CLOCK AS TRIGGER
		 % Trigger From Frame-Clock
		 frameClkString = [obj.frameClkChannel.Device.ID,'/',obj.frameClkChannel.Terminal];
		 obj.toneObj.setTriggerSource(frameClkString);
		 % 		 obj.puffObj.setTriggerSource(frameClkString)
		 % Share Clock
		 sampleClkSrc = obj.toneObj.getClockSource('PFI1');
		 obj.puffObj.setClockSource(sampleClkSrc);
		 % FRAME-RATE FUNCTION (CHANNEL)
		 obj.frameCounterSession = daq.createSession('ni');
		 obj.frameCounterChannel = obj.frameCounterSession.addDigitalChannel(...
			obj.daqDeviceName,...
			'port0/line16',...
			'InputOnly');
		 obj.frameCounterSession.Rate = obj.frameClkFrequency;
		 obj.frameCounterSession.IsContinuous = true;
		 % 		 obj.frameCounterSession.addAnalogInputChannel(obj.daqDeviceName, 'ai0', 'Voltage')
		 % 		 obj.frameCounterSession.Rate = obj.stimulusSampleFrequency;
		 obj.frameCounterListener = obj.frameCounterSession.addlistener('DataAvailable', ...
			@(src,evnt)frameAcquiredFcn(obj,src,evnt));
		 obj.frameCounterSession.NotifyWhenDataAvailableExceeds = 1;
		 obj.frameCounterSession.addClockConnection('External', [obj.daqDeviceName,'/',obj.frameClkChannel.Terminal], 'ScanClock');
		 % 		 obj.frameCounterSession.addClockConnection('external',[obj.daqDeviceName,'/PFI1'], 'ScanClock');
		 % TRIAL-RATE FUNCTION
		 obj.toneObj.sessionObj.NotifyWhenScansQueuedBelow = 1;
		 % INTER-TRIAL-INTERVAL
		 if isempty(obj.interTrialInterval)
			if numel(obj.interTrialIntervalRange) == 2
			   obj.interTrialInterval = diff(obj.interTrialIntervalRange) .* rand(obj.nTrials,1) + obj.interTrialIntervalRange(1);
			   obj.trialStartTime = cat(1, obj.experimentStartDelay, cumsum(obj.interTrialInterval) + obj.experimentStartDelay);
			   obj.trialFirstFrame = ceil(obj.frameClkFrequency .* obj.trialStartTime);
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
		 obj.dataLogger.logObjectEvents(obj.toneObj)
		 obj.dataLogger.logObjectEvents(obj.puffObj)
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
		 obj.frameCounterListener.Enabled = true;
		 %             if ~isempty(obj.clockPulseObj)
		 %                 if obj.clockPulseObj.IsRunning
		 %                     stop(obj.clockPulseObj);
		 %                 end
		 %                 ch = obj.clockPulseObj.Channels(1);
		 %                 obj.clockPulseObj.Rate = obj.clockRate;
		 %                 ch.Frequency = obj.clockRate;
		 %                 obj.clockPulseObj.prepare();
		 %             end
		 obj.ready = true;
		 obj.experimentRunning = true;
		 notify(obj, 'ExperimentStart')
		 startBackground(obj.frameCounterSession);
		 startBackground(obj.frameClkSession);
		 % 		 startBackground(obj.camInputSession);
		 % 		 if obj.toneObj.sessionObj.ScansQueued < 1
		 % 		 obj.puffObj.prepareOutput();
		 % 		 obj.toneObj.prepareOutput();
		 % 		 end
		 if isempty(obj.currentDataFile)
			obj.currentDataFile = TonePuffFile(...
			   'rootPath',obj.currentDataSetPath,...
			   'experimentName',obj.currentExperimentName);%changed rootPath from sessionPath
		 end
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
			if ~isempty(obj.frameCounterSession)
			   stop(obj.frameCounterSession);
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
			   obj.clearDataSet();
			   stop(obj.dataLogger)
			   % SAVE EXPERIMENT STRUCTURE
			   experimentStructure = struct(obj);
			   save(fullfile(obj.currentDataSetPath,'ExperimentStructure'),'experimentStructure')
			   notify(obj, 'ExperimentStop')
			   % SAVE FIRST FRAMES TO TEXT FILE
			   % 			   textfilepath  = fullfile(obj.currentExperimentName, ['first_frames_',obj.currentExperimentName,'.txt']);
			   % 			   fid = fopen(textfilepath, 'wt');
			   % 			   fprintf(fid, '%i\n',obj.trialFirstFrame);
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
		 obj.puffObj.signalDuration = obj.puffDuration;
		 obj.puffObj.signalDelay = obj.puffDelay;
		 obj.toneObj.signalDuration = obj.toneDuration;
		 obj.toneObj.signalDelay = obj.toneDelay;
		 M = max(...
			ceil(obj.stimulusSampleFrequency*obj.toneObj.signalDuration)+ceil(obj.stimulusSampleFrequency*obj.toneObj.signalDelay),...
			ceil(obj.stimulusSampleFrequency*obj.puffObj.signalDuration)+ceil(obj.stimulusSampleFrequency*obj.puffObj.signalDelay) )...
			+ round(obj.stimulusSampleFrequency/10);
		 obj.toneObj.outputNumSamples = M+10000;
		 obj.puffObj.outputNumSamples = M+1000;
		 % obj.puffObj.nextSignal = zeros(M,1);
		 % obj.puffObj.nextSignal(floor(obj.puffObj.signalDelay*aFs) + (1:ceil(obj.puffObj.signalDuration*aFs))) = 1;
		 % obj.puffObj.nextSignal((end-10):end) = 0; % important!!
		 obj.puffObj.signalGeneratingFcn = @()ones(floor(obj.puffObj.signalDuration*obj.puffObj.signalRate),1);
		 % SINE-WAVE
		 if isempty(obj.sineGenerator)
			obj.sineGenerator = dsp.SineWave;
		 else
			release(obj.sineGenerator);
		 end
		 obj.sineGenerator.SampleRate = obj.stimulusSampleFrequency;
		 obj.sineGenerator.SamplesPerFrame = ceil(obj.stimulusSampleFrequency*obj.toneObj.signalDuration);
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
		 % DEFINE A LINEAR ENVELOPE (RISE AND DECAY)
		 envelopeFcn = @(riseTime, duration, fs)  cat(1, ...
			cos(pi.*(1/2 + (1:ceil(riseTime*fs))'./ceil(riseTime*fs) )),...
			ones(ceil(duration*fs) - 2*ceil(riseTime*fs), 1) ,...
			flipud( cos(pi.*(1/2 + (1:ceil(riseTime*fs))'./ceil(riseTime*fs) ))) );
		 % WITH ENVELOPE
		 envelopeRiseTime = .010;
		 obj.toneObj.signalGeneratingFcn = @()obj.toneVolume.*obj.sineGenerator.step .* envelopeFcn( envelopeRiseTime, obj.toneObj.signalDuration, obj.stimulusSampleFrequency);
		 % WITHOUT ENVELOPE
		 % 		 obj.toneObj.signalGeneratingFcn = @()obj.toneVolume.*obj.sineGenerator.step
		 % WITH CHIRP
		 % 		 obj.toneObj.signalGeneratingFcn = @()obj.toneVolume.*obj.sineGenerator.step.*obj.chirpGenerator.step;
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
			if any(frameNum == obj.trialFirstFrame)
			   notify(obj, 'NewTrial')
			   frameInfo.firstFrame = 1;
			   if frameNum == obj.trialFirstFrame(end) %last frame
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
			stop(obj.frameCounterSession);
			delete(obj.frameClkSession);
			delete(obj.frameCounterSession);
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

