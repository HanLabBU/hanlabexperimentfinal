classdef TonePuffSystem3 < SubSystem
   
   
   
   properties
	  experimentStartDelay = 10
	  frameClkFrequency = 20
	  nTrials = 60
	  interTrialIntervalRange = [30 35]
	  interTrialInterval
	  laserDelay = 0
	  laserDuration = 1
	  toneFrequency = [14500 10000 6000]
	  toneVolume = [6 .15] 
	  toneDelay = 0.050
	  toneDuration =.350
	  puffDelay = 0.650
	  puffDuration = 0.100
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
	  laserObj@NiClockedTriggeredOutputEdit %scaler
	  toneObj@NiClockedTriggeredOutputEdit %scalar
	  puffObj@NiClockedTriggeredOutputEdit %scalar
	  strobeObj@NiClockedTriggeredOutputEdit %scalar
	  stimulusSet
	  laserSignal
	  toneSignal
	  puffSignal
	  currentStimulusNumber = 0
	  nextStimulusNumber
	  currentTrialNumber
	  frameClkSession@daq.ni.Session
	  frameClkChannel
	  frameCounterSession
	  frameCounterChannel
	  frameCounterListener
	  stimulusSampleFrequency = 100000
	  daqDeviceName = 'Dev2'
	  daqCounterOutNum = 0
	  daqCounterInNum = 1
	  daqLaserChannel = 'port1/line3'
	  daqToneChannel = 'ao0'
	  daqPuffChannel = 'port1/line2'
	  daqStrobeChannel = 'port1/line0'
	  trialStartTime
	  trialFirstFrame
	  trialStimulusNumber
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
	  function obj = TonePuffSystem3(varargin)
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
		 obj.puffObj.prepareOutput(obj.puffSignal{obj.nextStimulusNumber});
		 obj.toneObj.prepareOutput(obj.toneSignal{obj.nextStimulusNumber});
		obj.laserObj.prepareOutput(obj.laserSignal{obj.nextStimulusNumber});
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
		 obj.toneObj = NiClockedTriggeredOutputEdit(...
			'deviceId', obj.daqDeviceName,...
			'type', 'analog',...
			'channelId', obj.daqToneChannel,...
			'aoNumber', sscanf(obj.daqToneChannel, 'ao%f'),...
			'signalRate',obj.stimulusSampleFrequency);
		 setup(obj.toneObj);
		 %LASER(DIGITAL) OUTPUT
		 [port, ~] = sscanf(obj.daqLaserChannel, 'port%f/line%f');
		 obj.laserObj = NiClockedTriggeredOutputEdit(...
			'deviceId', obj.daqDeviceName,...
			'type', 'digital',...
			'channelId', obj.daqLaserChannel,...
			'portNumber', port(1),...
			'lineNumber', port(2),...
			'signalRate', obj.stimulusSampleFrequency);
		 setup(obj.laserObj);
		 % PUFF (DIGITAL) OUTPUT
		 [port, ~] = sscanf(obj.daqPuffChannel, 'port%f/line%f');
		 obj.puffObj = NiClockedTriggeredOutputEdit(...
			'deviceId', obj.daqDeviceName,...
			'type', 'digital',...
			'channelId', obj.daqPuffChannel,...
			'portNumber', port(1),...
			'lineNumber', port(2),...
			'signalRate',obj.stimulusSampleFrequency);
		 setup(obj.puffObj);
		 % LINK CLOCK-RATES AND USE FRAME-CLOCK AS TRIGGER
		 % Trigger From Frame-Clock
		 frameClkString = [obj.frameClkChannel.Device.ID,'/',obj.frameClkChannel.Terminal];
		 obj.toneObj.setTriggerSource(frameClkString);
%  		 obj.puffObj.setTriggerSource(frameClkString);
%  		 obj.laserObj.setTriggerSource(frameClkString);
		 % Share Clock
		 sampleClkSrc = obj.toneObj.getClockSource('PFI1');
		 obj.puffObj.setClockSource(sampleClkSrc);
		 obj.laserObj.setClockSource(sampleClkSrc);
		 % FRAME-RATE FUNCTION (CHANNEL)
		 obj.frameCounterSession = daq.createSession('ni');
		 obj.frameCounterChannel = obj.frameCounterSession.addDigitalChannel(...
			obj.daqDeviceName,...
			'port0/line16',...
			'InputOnly');
		 obj.frameCounterSession.Rate = obj.frameClkFrequency;
		 obj.frameCounterSession.IsContinuous = true;
		 obj.frameCounterSession.addAnalogInputChannel(obj.daqDeviceName, 'ai0', 'Voltage')
		 obj.frameCounterSession.Rate = obj.stimulusSampleFrequency;
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
			   warning('TonePuffSystem3:NoInterTrialIntervalRange', 'No automatic generation of Inter-Trial Intervals without set range')
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
		 % STIMULUS NUMBERS
		 if ~isempty(obj.nextStimulusNumber)
			obj.currentStimulusNumber = obj.nextStimulusNumber;
		 else
			obj.currentStimulusNumber = obj.trialStimulusNumber(1);
		 end
		 obj.nextStimulusNumber = obj.trialStimulusNumber(2);
		 % DATALOGGER
		 obj.dataLogger = DataLogger;
		 obj.dataLogger.savePath = obj.sessionPath;
		 setup(obj.dataLogger)
		 obj.dataLogger.logObjectEvents(obj.toneObj)
		 obj.dataLogger.logObjectEvents(obj.puffObj)
		 obj.dataLogger.logObjectEvents(obj.laserObj)
		 obj.dataLogger.logObjectEvents(obj)
		 start(obj.dataLogger)
		 if isempty(obj.frameSyncListener)
			warning('TonePuffSystem3:start:NoFrameSyncListener',...
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
		 %		 obj.laserObj.prepareOutput();
		 % 		 end
		 if isempty(obj.currentDataFile)
			obj.currentDataFile = TonePuffFile(...
			   'rootPath',obj.currentDataSetPath,...
			   'experimentName',obj.currentExperimentName);%changed rootPath from sessionPath
		 end
		 fprintf('TonePuffSystem3 STARTED\n');
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
			   			   textfilepath  = fullfile(obj.currentExperimentName, ['first_frames_',obj.currentExperimentName,'.txt']);
			   			   fid = fopen(textfilepath, 'wt');
			   			   fprintf(fid, '%i\n',obj.trialFirstFrame);
			   			   fclose(fid);			   
			   			if logical(obj.autoSyncTrialTime) && ~isempty(obj.autoSyncTimerObj)
			   			   obj.autoSyncTimerObj.stop();
			   			end
			   fprintf('Experiment Stopped\n');
			   
			end
		 catch me
			notify(obj,'ExperimentStop')
			keyboard
		 end
	  end
   end
   methods % TONE-PUFF-LASER SPECIFIC
	  function loadStandardStimulus(obj)
		 % SIGNAL DURATION & DELAY
		 obj.puffObj.signalDuration = obj.puffDuration;
		 obj.puffObj.signalDelay = obj.puffDelay;
		 obj.toneObj.signalDuration = obj.toneDuration;
		 obj.toneObj.signalDelay = obj.toneDelay;
		 obj.laserObj.signalDuration = obj.laserDuration;
		 obj.laserObj.signalDelay = obj.laserDelay;
		 M_laser = ceil(obj.stimulusSampleFrequency*obj.laserObj.signalDuration)+ceil(obj.stimulusSampleFrequency*obj.laserObj.signalDelay);
		 M_puff = ceil(obj.stimulusSampleFrequency*obj.puffObj.signalDuration)+ceil(obj.stimulusSampleFrequency*obj.puffObj.signalDelay);
		 M_tone = ceil(obj.stimulusSampleFrequency*obj.toneObj.signalDuration)+ceil(obj.stimulusSampleFrequency*obj.toneObj.signalDelay);
		 M = [M_laser M_puff M_tone];
		 M = max(M)+ round(obj.stimulusSampleFrequency/10);
		 obj.toneObj.outputNumSamples = M+10000;
		 obj.puffObj.outputNumSamples = M+1000;
		 obj.laserObj.outputNumSamples = M+1000;
		 % obj.puffObj.nextSignal = zeros(M,1);
		 % obj.puffObj.nextSignal(floor(obj.puffObj.signalDelay*aFs) + (1:ceil(obj.puffObj.signalDuration*aFs))) = 1;
		 % obj.puffObj.nextSignal((end-10):end) = 0; % important!!
		 % 		 obj.puffObj.signalGeneratingFcn = @()ones(floor(obj.puffObj.signalDuration*obj.puffObj.signalRate),1);
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
			(1:ceil(riseTime*fs))'./ceil(riseTime*fs),...
			ones(ceil(duration*fs) - 2*ceil(riseTime*fs), 1) ,...
			flipud( (1:ceil(riseTime*fs))'./ceil(riseTime*fs) ) );
		 % COSINE ENVELOPE (not working as it should)
		 % 		 envelopeFcn = @(riseTime, duration, fs)  cat(1, ...
		 % 			cos(pi.*(1/2 + (1:ceil(riseTime*fs))'./ceil(riseTime*fs) )),...
		 % 			ones(ceil(duration*fs) - 2*ceil(riseTime*fs), 1) ,...
		 % 			flipud( cos(pi.*(1/2 + (1:ceil(riseTime*fs))'./ceil(riseTime*fs) ))) );
		 % WITH ENVELOPE
		 envelopeRiseTime = .025;
		 obj.toneObj.signalGeneratingFcn = @()obj.toneVolume.*obj.sineGenerator.step .* envelopeFcn( envelopeRiseTime, obj.toneObj.signalDuration, obj.stimulusSampleFrequency);
		 % WITHOUT ENVELOPE
		 % 		 obj.toneObj.signalGeneratingFcn = @()obj.toneVolume.*obj.sineGenerator.step
		 % WITH CHIRP
		 % 		 obj.toneObj.signalGeneratingFcn = @()obj.toneVolume.*obj.sineGenerator.step.*obj.chirpGenerator.step;
		 % STORE MULTIPLE TONES		
		 toneSig = zeros(obj.toneObj.outputNumSamples,1);
		 if numel(obj.toneVolume) == 1
			toneVol = [obj.toneVolume obj.toneVolume];
		 else
			toneVol = obj.toneVolume;
		 end
		 activeToneSig = toneVol(1).*obj.sineGenerator.step ...
			.* envelopeFcn( envelopeRiseTime, obj.toneObj.signalDuration, obj.stimulusSampleFrequency);
		 toneSig(floor(obj.toneObj.signalRate*obj.toneObj.signalDelay) + (1:numel(activeToneSig))) = activeToneSig;
		 obj.toneSignal{1} = toneSig;
		 release(obj.sineGenerator)
		 obj.sineGenerator.Frequency = 4500;
		 toneSig = zeros(obj.toneObj.outputNumSamples,1);
		 activeToneSig = toneVol(2).*obj.sineGenerator.step ...
			.* envelopeFcn( envelopeRiseTime, obj.toneObj.signalDuration, obj.stimulusSampleFrequency);
		 toneSig(floor(obj.toneObj.signalRate*obj.toneObj.signalDelay) + (1:numel(activeToneSig))) = activeToneSig;
		 obj.toneSignal{2} = toneSig;
		 % STORE MULTIPLE PUFFS
		 puffSig = zeros(obj.puffObj.outputNumSamples,1);
		 activePuffSig = ones(floor(obj.puffObj.signalDuration*obj.puffObj.signalRate),1); % (puff)
		 puffSig(floor(obj.puffObj.signalRate*obj.puffObj.signalDelay) + (1:numel(activePuffSig))) = activePuffSig;
		 obj.puffSignal{1} = puffSig;		 
		 puffSig = zeros(obj.puffObj.outputNumSamples,1);
		 activePuffSig = 1; % (no puff)
		 puffSig(floor(obj.puffObj.signalRate*obj.puffObj.signalDelay) + (1:numel(activePuffSig))) = activePuffSig;	 		 
		 obj.puffSignal{2} = puffSig;
		 %STORE MULTIPLE LASERS
		 laserSig = zeros(obj.laserObj.outputNumSamples,1);
		 activeLaserSig = ones(floor(obj.laserObj.signalDuration*obj.laserObj.signalRate,1)); %(laser)
		 laserSig(floor(obj.laserObj.signalRate*obj.laserobj.signalDelay) + (1:numel(activeLaserSig)))= activeLaserSig;
		 obj.laserSignal{1} = laserSig;
		 laserSig = zeros(obj.puffObj.outputNumSamples,1);
		 activeLaserSig = 1; %(no laser)
		 laserSig(floor(obj.laserObj.signalRate*obj.laserObj.signalDelay) + (1:numel(activeLaserSig))) = activeLaserSig;
		 obj.laserSignal{2} = laserSig;
		 % ASSIGN STIMULI TO TRIALS RANDOMLY
		 obj.trialStimulusNumber = zeros(obj.nTrials, 1);
		 nStims = 3;
		 nonRandomStimNumbers = repmat(1:nStims, [floor(obj.nTrials/nStims), 1]);
		 nonRandomStimNumbers = nonRandomStimNumbers(:);
		 randomIndex = randperm(60);
		 randomStimNumbers = zeros(60,1);
		 for i=1:60
			randomStimNumbers(i) = nonRandomStimNumbers(randomIndex(i));
		 end
		 obj.trialStimulusNumber = randomStimNumbers;
		 obj.currentStimulusNumber = 0;
		 obj.nextStimulusNumber = obj.trialStimulusNumber(1);
	  end	  
   end
   methods % EVENT RESPONSE
	  function experimentStateChangeFcn(obj,~,evnt)
		 % (Required by SubSystem Parent Class)
		 fprintf('TonePuffSystem3: Received ExperimentStateChange event\n')
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
		 fprintf('TonePuffSystem3: Received TrialStateChange event\n')
		 % 		 persistent trialNumberLocal;
		 % 		 if isempty(trialNumberLocal)
		 % 			trialNumberLocal = 0;
		 % 		 end
		 % 		 obj.currentTrialNumber = trialNumberLocal;
		 % 		 fprintf('Queuing Trial %i\n', trialNumberLocal + 1)
		 try			
			% STIMULUS NUMBERS
			if isempty(obj.currentTrialNumber)
			   obj.currentTrialNumber = 0;
			else
			   obj.currentTrialNumber = obj.currentTrialNumber + 1;
			end
			if obj.currentTrialNumber > 0
			   % QUEUE OUTPUT
			   obj.puffObj.queueOutput();
			   obj.toneObj.queueOutput();
			   obj.laserObj.queueOutput();
			   obj.currentStimulusNumber = obj.trialStimulusNumber(obj.currentTrialNumber);
			else
			   obj.currentStimulusNumber = 0;
			end
			if obj.currentTrialNumber >= length(obj.trialStimulusNumber) % last trial
			   obj.nextStimulusNumber = 0;
			else
			   obj.nextStimulusNumber = obj.trialStimulusNumber(obj.currentTrialNumber + 1);
			end
			% DATA FILE
			if ~isempty(obj.currentDataFile)
			   obj.currentDataFile.experimentName = obj.currentExperimentName;
			   if ~isempty(obj.currentDataFile.trialNumber)
				  % previous data-file -> save it
				  obj.saveDataFile();
				  % exits after creating new (blank) currentDataFile
				  % for next trial
			   end
			end
			% 			trialNumberLocal = trialNumberLocal + 1;
			% prepare next DataFile with info for next trial
			% (or minute of recording)
			obj.currentDataFile.trialNumber = obj.currentTrialNumber;
			obj.currentDataFile.stimulusNumber = obj.currentStimulusNumber;
			obj.currentDataFile.experimentName = obj.currentExperimentName;
			% 			fprintf('Start of Trial: %i\n', trialNumberLocal);
		 catch me
			obj.lastError = me;
			keyboard
		 end
	  end
	  function frameAcquiredFcn(obj,src,evnt)
		 timeAtStart = hat;
		 % (Required by SubSystem Parent Class)
		 try
			% INCREMENT FRAME-COUNT
			frameNum = obj.framesAcquired + 1;
			obj.framesAcquired = frameNum;
			% FIRST FRAME
			if isempty(obj.currentDataFile)
			   obj.currentDataFile = TonePuffFile(...
				  'rootPath',obj.currentDataSetPath,...
				  'experimentName',obj.currentExperimentName);%changed rootPath from sessionPath
			end
			
			% EVERY FRAME - ADD FRAME INFO TO FILE
			frameInfo.frameNumber = frameNum;
			frameInfo.triggerTime = evnt.TriggerTime;
			frameInfo.timeStamp = evnt.TimeStamps;
			frameInfo.trialNumber = obj.currentTrialNumber;
			frameInfo.stimulusNumber = obj.currentStimulusNumber;
			frameInfo.highAccuracyTime = hat;
			frameInfo.firstFrame = double(any(frameNum==obj.trialFirstFrame));
			frameInfo.scansAcquired = evnt.Source.ScansAcquired;
			frameInfo.toneSamplesQueued = obj.toneObj.sessionObj.ScansQueued;
			frameInfo.toneSamplesOutput = obj.toneObj.sessionObj.ScansOutputByHardware;
			frameInfo.puffSamplesQueued = obj.puffObj.sessionObj.ScansQueued;
			frameInfo.puffSamplesOutput = obj.puffObj.sessionObj.ScansOutputByHardware;			
			frameInfo.laserSamplesQueued = obj.laserObj.sessionObj.ScansQueued;
			frameInfo.laserSamplesOutput = obj.laserObj.sessionObj.ScansOutputByHardware;		
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
			
			% NOTIFY NEW TRIAL BEGINS WITH NEXT FRAME
			if any((frameNum+1) == obj.trialFirstFrame(1:end-1))
			   notify(obj, 'NewTrial')
			   frameInfo.firstFrame = 1;
			elseif frameNum >= obj.trialFirstFrame(end) %last frame
				  stop(obj)			   
			else			   
			   % LOAD NEXT STIMULUS (+/-puff, +/-tone) 
			   if (hat - timeAtStart) < (.9/obj.frameClkFrequency)
				  if (obj.puffObj.sessionObj.ScansQueued < 1) && (obj.toneObj.sessionObj.ScansQueued < 1) && (obj.laserObj.sessionObj.ScansQueued < 1)
					 obj.puffObj.prepareOutput(obj.puffSignal{obj.nextStimulusNumber});
					 obj.laserObj.prepareOutput(obj.laserSignal(obj.nextStimulusNumber));  %check if i need this
				  end
			   end
			   if (hat - timeAtStart) < (.9/obj.frameClkFrequency)
				  if obj.toneObj.sessionObj.ScansQueued < 1
					 obj.toneObj.prepareOutput(obj.toneSignal{obj.nextStimulusNumber});
				  end
			   end
			end
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
			if isvalid(obj.laserObj)
			   delete(obj.laserObj);
			end
		 catch me
			disp(me.message)
		 end
	  end
   end
   
end

