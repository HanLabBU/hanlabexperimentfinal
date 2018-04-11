classdef LedControllerInterfaceDefault < DefaultFile
		
		
		
		
			
		properties
		end
		
		
		
		
		
		
		
		methods
				function obj = LedControllerInterfaceDefault(varargin)
						obj = obj@DefaultFile(...
								'className','LedControllerInterface');
						if nargin > 1
								for k = 1:2:length(varargin)
										obj.(varargin{k}) = varargin{k+1};
								end
						end
						if isempty(obj.hardCodeDefault)
								defineHardCodeDefaults(obj)
						end
						checkFile(obj)
						readFile(obj)
						evaluateStrings(obj)
				end
		end
		methods (Hidden)
				function defineHardCodeDefaults(obj)
						obj.hardCodeDefault = struct(...
								'nLeds',2,...
								'ledPins',{4,5},...
								'ledLabels',{'r','g'},...
								'serialTag','ledcontroller',...
								'serialPort','COM7',...
								'arduinoID','ledcontroller');
				end
				function evaluateStrings(obj)
						obj.nLeds = sscanf(obj.nLeds,'%f');
						obj.ledPins = strread(obj.ledPins,'%f','delimiter',',');
						obj.ledLabels = strread(obj.ledLabels,'%s','delimiter',',');
				end
		end
		
		
end
