classdef NiPulseOutput < hgsetget
  % ---------------------------------------------------------------------
  % NiPulseOutput
  % Han Lab
  % 1/19/2013
  % Mark Bucklin
  % ---------------------------------------------------------------------
  %
  % This class provides an interface to the National Instruments
  % Multifunction I/O board, NI USB-6259 (by default) for use with
  % experimental instruments (e.g. nosepoke, LEDs, buzzers, speakers,
  % etc.) As opposed to the NIDAQINTERFACE class, this class utilizes the
  % session-based interface which affords compatibility with 64-bit
  % versions of matlab.
  %
  % Note: Changed 12/2014 to also be more generally configured as an analog output.
  %
  % See Also TOUCHINTERFACE TOUCHDISPLAY NIDAQINTERFACE
  
  
  
  
  
  properties % Base Properties (common to Analog & Digital types)
	 type				% 'analog' or 'digital'
	 pulseTime       % in seconds
	 deviceId = 'dev2'
	 channelId
	 default
  end
  properties % Digital Output
	 activeHigh      % true if pulse goes high for pulseTime, then low until called again
	 portNumber
	 lineNumber
  end
  properties % Analog Output
	 aoNumber
	 pulseVal
  end
  properties (SetAccess = protected)
	 sessionObj
	 channelObj
	 deviceObj
	 subSystemObj
	 timerObj
	 isanalog
	 isrunning
	 isready
  end
  
  
  
  
  events
  end
  
  
  
  
  methods % Initialization
	 function obj = NiPulseOutput(varargin)
		% Assign input arguments to object properties
		if nargin > 1
		  for k = 1:2:length(varargin)
			 obj.(varargin{k}) = varargin{k+1};
		  end
		end
		% Define Defaults
		obj.default = struct(...
		  'type','digital',...
		  'deviceId','dev2',...
		  'pulseTime',.010,...
		  'activeHigh',true,...
		  'portNumber',0,...
		  'lineNumber',0,...
		  'aoNumber',0,...
		  'pulseVal',1);
		obj.isready = false;
	 end
	 function setup(obj)
		global ANALOGSESSION
		global DIGITALSESSION
		% Fill in Defaults
		props = fields(obj.default);
		for n=1:length(props)
		  thisprop = sprintf('%s',props{n});
		  if isempty(obj.(thisprop))
			 obj.(thisprop) = obj.default.(thisprop);
		  end
		end
		if strncmpi('analog', obj.type, 1)
		  obj.isanalog = true;
		else
		  obj.isanalog = false;
		end
		% Check/Query Device Selection
		obj.queryDevice();
		% Check/Query Channel Selection
		obj.queryChannel();
		% Make Daq Session and Analog- or Digital-Output Channels the set Initial State		
		if obj.isanalog
		  % Configure as ANALOG OUTPUT		
		   if isempty(ANALOGSESSION)
			  obj.sessionObj = daq.createSession('ni');
			  ANALOGSESSION = obj.sessionObj;
		   else
			  obj.sessionObj = ANALOGSESSION;
		   end  
		  obj.channelObj = obj.sessionObj.addAnalogOutputChannel(obj.deviceId,...
			 obj.channelId, 'Voltage');%sprintf('ao%i',obj.aoNumber)
		  obj.sessionObj.outputSingleScan(zeros(1,numel(obj.sessionObj.Channels)));
		else
		  % Configure as DIGITAL OUTPUT		  
		  %	for n = 1:numel(obj.lineNumber) todo  this part does not work
          if isempty(DIGITALSESSION)
			  obj.sessionObj = daq.createSession('ni');
			  DIGITALSESSION = obj.sessionObj;
          else
%               DIGITALSESSION = DIGITALSESSION.addDigitalChannel('Dev1','port1/line0','OutputOnly'); % added by Mike
			 obj.sessionObj = DIGITALSESSION;
		  end
		  obj.channelObj = obj.sessionObj.addDigitalChannel(...
			 obj.deviceId,...
			 obj.channelId,...
			 'OutputOnly'); sprintf('port%g/line%g',obj.portNumber,obj.lineNumber);	
		  if obj.activeHigh  %start low if activeHigh is true
			 obj.sessionObj.outputSingleScan(zeros(1,numel(obj.sessionObj.Channels)));
		  else
			 obj.sessionObj.outputSingleScan(ones(1,numel(obj.sessionObj.Channels)));
		  end
		end
		% Ready
		obj.isready = true;
	 end
	 function varargout = queryDevice(obj)
		% Display available Device info
		devs = daq.getDevices;
		vendors = cat(1,devs.Vendor);
		devs = devs(strncmp({vendors.ID}','ni',2));
		if isempty(devs)
		  error('NiPulseOutput:NoDevicesFound','No National-Instruments devices found')
		end
		devsel = strcmpi(obj.deviceId, {devs.ID});
		if ~any(devsel)
		  if numel(devs) > 1
			 [devsel,ok] = listdlg('PromptString','Select a Data-Acquisition Device',...
				'SelectionMode','single',...
				'ListSize', [350 200],...
				'ListString', {devs.Description}');
			 if ~ok, return, end
		  end
		end
		obj.deviceObj = devs(max(devsel,1));
		obj.deviceId = obj.deviceObj.ID;
		if nargout
		  varargout{1} = obj.deviceId;
		end
	 end
	 function varargout = queryChannel(obj)
		if isempty(obj.deviceObj)
		  queryDevice();
		end
		subsys = obj.deviceObj.Subsystems;
		if obj.isanalog
		  obj.subSystemObj = subsys(strcmpi('analogoutput',{subsys.SubsystemType}));
		  chanNames = obj.subSystemObj.ChannelNames;
		  [aochans, count] = sscanf(strcat(chanNames{:}), 'ao%f');
		  chansel = (aochans==obj.aoNumber);
		  if ~any(chansel)
			 [chansel,ok] = listdlg('PromptString','Select an Analog-Output Channel (NiPulseOutput)',...
				'SelectionMode','single',...
				'ListSize', [100 count*30],...
				'ListString', chanNames);
			 if ok
				obj.aoNumber = aochans(chansel);
			 else
				return
			 end
		  end
		else
		  obj.subSystemObj = subsys(strcmpi('digitalio',{subsys.SubsystemType}));
		  chanNames = obj.subSystemObj.ChannelNames;
		  [portlinepair, count] = sscanf(strcat(chanNames{:}), 'port%f/line%f');
		  ports = portlinepair(1:2:end);
		  lines = portlinepair(2:2:end);
		  chansel = (ports==obj.portNumber) & (lines==obj.lineNumber);
		  if ~any(chansel)
			 [~,portsort] = sort(100*(ports+1) + lines);
			 chanNames = chanNames(portsort);
			 [chansel,ok] = listdlg('PromptString','Select a Digital-Output Channel (NiPulseOutput)',...
				'SelectionMode','single',...
				'ListSize', [150 count*30],...
				'ListString', chanNames);
			 if ok
				obj.portNumber = ports(portsort(chansel));
				obj.lineNumber = lines(portsort(chansel));
			 else
				return
			 end
		  end
		end
		obj.channelId = chanNames{chansel};
		if nargout
		  varargout{1} = obj.channelId;
		end
	 end
  end
  methods % Input/Output Callback Functions
	 function sendPulse(obj, pulseOnTime, nPulses, pulseOnVal)
		% Using MATLAB timer to manually pulse signal on for a specified (or default) amount of time
		% >> obj.sendPulse()
		% >> obj.sendPulse(.5)				- half-second pulse
		% >> obj.sendPulse(.1, 5)				- pulse train of five one-tenth-second pulses (1/5th second with
		%											50% duty cycle)
		% >> obj.sendPulse(.25, 1, 6)			- quarter-second pulse to +6-volts (if signal is analog)
		if nargin <= 1
		  pulseOnTime = obj.pulseTime;
		end
		if nargin <= 2
		  nPulses = 1;
		end		
		if nargin <= 3		  
		  if obj.isanalog
			 pulseOnVal = obj.pulseVal;
		  else
			 pulseOnVal = obj.activeHigh;
		  end
		end				
		if nPulses > 1
		  followFcn = @(~,~)sendPulse(obj, pulseOnTime, nPulses-.5, ~pulseOnVal);
		else
		  followFcn = @deleteTimerFcn;
		end
		if isempty(obj.timerObj) || ~isvalid(obj.timerObj)
		  obj.timerObj = timer(...
			 'ExecutionMode', 'singleShot',...
			 'StartDelay', pulseOnTime,...
			 'TimerFcn', @(src,evnt)resetPulse(obj,src,evnt),...
			 'TasksToExecute', 1,...
			 'StopFcn', followFcn);
		else
		  obj.timerObj.StartDelay = pulseOnTime;
		  obj.timerObj.TimerFcn = @(src,evnt)resetPulse(obj,src,evnt);
		  obj.timerObj.StopFcn = followFcn;
		end
		obj.sessionObj.outputSingleScan(pulseOnVal); % (set high)
		start(obj.timerObj);
	 end
	 function resetPulse(obj,src,evnt)		
		obj.sessionObj.outputSingleScan(~obj.activeHigh); % (reset low)
     end
     function resetPulseAnalog(obj)		
		obj.sessionObj.outputSingleScan(0); % (reset low)
	 end
  end
  methods % Cleanup
	 function delete(obj)
		global ANALOGSESSION
		global DIGITALSESSION
		if obj.isanalog
		   ANALOGSESSION = [];
		else
		   DIGITALSESSION = [];
		end
		delete(obj.timerObj)
		if isvalid(obj.sessionObj)
		   obj.sessionObj.release()
		   delete(obj.sessionObj);
		end
	 end
  end
  
end






function deleteTimerFcn(src,evnt)
delete(src);
end









