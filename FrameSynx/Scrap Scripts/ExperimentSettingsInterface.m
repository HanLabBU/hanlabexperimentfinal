classdef ExperimentSettingsInterface < hgsetget
	
	
	
	
	
	
	
	properties
    animalName
		saveRoot
	end
	properties (SetAccess = protected)
		savePath
	end
	properties (Hidden, SetAccess = protected)
		default
		gui
	end
	
	
	
	
	
	
	events
		
	end
	
	
	
	
	
	
	methods
		function obj = ExperimentSettingsInterface(varargin)
			global EXPERIMENT_SETTINGS_INTERFACE
			if ~isempty(EXPERIMENT_SETTINGS_INTERFACE) ...
					&& isvalid(EXPERIMENT_SETTINGS_INTERFACE)
				delete(EXPERIMENT_SETTINGS_INTERFACE)
			end
			if nargin > 1
				for k = 1:2:length(varargin)
					obj.(varargin{k}) = varargin{k+1};
				end
			end
			obj.defineDefaults()
			obj.checkProperties()
			if isempty(obj.gui)
				obj.gui = ExperimentSettingsInterfaceGUI(obj);
			end
			EXPERIMENT_SETTINGS_INTERFACE = obj;
		end
		function defineDefaults(obj)
			obj.default = ExperimentSettingsInterfaceDefault;
		end
		function checkProperties(obj)
			props = properties(obj);
			for n = 1:length(props)
				prop = props{n};
				if isempty(obj.(prop)) && isfield(obj.default,prop)
					obj.(prop) = obj.default.(prop);
				end
			end
		end
		
		
	end
	
	
	
	
	
	
	
end
	
	




	
	