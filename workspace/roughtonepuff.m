%% CONSTANTS & INPUTS
devName = 'Dev2';
clkFreq = 1;
counterNum = 0;

%% COUNTER SESSION FOR FRAME-CLOCK SOURCE
s.clk = daq.createSession('ni');
camClk = s.clk.addCounterOutputChannel(devName,counterNum,'PulseGeneration');
clkTerminal = camClk.Terminal;
camClk.Frequency = clkFreq;
camClk.InitialDelay = 0;
camClk.DutyCycle = .1;
s.clk.IsContinuous = true;
clkString = [camClk.Device.ID,'/',camClk.Terminal];
s.clk.Rate = clkFreq;

%% ANALOG OUTPUT
s.aio = daq.createSession('ni');
tone = s.aio.addAnalogOutputChannel(devName,'ao0','Voltage');
aFs = 100000; 
s.aio.Rate = aFs;
s.aio.addTriggerConnection('External',clkString,'StartTrigger'); % Input (from frame-clock) to trigger a start
s.aio.addClockConnection('Dev2\PFI1', 'External', 'ScanClock'); % Output to share with digital system

%% DIGITAL OUTPUT
s.dio = daq.createSession('ni');
puff = s.dio.addDigitalChannel(devName,'port0/line0','OutputOnly');
s.dio.addClockConnection('External', 'Dev2\PFI1', 'ScanClock');
s.dio.Rate = s.aio.Rate;

%%
% s.clk.addClockConnection('Dev2\PFI5', 'External', 'ScanClock')
% s.clk.addClockConnection('Dev2\PFI5','External', 'ScanClock') %dummy?
% frameTrigSession.addTriggerConnection('Dev2\PFI5', 'External', 'StartTrigger');
s.clk.startBackground;
% frameTrigSession.removeConnection(1)
% s.clk.removeConnection(1)

%%
puffDur = .1;
puffDelay = 1.5;
toneDur = 1;
toneDelay = 0;
M = max( ceil(aFs*toneDur)+ceil(aFs*toneDelay), ceil(aFs*puffDur)+ceil(aFs*puffDelay) ) + round(aFs/10);
puffSig = zeros(M,1);
puffSig(floor(puffDelay*aFs) + (1:ceil(puffDur*aFs))) = 1;
puffSig((end-10):end) = 0; % important!!
% SINE-WAVE
sw = dsp.SineWave;
sw.SampleRate = aFs;
sw.SamplesPerFrame = aFs*toneDur;
sw.Frequency = 700;
% CHIRP
cw = dsp.Chirp;
cw.InitialFrequency = 400;
cw.TargetFrequency = 2000;
cw.SampleRate = sw.SampleRate;
cw.SamplesPerFrame = sw.SamplesPerFrame;
% COMBINE
toneSig = zeros(M,1);
toneSig(floor(toneDelay*aFs) + (1:ceil(toneDur*aFs))) = sw.step.*cw.step;

%%
% sig.release();
% sig.Frequency = 200;
% frameTrigSession.queueOutputData([puffSig, toneSig]);
% frameTrigSession.startBackground;
toneVol = .9;
s.aio.queueOutputData(toneVol .* toneSig);
s.dio.queueOutputData(puffSig);
s.dio.startBackground();
s.aio.startBackground();

% s.dio.outputSingleScan(0)
%%
stop(s.clk)
delete(s.aio)
delete(s.dio)
delete(s.clk)
clear all, close all
daq.reset();

%%
% frameTrigSession.addTriggerConnection('External',clkString,'StartTrigger');
% frameTrigSession.Rate = clkFreq;
% frameTrigSession.addClockConnection('External', [devName,'/',clkTerminal], 'ScanClock');
% lick = frameTrigSession.addDigitalChannel(devName,'port0/line0','InputOnly');
% frameTrigSession.Rate = clkFreq;
% addClockConnection(frameTrigSession, 'External', [devName,'/',clkTerminal], 'ScanClock');



%%
% M = 20;
% queueMoreData = @(src,event) queueOutputData(frameTrigSession,...
%   cat(2, [1;zeros(M-1,1)], [zeros(M-1,1);1], sin(linspace(0,2*pi*20,M))', [ones(5,1);ones(M-5,1)]));
% lh = addlistener(frameTrigSession,'DataRequired',queueMoreData);
% 
% s.clk.startBackground
% 
% outputSingleScan(s,[decimalToBinaryVector(2),1.23])

%%
% 
% puffString =  [camClk.Device.ID,'/','PFI1'];
% snuffString =  [camClk.Device.ID,'/','PFI2'];
% puffConn = frameTrigSession.addTriggerConnection(clkString, puffString, 'StartTrigger')
% 
% 
% frameTrigSession.queueOutputData(ones(100,1));
% frameTrigSession.startBackground



% frameTrigSession.addClockConnection('External',[devName,'/',camClk.Terminal],'ScanClock')
% camClk.startBackground
% dataIn = startForeground(frameTrigSession);
% plot(dataIn)
% puff = frameTrigSession.addDigitalChannel(devName,'port1/line1','OutputOnly');
% lick = frameTrigSession.addDigitalChannel(devName,'port1/line0','InputOnly');