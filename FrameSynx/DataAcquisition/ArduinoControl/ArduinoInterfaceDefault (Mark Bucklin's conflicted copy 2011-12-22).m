classdef ArduinoInterfaceDefault < DefaultFile
		
		
			
		properties
		end
		
		
		
		
		methods
				function obj = ArduinoInterfaceDefault(varargin)
						obj = obj@DefaultFile(...
								'className','ArduinoInterface');
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
								'serialTag','arduino',...
								'serialPort','COM7',...
								'arduinoID','susan');
				end
				function evaluateStrings(obj)
				end
		end
		
		
end
