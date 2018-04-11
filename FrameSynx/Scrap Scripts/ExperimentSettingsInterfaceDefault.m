classdef ExperimentSettingsInterfaceDefault < DefaultFile
		
		
		
		
			
		properties
		end
		
		
		
		
		
		
		
		methods
				function obj = ExperimentSettingsInterfaceDefault(varargin)
						obj = obj@DefaultFile(...
								'className','ExperimentSettingsInterface');
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
						obj.hardCodeDefault.saveRoot = 'Z:\';
						obj.hardCodeDefault.animalName = 'YODA';
						obj.hardCodeDefault.animalNameList = {'YODA','TWEEK','STARBUCK','ENIGMA','RAT'};
				end
				function evaluateStrings(obj)
						obj.animalNameList = ...
								strread(obj.animalNameList,'%s','delimiter',',');
				end
		end
		
		
end









