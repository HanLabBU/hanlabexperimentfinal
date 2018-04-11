function clkSession = setGlobalFrameClock(fps, devName, counterNum)
global CLK;

if nargin < 1
   fps = 25;
end
if nargin < 2   
   devName = 'Dev2';
end
if nargin < 3
   counterNum = 0;
end

if isempty(CLK) || ~isvalid(CLK.Session)
   CLK.Freq = fps;
   
   % COUNTER SESSION FOR FRAME-CLOCK SOURCE
   clkSession = daq.createSession('ni');
   CLK.Session = clkSession;
   CLK.Channel = CLK.Session.addCounterOutputChannel(devName,counterNum,'PulseGeneration');
   CLK.Terminal = CLK.Channel.Terminal;
   CLK.Channel.Frequency = CLK.Freq;
   CLK.Channel.InitialDelay = 0;
   CLK.Channel.DutyCycle = .1;
   CLK.Session.IsContinuous = true;
   CLK.String = [CLK.Channel.Device.ID,'/',CLK.Channel.Terminal];
   CLK.Session.Rate = CLK.Freq;
else
   clkSession = CLK.Session;
   wasRunning = clkSession.IsRunning;
   if wasRunning
	  stop(clkSession)
   end
   CLK.Freq = fps;
   CLK.Channel.Frequency = CLK.Freq;
   if wasRunning
	  startBackground(clkSession)
   end
end


% TODO: similar function for global stimulus sample-rate