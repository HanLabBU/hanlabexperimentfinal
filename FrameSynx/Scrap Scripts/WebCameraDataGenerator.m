classdef WebCameraDataGenerator < DataGenerator
		
		
		
		
		
		
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
		
		properties
				dvs
				default
		end
		
		
		
		
		
		
		
		methods % Constructor/Destructor & Defaults
				function obj = WebCameraDataGenerator(varargin)
						obj = obj@DataGenerator('web');
						% Argument Checking and Property Settings
						if nargin > 1
								for k = 1:2:length(varargin)
										obj.(varargin{k}) = varargin{k+1};
								end
						end
						defineDefaults(obj)
						set(obj.dvs.cameraObj,'frameRate',obj.default.frameRate);
						start(obj.cameraObj)
				end
				function defineDefaults(obj)
						obj.default.BhvControlComputerName = 'analysis2';
						obj.default.frameRate = 15;
						obj.default.saveRoot = 'E:\Data\';
						obj.dvs.animalName = 'RAT';
						obj.dvs.nFramesPreTrigger = 1;
						obj.dvs.nFramesPostTrigger = 1;
						obj.dvs.trigger = 'Trial on';
						obj.dvs.stimOnMinimum = 1;
						obj.dvs.trialLengthMinimum = 1;
						obj.dvs.computeTrigAvgOnline = false;
						obj.dvs.mainAx = [];
						obj.dvs.cameraObj = WebCamera;
						obj.dvs.illuminationControlObj = IlluminationControl;
						obj.dvs.stimulusPresentationObj = BehavControlInterface(...
								'dataGeneratorObj',obj,...
								'BhvControlComputerName',obj.default.BhvControlComputerName,...;
								'showLog','yes');
				end
		end
		
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
				% Get from BehavControl
				function filename = get.experimentFileName(obj)
						filename = obj.stimulusPresentationObj.fileName;
				end
				function filepath = get.experimentFilePath(obj)
						filepath = [obj.savePath,obj.experimentFileName];
						if char(filepath(end)) ~= char('\')
								filepath = [filepath,'\'];
						end
				end
				% Get from GUI
				function bhv = get.stimulusPresentationObj(obj)
						bhv = obj.dvs.stimulusPresentationObj;
				end
				function cam = get.cameraObj(obj)
						cam = obj.dvs.cameraObj;
				end
				function light = get.illuminationControlObj(obj)
						light = obj.dvs.illuminationControlObj;
				end
				function name = get.animalName(obj)
						if isfield(obj.dvs,'animalName')
								name = obj.dvs.animalName;
						else
								name = 'ANIMAL';
						end
				end
				function nframes = get.nFramesPreTrigger(obj)
						nframes = obj.dvs.nFramesPreTrigger;
				end
				function nframes = get.nFramesPostTrigger(obj)
						nframes = obj.dvs.nFramesPostTrigger;
				end
				function trigstring = get.trigger(obj)
						trigstring = obj.dvs.trigger;
				end
				function mintime = get.stimOnMinimum(obj)
						mintime = obj.dvs.stimOnMinimum;
				end
				function mintime = get.trialLengthMinimum(obj)
						mintime = obj.dvs.trialLengthMinimum;
				end
				function choice = get.computeTrigAvgOnline(obj)
						choice = obj.dvs.computeTrigAvgOnline;
				end
				function pathstring = get.savePath(obj)
						if isdir(obj.default.saveRoot)
								pathstring = [obj.default.saveRoot,...
										obj.animalName,'\',...
										obj.animalName,datestr(date,'_mm_dd_yy'),'\'];
						else
								saveroot = uigetdir('C:','Choose the image data root directory');
								pathstring = [saveroot,...
										obj.animalName,'\',...
										obj.animalName,datestr(date,'_mm_dd_yy'),'\'];
						end						
						if char(pathstring(end)) ~= char('\')
								pathstring = [pathstring,'\'];
						end
				end
				function ax = get.mainAx(obj)
						ax = obj.dvs.mainAx;
				end
		end
		
		
		
		
		
end
