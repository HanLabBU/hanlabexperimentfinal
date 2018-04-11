classdef SystemSynchronizerDefault < DefaultFile
		
		
		
		
			
		properties
		end
		
		
		
		
		
		
		
		methods
				function obj = SystemSynchronizerDefault(varargin)
						obj = obj@DefaultFile(...
								'className','SystemSynchronizer');
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
						obj.hardCodeDefault.saveRoot = 'F:\Data\';
						obj.hardCodeDefault.animalName = 'mouse1';
						obj.hardCodeDefault.animalNameList = {'mouse1','mouse2','mouse3','mouse4','squirrel0'};												
				end
				function evaluateStrings(obj)
						obj.animalNameList = ...
								strread(obj.animalNameList,'%s','delimiter',',');
				end
		end
		
		
end









