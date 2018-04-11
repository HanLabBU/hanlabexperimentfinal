classdef ArduinoInterface < hgsetget
		
		
		
		
		properties
				serialObj
				serialPort
				serialTag
		end
		properties % Shared with arduino
				arduinoID
				clientID
		end
		properties (Hidden, Transient) % Settings
				timeout
				nArduinos
		end
		
		
		
		events
		
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
						checkProperties(obj)
						setup(obj)						
				end
				function checkProperties(obj)
						if isempty(obj.serialPort)
								obj.setComFcn
						end
						if isempty(obj.serialTag)
								obj.serialTag = sprintf('arduino%i',obj.nArduinos);
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
								prompt = 'Select Illumination Arduino COM Port';
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
						obj.serialObj= instrfind('Type', 'serial',...
								'Port', obj.serialPort,...
								'Tag',obj.serialTag);
						if isempty(obj.serialObj)
								obj.serialObj = serial(obj.serialPort,...
										'BaudRate',9600,...
										'Tag',obj.serialTag,...
										'Terminator',{'CR/LF','LF'}); % read lines followed by CR/LF, write a line followed by LF
						else
								fclose(obj.serialObj);
								obj.serialObj = obj.serialObj(1);
						end
						set(obj.serialObj,'inputbuffersize',1028);
						arduinoHandShake(obj);
				end
		end
		methods % Arduino Communication Functions
				function succnot = arduinoHandShake(obj,varargin)
						fclose(obj.serialObj);
						fopen(obj.serialObj);
						if nargin>1
								obj.arduinoID = varargin{1};
						end
						tic
						while(~obj.serialObj.Bytesavailable)
								pause(.02)
								if toc > obj.timeout
										warning('ArduinoInterface:arduinoHandShake','Arduino is not initiating communication')
										break
								end
						end
						fprintf(obj.serialObj,obj.clientID); % identify self
						fscanf(obj.serialObj,'%s'); % clear junk screamer A's
						tmp = fscanf(obj.serialObj,'%s'); % should return 'matlab'
						tmp = strread(tmp,'%s','delimiter',':');
						clientid = tmp{2};
						fprintf(obj.serialObj,obj.arduinoID); % assign the ID to the arduino
						tmp = fscanf(obj.serialObj,'%s'); % wait for arduino to repeat it's ID back
						tmp = strread(tmp,'%s','delimiter',':');
						id = tmp{2};
						if strcmpi(id,obj.arduinoID) ...
										&& strcmp(clientid,obj.clientID)
								succnot = true;
						else
								succnot = false;
						end
				end
		end
		methods % Set and Get Methods
		end
		methods
				function delete(obj)
						fclose(obj.serialObj);
						delete(obj.serialObj);
				end
		end
		
		
		
end

% Starting Communication Protocol goes like this:
% Once a connection with the arduino is opened, arduino sends 'A' every 100 ms
% matlab sends clientID (e.g. 'matlab') to the arduino
% arduino acknowledges by repeating clientID
% matlab sends arduinoID (e.g. 'ledsensor') to the arduino
% arduino acknowledges by repeating ID




