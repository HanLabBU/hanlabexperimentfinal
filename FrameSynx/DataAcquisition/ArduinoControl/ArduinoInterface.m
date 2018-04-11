classdef ArduinoInterface < hgsetget
    % ---------------------------------------------------------------------    
    % ArduinoInterface
    % FrameSynx Toolbox
    % 1/8/2010
    % Mark Bucklin
    % ---------------------------------------------------------------------    
    %
    % The ArduinoInterface class provides the basic functions for
    % communication with the Arduino microcontroller system. The Arduino
    % microcontroller must be loaded with either the the LedSensor or
    % LedController firmware (or something that follows the same protocol).
    % 
    % See also ARDUINOINTERFACEDEFAULT, ARDUINOCONTROL, LEDCONTROL,
    % ILLUMINATIONCONTROL, LEDCONTROLLERINTERFACE, LEDSENSORINTERFACE
    
    
		
		
		properties
				serialObj
				serialTag
				serialPort
		end
		properties % Shared with arduino
				arduinoID
				clientID
		end
		properties (SetObservable,SetAccess = protected)
				currentData % derived classes should define a set function for currentData
				arduinoState %{stopped,setup,running}
				arduinoSetupConfirmed
		end
		properties (Hidden, Transient) % Settings
				timeout
				nArduinos
				frameDataListener
		end
		properties (Hidden)
				default
		end
		
		
		
		events
				DataReceived
		end
		
		
		methods
				function obj = ArduinoInterface(varargin)
						persistent nArduinoCalls
						if nargin > 1
								for k = 1:2:length(varargin)
										obj.(varargin{k}) = varargin{k+1};
								end
						end
						if isempty(nArduinoCalls)
								obj.nArduinos = 1;
								nArduinoCalls = 1;
						else
								nArduinoCalls = nArduinoCalls+1;
								obj.nArduinos = nArduinoCalls;
						end
						obj.arduinoState = 'stopped';
						obj.arduinoSetupConfirmed = false;
				end
				function checkProperties(obj)
						%TODO: use defaults file
						if isempty(obj.default)
								obj.default = ArduinoInterfaceDefault;
						end
						if isempty(obj.serialTag)
								obj.serialTag = sprintf('arduino%i',obj.nArduinos);
						end
						if isempty(obj.serialPort)
								obj.setComFcn
						end
						if isempty(obj.timeout)
								obj.timeout = 3;
						end
						if isempty(obj.clientID)
								obj.clientID = 'matlab';
						end
						if isempty(obj.arduinoID)
								obj.arduinoID = obj.serialTag;
						end
				end
				function setComFcn(obj)
						comOptions = instrhwinfo('serial');
						if length(comOptions.SerialPorts) > 1
								prompt = sprintf('Select arduino COM port for: %s',obj.serialTag);
								selection = menu(prompt,comOptions.SerialPorts);
								if selection
										obj.serialPort = comOptions.SerialPorts{selection};
								else
										obj.serialPort = comOptions.SerialPorts{1};
								end
						else
								obj.serialPort = comOptions.SerialPorts{1};
						end
				end
				function setup(obj)
						try
								obj.arduinoState = 'setup';
								checkProperties(obj)
								obj.serialObj= instrfind('Type', 'serial',...
										'Port', obj.serialPort,...
										'Tag',obj.serialTag);
								if isempty(obj.serialObj)
										obj.serialObj = serial(obj.serialPort,...
												'BaudRate',115200,...
												'Tag',obj.serialTag,...
												'Terminator',{'CR/LF','LF'},...% read terminator CR/LF, write terminated by LF
												'inputbuffersize',1028,...
												'BytesAvailableFcn',@(src,evnt)readSerialFcn(obj,src,evnt));
										fopen(obj.serialObj);%?<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
								elseif isvalid(obj.serialObj)
										obj.arduinoSetupConfirmed  = false;
										stop(obj);
										flushinput(obj.serialObj);
% 										fclose(obj.serialObj);
% 										obj.serialObj = obj.serialObj(1);
								end
								connectArduino(obj)
						catch me
								disp(me)
								warning(me.message)
								obj.arduinoState = 'error';
						end
				end
		end
		methods % Arduino Communication Functions
				function connectArduino(obj)
						try
								if ~obj.arduinoSetupConfirmed
										tic
										restarts=0;
										disp('Waiting for Arduino...')
										while obj.serialObj.BytesAvailable < 1 &&	obj.serialObj.ValuesReceived < 1
												if toc > 3 % seconds allowance before serial object reopend
														disp('Restarting Arduino...')
														fclose(obj.serialObj);
														if restarts > 5
																error('ArduinoInterface:connectArduino','The arduino has failed to initialize')
														end														
														fopen(obj.serialObj);
														restarts = restarts+1;
														tic
												end
												pause(.5)
										end
										disp('Connected Successfully')
								else
										obj.arduinoSetupConfirmed = false;
								end
								sendCommand(obj,'s') % command arduino to setup (repeat request for properties)
								tic
% 								while ~obj.arduinoSetupConfirmed
% 										pause(1);
% 										if toc>5
% 												warning('ArduinoInterface:connectArduino','The arduino has failed to setup')
% 												break
% 										end
% 								end
						catch me
								disp(me.stack(1))
								warning(me.message)
								obj.arduinoState = 'error';
						end
				end
				function start(obj)
						if isempty(obj.serialObj) || ~isvalid(obj.serialObj)
								setup(obj);
						end
						if obj.arduinoSetupConfirmed
								if isempty(obj.frameDataListener)
										obj.frameDataListener = addlistener( ...
												obj, 'currentData', 'PostSet',...
												@(src,evnt)frameDataAcquiredFcn(obj,src,evnt));
								else
										obj.frameDataListener.Enabled = true;
								end
								obj.arduinoState = 'running';
								sendCommand(obj,'a');% send 'a' for activate
								disp('arduino started')
						else
								disp('arduino not started')
						end
				end
				function stop(obj)
						sendCommand(obj,'d') % send 'd' to deactivate
						obj.arduinoState = 'stopped';
						obj.frameDataListener.Enabled = false;
				end
				function readSerialFcn(obj,src,evnt)
						% Read String from Arduino
						msg = fscanf(obj.serialObj,'%s');
%                         fprintf('arduino %s\n',msg)
						if length(msg)<1
								warning('ArduinoInterface:readSerialFcn:ZeroLengthMessage',...
										'Zero-length message received from arduino')
						end
						if  strcmp(msg(1),'@') 
								% Arduino-State: Shouting, WAITING/STOPPED for Response
								disp(msg)
								return % note: could use flushinput somewhere?
						end
						if ~strcmp(obj.arduinoState,'running') 
								% Arduino-State: SETUP (or other?)
								if strcmpi(msg,'confirmsetup')
										obj.arduinoSetupConfirmed = true;
										disp('Arduino Setup Confirmed')
										obj.arduinoState = 'ready';
										return
								end
								if any(strcmpi(properties(obj),msg)) 
										% Arduino Requesting a Property Value Setting (SETUP)
										val2send = eval(sprintf('obj.%s',msg));
										switch class(val2send)
												case 'char'
														fprintf(obj.serialObj,'%s',val2send);
												case 'double'
														fwrite(obj.serialObj,floor(val2send),'uint8'); % or use %d to send int
												case 'cell' % hopefully a char array?
														fprintf(obj.serialObj,'%s',char(val2send));
												otherwise
														fwrite(obj.serialObj,val2send);%uchar default precision
										end
								else
										warning('ArduinoInterface:readSerialFcn:NoProperty',...
												'The Arduino is Requesting an Invalid Property: %s',msg);
								end
						else
								% Arduino-State: RUNNING -> 
								obj.currentData = msg;
								notify(obj,'DataReceived',arduinoSerialMsg(msg))
						end
				end
				function sendCommand(obj,command,varargin)
						fprintf(obj.serialObj,'%s',command);
				end
				function tf = isrunning(obj)
						if strcmp(obj.arduinoState,'running')
								tf = true;
						else
								tf = false;
						end
				end
				function tf = isready(obj)
						if strcmp(obj.arduinoState,'ready')
								tf = true;
						else
								tf = false;
						end
				end
		end
		methods % Set and Get Methods
		end
		methods % Data Processing
				function frameDataAcquiredFcn(obj,src,evnt)
						% This should be overloaded/overwritten in a derived class
				end
		end
		methods % Delete
				function delete(obj)
						try
								if ~isempty(obj.serialObj) && isvalid(obj.serialObj)
										fclose(obj.serialObj);
										delete(obj.serialObj);
								end
								instrreset
						catch me
								disp(me.message)
								disp(me.stack(1))
						end
				end
		end
		
		
		
end

%OLD PROTOCOL (new one just replies to requests for properties)
% Starting Communication Protocol goes like this:
% Once a connection with the arduino is opened, arduino sends 'A' every 100 ms
% matlab sends clientID (e.g. 'matlab') to the arduino
% arduino acknowledges by repeating clientID
% matlab sends arduinoID (e.g. 'ledsensor') to the arduino
% arduino acknowledges by repeating ID




