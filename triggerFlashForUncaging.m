function triggerFlashForUncaging()
FPS = 20;

devName = 'Dev2';
obj = NiClockedTriggeredOutput;
obj.signalRate = 1000;
setup(obj)


frameClkSession = setGlobalFrameClock(FPS, devName,0);
frameClkChannel = frameClkSession.Channels(1);




pfiTerminal = 'PFI12';
trigTerminalString = [obj.deviceId, '/', pfiTerminal];
ftc = frameClkSession.addTriggerConnection(trigTerminalString, 'External', 'StartTrigger');
obj.sessionObj.addTriggerConnection('External', trigTerminalString, 'StartTrigger');
frameClkChannel.DutyCycle = .01;




counterNum = 1;
dioClkSession = daq.createSession('ni');
CLK.Session = dioClkSession;
CLK.Channel = CLK.Session.addCounterOutputChannel(devName,1,'PulseGeneration');
CLK.Terminal = CLK.Channel.Terminal;
CLK.Channel.Frequency = obj.sessionObj.Rate;
CLK.Channel.InitialDelay = 0;
CLK.Channel.DutyCycle = .50;
CLK.Session.IsContinuous = true;
CLK.String = [CLK.Channel.Device.ID,'/',CLK.Channel.Terminal];
CLK.Freq = 1000;
CLK.Session.Rate = CLK.Freq;
diocc = CLK.Session.addClockConnection( CLK.String, 'External', 'ScanClock');
obj.sessionObj.addClockConnection('External', CLK.String, 'ScanClock');


flashDelayMilliseconds = 35;
flashTriggerDurationMilliseconds = 1;

obj.signalDelay = flashDelayMilliseconds/obj.signalRate;
obj.outputNumSamples = flashDelayMilliseconds + flashTriggerDurationMilliseconds + 2;
obj.signalGeneratingFcn = @() ones(flashTriggerDurationMilliseconds,1);
obj.signalDuration = flashTriggerDurationMilliseconds/1000;
% numFlashes = 6;
% obj.signalGeneratingFcn = @() cat(1, zeros(flashDelayMilliseconds,1), 1, zeros(4,1));
obj.nextSignal = obj.signalGeneratingFcn();
obj.sessionObj.NotifyWhenScansQueuedBelow = 1;
obj.sessionObj.IsContinuous = true;
% obj.sessionObj.IsNotifyWhenScansQueuedBelowAuto = true;
addlistener(obj.sessionObj, 'DataRequired', @(~,~) prepareOutputRegenerate(obj) )
obj.sessionObj.TriggersPerRun = 1;
obj.prepareOutputRegenerate();


startCamFcn = @() frameClkSession.startBackground;
startDioClkFcn = @() dioClkSession.startBackground;
queueFlashFcn = @() obj.queueOutput;
flashQueuedFcn = @() fprintf('*********FLASH******* (Queued...)\n');
stopCamFcn = @() frameClkSession.stop;
stopDioClkFcn = @() dioClkSession.stop;

stopCamTimer = timer(...
   'ExecutionMode','singleShot',...
   'StartDelay', 10,...
   'TimerFcn', @(~,~) cellfun(@feval, {stopCamFcn, stopDioClkFcn}));

flashTimerFcn = timer(...
   'ExecutionMode','fixedRate',...
   'Period', 1,...
   'StartDelay', 10,...
   'TasksToExecute',5,...
   'StartFcn', @(~,~) cellfun(@feval, {startCamFcn, startDioClkFcn}),...
   'TimerFcn', @(~,~) cellfun(@feval, {queueFlashFcn, flashQueuedFcn}),...
   'StopFcn', @(~,~) start(stopCamTimer));



if  strcmp('Yes', questdlg('Start Now?'))
   start(flashTimerFcn)
end

h=msgbox('click to clear');
set(h,'DeleteFcn', @(~,~)cleanupFcn())

   function cleanupFcn()
	  try
		 delete(flashTimerFcn)
		 delete(stopCamTimer)
		 delete(dioClkSession)
		 delete(frameClkSession)
		 delete(obj)
	  catch
		 delete(timerfindall)
		 clear all global
		 daq.reset()
	  end
   end
end
%
%





%
% cleanupFcn = @() cellfun(@eval,...
%    {'delete(flashTimerFcn)',...
%    'delete(dioClkSession)',...
%    'delete(frameClkSession)',...
%    'delete(obj)',...
%    'clearvars'});

















