classdef LedControllerInterface < ArduinoInterface
		
		
		
				
properties % Write To Arduino
		nLeds
		ledPins
		ledLabels
end
properties % Read From Arduino
		ledStates
		frameCount
end
properties (SetObservable) % Frame Data Storage
		frameData
end





methods % Constructor
		function obj = LedControllerInterface(varargin)
				obj = obj@ArduinoInterface(...
						'serialTag','ledsensor',...
						'arduinoID','ledsensor',...
						'clientID','matlab'); %superclass constructor has to be called first
				obj.default = LedControllerInterfaceDefault;
		end
end
methods % Setup
		function setup(obj)
				obj.arduinoState = 'setup';
				obj.setup@ArduinoInterface() % call superclass setup
				if obj.arduinoSetupConfirmed
						obj.frameCount = 0;
						% space here for future use?
						obj.arduinoState = 'ready';
				end
		end
		function checkProperties(obj)
				props = fields(obj.default);
				for n=1:length(props)
						thisprop = sprintf('%s',props{n});
						if isempty(obj.(thisprop))
								obj.(thisprop) = obj.default.(thisprop);
						end
				end
				obj.checkProperties@ArduinoInterface
		end
end
methods % Data Processing
		function frameDataAcquiredFcn(obj,~,~)
				obj.frameCount = obj.frameCount + 1;
				obj.frameData = obj.currentData;
		end
end
methods % Delete
		function delete(obj)
				delete@ArduinoInterface(obj);
		end
end
		
		
		
		
end









