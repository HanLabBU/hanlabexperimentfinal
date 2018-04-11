classdef ImageAcquisitionGUIDefault < DefaultFile
		
		
		
		
		
		properties
		end
		
		
		
		
		
		
		
		methods
				function obj = ImageAcquisitionGUIDefault(varargin)
						obj = obj@DefaultFile(...
								'className','ImageAcquisitionGUI');
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
						obj.hardCodeDefault.configFileDir = ...
								fullfile(imaqroot,'CameraControl\IFC Configuration Files');
						obj.hardCodeDefault.saveRoot = 'Z:\';
						obj.hardCodeDefault.camObjList = {'DalsaCamera','WebCamera'};
						obj.hardCodeDefault.green = [.231 .443 .337];
						obj.hardCodeDefault.red = [.847 .16 0];
						obj.hardCodeDefault.yellow = [.9 .8 .05];
						obj.hardCodeDefault.previewWindowSize = 400;
						obj.hardCodeDefault.maxFR = 30;
						obj.hardCodeDefault.maxminoffset = 4095;
						obj.hardCodeDefault.offset = 0;
						obj.hardCodeDefault.gain = 1;
						obj.hardCodeDefault.maxgain = 10;
						obj.hardCodeDefault.monkeyList = {'YODA','TWEEK','STARBUCK','ENIGMA','RAT'};
						obj.hardCodeDefault.colormapList = {'gray','jet','hot','cool','bone','copper','pink','flag','prism','spring','summer','autumn','winter'};
						obj.hardCodeDefault.moveSequenceOptions = ...
								{'Real-Time','Half-Speed','User-Controlled','Montage'};
						obj.hardCodeDefault.behavControlComputerName = 'stimulus2';
						obj.hardCodeDefault.stimOnMinimum = .5;
						obj.hardCodeDefault.trialLengthMinimum = 3;
						obj.hardCodeDefault.saveRoot = 'Z:\';
				end
				function evaluateStrings(obj)
						obj.camObjList = ...
								strread(obj.camObjList,'%s','delimiter',',');
						obj.green = ...
								sscanf(obj.green,'%f %f %f')';
						obj.red = ...
								sscanf(obj.red,'%f %f %f')';
						obj.yellow = ...
								sscanf(obj.yellow,'%f %f %f')';
						obj.previewWindowSize = ...
								sscanf(obj.previewWindowSize,'%f') ;
						obj.maxFR  = ...
								sscanf(obj.maxFR,'%f') ;
						obj.maxminoffset = ...
								sscanf(obj.maxminoffset,'%f') ;
						obj.offset = ...
								sscanf(obj.offset,'%f') ;
						obj.gain  = ...
								sscanf(obj.gain,'%f') ;
						obj.maxgain  = ...
								sscanf(obj.maxgain,'%f') ;
						obj.monkeyList = ...
								strread(obj.monkeyList,'%s','delimiter',',');
						obj.colormapList = ...
								strread(obj.colormapList,'%s','delimiter',',');
						obj.moveSequenceOptions = ...
								strread(obj.moveSequenceOptions,'%s','delimiter',',');
						obj.stimOnMinimum  = ...
								sscanf(obj.stimOnMinimum,'%f') ;
						obj.trialLengthMinimum = ...
								sscanf(obj.trialLengthMinimum,'%f') ;
						
				end
		end
		
		
end