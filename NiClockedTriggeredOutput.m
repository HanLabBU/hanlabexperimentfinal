
classdef NiClockedTriggeredOutput < NiPulseOutput
  
  
  
  properties
	 signalRate
	 signalDuration
	 signalDelay
	 nextSignal
	 signalGeneratingFcn
	 outputNumSamples
  end
  properties (SetAccess = protected)
	 triggerSource
	 triggerConnection
	 clockSource
	 clockConnection
  end
  
  
  
  
  events
	 OutputPrepared
	 OutputQueued
  end
  
  
  
  
  methods % Initialization
	 function obj = NiClockedTriggeredOutput(varargin)
		obj = obj@NiPulseOutput(varargin{:});
		% Assign input arguments to object properties
		% 		if nargin > 1
		% 		  for k = 1:2:length(varargin)
		% 			 obj.(varargin{k}) = varargin{k+1};
		% 		  end
		% 		end
		% Define Defaults
		obj.default.signalRate = 100000;
	 end
	 function setup(obj)
		obj.setup@NiPulseOutput();
	 end
	 function setClockSource(obj, clkSrcObj)		
		clkTerminalString = clkSrcObj.clockSource;
		obj.sessionObj.addClockConnection('External', clkTerminalString, 'ScanClock');
		obj.signalRate = clkSrcObj.signalRate;
		obj.sessionObj.Rate = obj.signalRate;
		obj.clockSource = clkTerminalString;
	 end
	 function clkSrc = getClockSource(obj, pfiTerminal)
		% Output scan-clock to share with digital system
		clkTerminalString = [obj.deviceId, '/', pfiTerminal];
		obj.clockConnection = obj.sessionObj.addClockConnection(clkTerminalString, 'External', 'ScanClock'); 
		obj.clockSource = clkTerminalString;
		obj.sessionObj.Rate = obj.signalRate;
		clkSrc = obj;
	 end	 
	 function setTriggerSource(obj,trigSrc)
		% 		trigTerminalString = [trigSrc.Device.ID,'/',trigSrc.Terminal];
		obj.triggerConnection = obj.sessionObj.addTriggerConnection('External', trigSrc, 'StartTrigger');
		obj.triggerSource = trigSrc;
		obj.sessionObj.ExternalTriggerTimeout = 60;
	 end
	 function trigSrc = getTriggerSource(obj, pfiTerminal)
		% Output scan-clock to share with digital system
		trigTerminalString = [obj.deviceId, '/', pfiTerminal];
		obj.triggerConnection = obj.sessionObj.addTriggerConnection(trigTerminalString, 'External', 'StartTrigger'); 
		obj.triggerSource = trigTerminalString;
		obj.sessionObj.Rate = obj.signalRate;
		trigSrc = trigTerminalString;
	 end
  end
  methods % Input/Output Callback Functions
	 function varargout = prepareOutput(obj, varargin)
		if nargin > 1
		  obj.nextSignal = varargin{1};
		elseif isempty(obj.nextSignal) && ~isempty(obj.signalGeneratingFcn)
		  signalSize = obj.signalRate*(obj.signalDuration+obj.signalDelay);
		  if ~isempty(obj.outputNumSamples)
			 M = max(obj.outputNumSamples, signalSize);
		  else
			 M = signalSize;
		  end
		  obj.nextSignal = zeros(M,1);
		  sig = feval(obj.signalGeneratingFcn);
		  sig = sig(:);
		  obj.nextSignal(floor(obj.signalRate*obj.signalDelay) + (1:numel(sig))) = sig;
		end
		if (obj.sessionObj.ScansQueued < 1)...
			  && (~obj.sessionObj.IsRunning || obj.sessionObj.IsContinuous)...
			  && ~isempty(obj.nextSignal)
		   obj.sessionObj.queueOutputData(obj.nextSignal);
		   obj.sessionObj.prepare();%new
		   notify(obj,'OutputPrepared')
		end
		if nargout
		  varargout{1} = obj.nextSignal;
		end
	 end
	 function varargout = prepareOutputRegenerate(obj, varargin)
		if nargin > 1		  
		  obj.nextSignal = varargin{1};
		elseif ~isempty(obj.signalGeneratingFcn)
		  signalSize = obj.signalRate*(obj.signalDuration+obj.signalDelay);
		  if ~isempty(obj.outputNumSamples)
			 M = max(obj.outputNumSamples, signalSize);
		  else
			 M = signalSize;
		  end
		  obj.nextSignal = zeros(M,1);
		  sig = feval(obj.signalGeneratingFcn);
		  sig = sig(:);
		  obj.nextSignal(floor(obj.signalRate*obj.signalDelay) + (1:numel(sig))) = sig;
		end
		obj.sessionObj.queueOutputData(obj.nextSignal);
		if nargout
		  varargout{1} = obj.nextSignal;
		end
	 end
	 function queueOutput(obj)
		if isempty(obj.nextSignal) || obj.sessionObj.ScansQueued<1
		  obj.prepareOutput();
		end
		% 		if obj.sessionObj.ScansQueued<1
		if ~obj.sessionObj.IsRunning
		   obj.sessionObj.startBackground();
		end
		notify(obj,'OutputQueued')
	 end
  end
  methods % Cleanup
	 function delete(obj)
		stop(obj.sessionObj)
		release(obj.sessionObj)
		delete(obj.sessionObj)
	 end
  end
  
end










