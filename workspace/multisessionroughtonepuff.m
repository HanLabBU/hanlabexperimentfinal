%% CONSTANTS & INPUTS
devName = 'Dev2';
clkFreq = 25;
counterNum = 0;

%% COUNTER SESSION FOR CLOCK SOURCE
clkSession = daq.createSession('ni');
camClk = clkSession.addCounterOutputChannel(devName,counterNum,'PulseGeneration');
clkTerminal = camClk.Terminal;
camClk.Frequency = clkFreq;
camClk.InitialDelay = 0;
camClk.DutyCycle = 1/1024;
clkSession.IsContinuous = true;

%%
dioSession = daq.createSession('ni');
% puff = dioSession.addDigitalChannel(devName, 'port1/line1', 'OutputOnly'); % port1 doesn't support clocked sampling
puff = dioSession.addDigitalChannel(devName,'port0/line0','OutputOnly');
% lick = dioSession.addDigitalChannel(devName,'port0/line0','InputOnly');
dioSession.Rate = clkFreq;
addClockConnection(dioSession, 'External', [devName,'/',clkTerminal], 'ScanClock');
tone = dioSession.addAnalogOutputChannel(devName,'ao0','Voltage');
dioSession.Rate = clkFreq;

%%
M = 20;
queueMoreData = @(src,event) queueOutputData(dioSession,...
  cat(2, [1;zeros(M-1,1)], [zeros(M-1,1);1], sin(linspace(0,2*pi*20,M))', [ones(5,1);ones(M-5,1)]));
lh = addlistener(dioSession,'DataRequired',queueMoreData);







% 
% clkSession.startBackground
% 
% outputSingleScan(s,[decimalToBinaryVector(2),1.23])

%%
clkString = [camClk.Device.ID,'/',camClk.Terminal];
puffString =  [camClk.Device.ID,'/','PFI1'];
snuffString =  [camClk.Device.ID,'/','PFI2'];
puffConn = dioSession.addTriggerConnection(clkString, puffString, 'StartTrigger')


dioSession.queueOutputData(ones(100,1));
dioSession.startBackground



% dioSession.addClockConnection('External',[devName,'/',camClk.Terminal],'ScanClock')
% camClk.startBackground
% dataIn = startForeground(dioSession);
% plot(dataIn)
% puff = dioSession.addDigitalChannel(devName,'port1/line1','OutputOnly');
% lick = dioSession.addDigitalChannel(devName,'port1/line0','InputOnly');