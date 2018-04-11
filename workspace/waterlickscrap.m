
clockFreq = 100;
s = daq.createSession('ni');
water = s.addDigitalChannel('Dev1','port0/line1','OutputOnly');
lick = s.addDigitalChannel('Dev1','port0/line0','InputOnly');
s.Rate = clockFreq;

sclk = daq.createSession('ni');
ch1 = sclk.addCounterOutputChannel('Dev1','ctr1','PulseGeneration');
sclk.IsContinuous = true;
ch1.Frequency = clockFreq;
sclk.startBackground

s.addClockConnection('External',['Dev1/',ch1.Terminal],'ScanClock')
lh=addlistener(s,'DataAvailable', @plotData); 

s.queueOutputData(ones(100,1));
% dataIn = startForeground(s);
% plot(dataIn)
s.startBackground



