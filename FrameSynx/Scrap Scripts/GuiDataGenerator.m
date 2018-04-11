classdef GuiDataGenerator < DataGenerator
	  

	  properties (Transient)
			guiObj
	  end
	  properties (Transient, Dependent)
			% GUI Controlled Objects
			stimulusPresentationObj
			cameraObj
			illuminationControlObj
			
			% Graphics Handles
			mainAx
			
			% Camera & illumination Settings
			cameraName
			resolution
			frameRate
			channelSequence
			channels
			channelLabels
			
			% Experiment Settings
			stimulusNames%todo: take input from user
			computeTrigAvgOnline
			trigger %TODO: variable trigger, and write get function for trigger from gui
			nFramesPreTrigger%numFramesPreStim
			nFramesPostTrigger%numFramesPostStim
			stimOnMinimum%stimOnUseThreshold
			trialLengthMinimum
			animalName
			experimentFileName
			experimentFilePath
			savePath
	  end
	  
	  methods
	     function obj = GuiDataGenerator(varargin)
	     obj = obj@DataGenerator('gui');
	     % Argument Checking and Property Settings
	     if nargin > 1
		 for k = 1:2:length(varargin)
		    obj.(varargin{k}) = varargin{k+1};
		 end
	     end
	     end
	  end % Constructor
	  methods % Get Functions (for dependent properties)
	     % Get from Camera
	     function name = get.cameraName(obj)
	     name = obj.cameraObj.name;
	     end
	     function res = get.resolution(obj)
	     res = obj.cameraObj.resolution;
	     end
	     function fr = get.frameRate(obj)
	     fr = obj.cameraObj.frameRate;
	     end
	     % Get from Illumination
	     function sequence = get.channelSequence(obj)
	     sequence = obj.illuminationControlObj.channelSequence;
	     end
	     function waves = get.channels(obj)
	     waves = obj.illuminationControlObj.channels;
			 end
			 function labels = get.channelLabels(obj)
					 labels = obj.illuminationControlObj.channelLabels;
			 end
	     % Get from BehavControl
	     function filename = get.experimentFileName(obj)
	     filename = obj.stimulusPresentationObj.fileName;
	     end
	     function filepath = get.experimentFilePath(obj)
	     filepath = fullfile(obj.savePath,obj.experimentFileName);
% 			 if char(filepath(end)) ~= char('\')
% 					 filepath = [filepath,'\'];
% 			 end
	     end
	     % Get from GUI
	     function bhv = get.stimulusPresentationObj(obj)
	     bhv = obj.guiObj.stimulusPresentationObj;
	     end
	     function cam = get.cameraObj(obj)
	     cam = obj.guiObj.cameraObj;
	     end
	     function light = get.illuminationControlObj(obj)
	     light = obj.guiObj.illuminationControlObj;
	     end
	     function name = get.animalName(obj)
	     name = obj.guiObj.animalName;
	     end
	     function nframes = get.nFramesPreTrigger(obj)
	     nframes = obj.guiObj.nFramesPreTrigger;
	     end
	     function nframes = get.nFramesPostTrigger(obj)
	     nframes = obj.guiObj.nFramesPostTrigger;
	     end
	     function trigstring = get.trigger(obj)
	     trigstring = obj.guiObj.trigger;
	     end
	     function mintime = get.stimOnMinimum(obj)
	     mintime = obj.guiObj.stimOnMinimum;
	     end
	     function mintime = get.trialLengthMinimum(obj)
	     mintime = obj.guiObj.trialLengthMinimum;
	     end
	     function choice = get.computeTrigAvgOnline(obj)
	     choice = obj.guiObj.computeTrigAvgOnline;
	     end
	     function pathstring = get.savePath(obj)
	     pathstring = obj.guiObj.savePath;
	     end
	     function ax = get.mainAx(obj)
	     ax = obj.guiObj.mainAx;
	     end
	  end
	  	  
end
