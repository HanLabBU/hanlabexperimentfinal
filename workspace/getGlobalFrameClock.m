function clkSession = getGlobalFrameClock()

global CLK;
if isempty(CLK)
  % FRAME-TRIGGER/CLOCK  %TODO!!!!!!!!
  devName = 'Dev2';
  CLK.Freq = 25;
  counterNum = 0;
  aFs = 100000;
  
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
end