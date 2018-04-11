%% CONSTANTS & INPUTS
devName = 'Dev2';
clkFreq = 4;
counterNum = 0;

%% COUNTER SESSION FOR CLOCK SOURCE
clkSession = daq.createSession('ni');
camClk = clkSession.addCounterOutputChannel(devName,counterNum,'PulseGeneration');
clkTerminal = camClk.Terminal;
camClk.Frequency = clkFreq;
camClk.InitialDelay = 0;
camClk.DutyCycle = 1/1024;
clkSession.IsContinuous = true;
clkString = [camClk.Device.ID,'/',camClk.Terminal];

%% DIGITAL OUTPUT
dioSession = daq.createSession('ni');
% puff = dioSession.addDigitalChannel(devName, 'port1/line1', 'OutputOnly'); % port1 doesn't support clocked sampling
puff = dioSession.addDigitalChannel(devName,'port0/line0','OutputOnly');
dioTrig = dioSession.addTriggerConnection('External',clkString,'StartTrigger');
dioSession.Rate = clkFreq;

dioSession.addClockConnection('External', [devName,'/',clkTerminal], 'ScanClock');
% lick = dioSession.addDigitalChannel(devName,'port0/line0','InputOnly');
% dioSession.Rate = clkFreq;
% addClockConnection(dioSession, 'External', [devName,'/',clkTerminal], 'ScanClock');

%% ANALOG OUTPUT
aioSession = daq.createSession('ni');
tone = aioSession.addAnalogOutputChannel(devName,'ao0','Voltage');
aioSession.addTriggerConnection('External',clkString,'StartTrigger');
aFs = 100000; 
aioSession.Rate = aFs;

%% 
clkSession.startBackground;

%%
dioSession.queueOutputData([zeros(2,1);ones(2,1)]);
dioSession.startBackground;

%%
dur = 1; 
sig = dsp.SineWave;
sig.SampleRate = aFs;
sig.SamplesPerFrame = aFs*dur;

%%
sig.release();
sig.Frequency = 200;
aioSession.queueOutputData(sig.step);
aioSession.startBackground;


% M = 20;
% queueMoreData = @(src,event) queueOutputData(dioSession,...
%   cat(2, [1;zeros(M-1,1)], [zeros(M-1,1);1], sin(linspace(0,2*pi*20,M))', [ones(5,1);ones(M-5,1)]));
% lh = addlistener(dioSession,'DataRequired',queueMoreData);
% 
% clkSession.startBackground
% 
% outputSingleScan(s,[decimalToBinaryVector(2),1.23])

%%
% 
% puffString =  [camClk.Device.ID,'/','PFI1'];
% snuffString =  [camClk.Device.ID,'/','PFI2'];
% puffConn = dioSession.addTriggerConnection(clkString, puffString, 'StartTrigger')
% 
% 
% dioSession.queueOutputData(ones(100,1));
% dioSession.startBackground



% dioSession.addClockConnection('External',[devName,'/',camClk.Terminal],'ScanClock')
% camClk.startBackground
% dataIn = startForeground(dioSession);
% plot(dataIn)
% puff = dioSession.addDigitalChannel(devName,'port1/line1','OutputOnly');
% lick = dioSession.addDigitalChannel(devName,'port1/line0','InputOnly');