classdef BehavControlInterfaceDefault < DefaultFile
		
		
		
		
			
		properties
		end
		
		
		
		
		
		
		
		methods
				function obj = BehavControlInterfaceDefault(varargin)
						obj = obj@DefaultFile(...
								'className','BehavControlInterface');
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
								'localPort',8936,...
								'remotePort',3180,...
								'BhvControlComputerName','stimulus2',...
								'savePath','Z:\BehavCtrl Interface Logs');
				end
				function evaluateStrings(obj)
						obj.localPort = sscanf(obj.localPort,'%f');
						obj.remotePort = sscanf(obj.remotePort,'%f');
				end
		end
		
		
end