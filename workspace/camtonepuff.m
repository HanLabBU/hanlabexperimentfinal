%%
obj = CameraSystem(...
  'cameraClass','DcamCamera',...
  'frameSyncMode','auto');
cam = obj.cameraObj;
vio = cam.videoInputObj;
vss = getselectedsource(vio);

%%
obj.cameraObj.resetTrigConfig()
fps = obj.cameraObj.frameRate;

%%

readoutTime = .011; %TODO
framePeriod = 1/fps;
exposureTime = framePeriod-readoutTime;
readoutRatio = readoutTime/framePeriod;

dev = daq.getDevices;
devName = dev(1).ID;
s = daq.createSession('ni');
s.Rate = fps;


clk = s.addCounterOutputChannel(devName,'ctr1','PulseGeneration');
clk.InitialDelay = 0;
clk.DutyCycle = readoutRatio;
s.IsContinuous = true;
clk.Frequency = fps;
s.prepare();

%%
trigger(obj)
s.startBackground
%%
% t = timer(
obj.saveDataFile;
% s.stop

% (to use clock to preview, stop vio/cam.videoInputObj first)
% stop(vio)


% s.addClockConnection('External',[devName,'/',clk.Terminal],'ScanClock')
% lh=addlistener(s,'DataAvailable', @plotData); 
% 
% s.queueOutputData(ones(100,1));
% dataIn = startForeground(s);
% plot(dataIn)
% s.startBackground
% 
% s.stop()

