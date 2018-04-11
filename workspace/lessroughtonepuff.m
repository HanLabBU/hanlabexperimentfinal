%% PRECLEAN
delete(frameClkSession)
delete(toneObj)
delete(puffObj)
clear

%% CONSTANTS & INPUTS
devName = 'Dev2';
frameClkFrequency = 25;
counterNum = 0;
stimulusSampleFrequency = 100000;

%% COUNTER SESSION FOR FRAME-CLOCK SOURCE
frameClkSession = daq.createSession('ni');
frameClkChannel = frameClkSession.addCounterOutputChannel(devName,counterNum,'PulseGeneration');
frameClkTerminal = frameClkChannel.Terminal;
frameClkChannel.Frequency = frameClkFrequency;
frameClkChannel.InitialDelay = 0;
frameClkChannel.DutyCycle = .1;
frameClkSession.IsContinuous = true;
frameClkString = [frameClkChannel.Device.ID,'/',frameClkChannel.Terminal];
frameClkSession.Rate = frameClkFrequency;

%% ANALOG OUTPUT
toneObj = NiClockedTriggeredOutput(...
  'deviceId', devName,...
  'type', 'analog',...
  'channelId', 'ao0',...
  'signalRate',stimulusSampleFrequency);
setup(toneObj);
clkSrc = toneObj.getClockSource('PFI1');
toneObj.setTriggerSource(frameClkString);

%% DIGITAL OUTPUT
puffObj = NiClockedTriggeredOutput(...
  'deviceId', devName,...
  'type', 'digital',...
  'channelId', 'port0/line0',...
  'signalRate',stimulusSampleFrequency);
setup(puffObj);
puffObj.setClockSource(clkSrc);



%%
puffObj.signalDuration = .1;
puffObj.signalDelay = 1.5;
toneObj.signalDuration = 1;
toneObj.signalDelay = 0;
M = max(...
  ceil(stimulusSampleFrequency*toneObj.signalDuration)+ceil(stimulusSampleFrequency*toneObj.signalDelay),...
  ceil(stimulusSampleFrequency*puffObj.signalDuration)+ceil(stimulusSampleFrequency*puffObj.signalDelay) )...
  + round(stimulusSampleFrequency/10);
toneObj.outputNumSamples = M+1000;
puffObj.outputNumSamples = M+1000;
% puffObj.nextSignal = zeros(M,1);
% puffObj.nextSignal(floor(puffObj.signalDelay*aFs) + (1:ceil(puffObj.signalDuration*aFs))) = 1;
% puffObj.nextSignal((end-10):end) = 0; % important!!
puffObj.signalGeneratingFcn = @()ones(floor(puffObj.signalDuration*puffObj.signalRate),1);
% SINE-WAVE
sw = dsp.SineWave;
sw.SampleRate = stimulusSampleFrequency;
sw.SamplesPerFrame = stimulusSampleFrequency*toneObj.signalDuration;
sw.Frequency = 700;
% CHIRP
cw = dsp.Chirp;
cw.InitialFrequency = 1500;
cw.TargetFrequency = 2000;
cw.SampleRate = sw.SampleRate;
cw.SamplesPerFrame = sw.SamplesPerFrame;
% COMBINE
toneVol = .9;
toneObj.signalGeneratingFcn = @()toneVol.*sw.step.*cw.step;
% toneObj.nextSignal = zeros(M,1);
% toneObj.nextSignal(floor(toneObj.signalDelay*aFs) + (1:ceil(toneObj.signalDuration*aFs))) = sw.step.*cw.step;

%% START CAMERA
frameClkSession.startBackground;

%% QUEUE TONE & PUFF
toneObj.prepareOutput();
puffObj.prepareOutput();

%% START TONE & PUFF
puffObj.queueOutput();
toneObj.queueOutput();

% sig.release();
% sig.Frequency = 200;
% frameTrigSession.queueOutputData([puffObj.nextSignal, toneObj.nextSignal]);
% frameTrigSession.startBackground;

% toneObj.sessionObj.queueOutputData(toneVol .* toneObj.nextSignal);
% puffObj.sessionObj.queueOutputData(puffObj.nextSignal);
% puffObj.sessionObj.startBackground();
% toneObj.sessionObj.startBackground();

% puffObj.sessionObj.outputSingleScan(0)
%%
stop(frameClkSession)
delete(toneObj.sessionObj)
delete(puffObj.sessionObj)
delete(frameClkSession)
clear all, close all
daq.reset();

%%
% frameTrigSession.addTriggerConnection('External',frameClkString,'StartTrigger');
% frameTrigSession.Rate = frameClkFrequency;
% frameTrigSession.addClockConnection('External', [devName,'/',frameClkTerminal], 'ScanClock');
% lick = frameTrigSession.addDigitalChannel(devName,'port0/line0','InputOnly');
% frameTrigSession.Rate = frameClkFrequency;
% addClockConnection(frameTrigSession, 'External', [devName,'/',frameClkTerminal], 'ScanClock');



%%
% M = 20;
% queueMoreData = @(src,event) queueOutputData(frameTrigSession,...
%   cat(2, [1;zeros(M-1,1)], [zeros(M-1,1);1], sin(linspace(0,2*pi*20,M))', [ones(5,1);ones(M-5,1)]));
% lh = addlistener(frameTrigSession,'DataRequired',queueMoreData);
% 
% frameClkSession.startBackground
% 
% outputSingleScan(s,[decimalToBinaryVector(2),1.23])

%%
% 
% puffString =  [frameClkChannel.Device.ID,'/','PFI1'];
% snuffString =  [frameClkChannel.Device.ID,'/','PFI2'];
% puffConn = frameTrigSession.addTriggerConnection(frameClkString, puffString, 'StartTrigger')
% 
% 
% frameTrigSession.queueOutputData(ones(100,1));
% frameTrigSession.startBackground



% frameTrigSession.addClockConnection('External',[devName,'/',frameClkChannel.Terminal],'ScanClock')
% frameClkChannel.startBackground
% dataIn = startForeground(frameTrigSession);
% plot(dataIn)
% puff = frameTrigSession.addDigitalChannel(devName,'port1/line1','OutputOnly');
% lick = frameTrigSession.addDigitalChannel(devName,'port1/line0','InputOnly');