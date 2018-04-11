classdef DcamCamera < MatlabCompatibleCamera
  % ------------------------------------------------------------------------------
  % DcamCamera
  % FrameSynx toolbox
  % 1/8/2009
  % Mark Bucklin
  % ------------------------------------------------------------------------------
  %
  % This class derives from the abstract class, CAMERA, to provide an
  % interface with the Dalstar 1M30P CCD Camera, made by Dcam.
  %
  % SYNTAX:
  % >> cameraObject = DcamCamera;
  % or
  % >> cameraObject = DcamCamera('propertyname1',value1,...)
  %
  % where propertyname can be any one of the following properties.
  %
  % DcamCamera Properties:
  %     serialPort - Port for configuration of Camera hardware, e.g. 'COM5'
  %     gain - Camera hardware setting, accepts values 1 to 10
  %     offset - Camera hardware setting, accepts values -4095 to 4095
  %     triggerMode - Camera hardware setting, 'auto', 'manual', or 'sync'
  %     configFileDirectory - Directory containing 4 IFC configuration files
  %     configurationFile - Current configuration file name
  %     resolutionOptions - 128, 256, 512, or 1024 pixel width
  %     name
  %     frameRate - Can be set as high as 30 or higher at low resolution
  %     resolution - Set to one of four optional resolution values
  %     camAdapter - 'coreco'
  %     deviceID - Usually set to 1, can set for multiple Camera use
  %     videoFormat - Configuration directory and filename
  %     videoInputObj
  %     hardwareSettingsInterface - object of class 'DcamCamSerialConnection'
  %     previewFigure - Handle to the preview figure
  %     previewImageObj - Handle to preview image object
  %
  % Camera properties can be set on instantiation or using either set format, i.e.
  % set(cameraObject,'propertyname') or cameraObject.propertyname = value.
  %
  % DcamCamera Methods:
  %   setup - creates videoinput object for 'coreco' framegrabber
  %   reset - reset videoinput object and serial connection
  %   softReset - resets camera via serial connection
  %   hardReset - resets camera via serial connection (power off-on)
  %
  % IMPORTANT:
  % Be sure to delete the DcamCamera object at the end of a recording session
  % with the following syntax:
  %
  % >> delete(dalsaCameraObject)
  %
  %
  % See also MATLABCOMPATIBLECAMERA, CAMERA, DALSACAMSERIALCONNECTION,
  % WEBCAMERA, DALSACAMERADEFAULT, DALSACAMERAGUI, CAMERASYSTEM,
  % CAMERACONTROL
  
  
  
  properties (SetObservable,GetObservable)
	 % 	 name
	 % 	 frameRate
	 % 	 resolution
	 % 	 gain
	 % 	 offset
	 % 	 triggerMode
	 % 	 triggerConfiguration
  end
  properties (SetObservable, GetObservable)
	 %     serialPort
	 %     configFileDirectory
  end
  properties (Dependent)
	 %     configurationFile
  end
  properties (Access = private)
	 default
  end
  
  
  
  
  
  
  methods % Constructor & Destructor
	 function obj = DcamCamera(varargin)
		if nargin > 1
		  for k = 1:2:length(varargin)
			 obj.(varargin{k}) = varargin{k+1};
		  end
		end
		obj.default = DcamCameraDefault; %subclass of DefaultFile class
	 end
	 function delete(obj)
		try
		  if ~isempty(obj.videoInputObj)
			 if isrunning(obj.videoInputObj)
				stop(obj)
			 end
			 delete(obj.videoInputObj);
		  end
		  %         delete(obj.hardwareSettingsInterface)
		catch me
		  warning(me.message)
		  disp(me.stack(1))
		end
	 end
	 function checkProperties(obj)
		if isempty(obj.name)
		  obj.name = obj.default.name;
		end
		if isempty(obj.gain)
		  obj.gain = obj.default.gain;
		end
		if isempty(obj.offset)
		  obj.offset = obj.default.offset;
		end
		% 		 trigoptions = {'sync','auto','manual'};
		obj.triggerMode = obj.default.triggerMode;
		obj.queryTriggerConfigFcn()
		if isempty(obj.resolutionOptions)
		  obj.resolutionOptions = [...
			 512 512;...
			 1024 1024;...
			 2048 2048];
		end
		if isempty(obj.frameRate)
		  if isempty(obj.default.frameRate)
			 queryFrameRateFcn(obj);
		  else
			 obj.frameRate = obj.default.frameRate;
		  end
		end
		if isempty(obj.deviceID)
		  obj.deviceID = 1;
		end
		if isempty(obj.videoDataType)
		  obj.videoDataType = 'uint16';
		end
	 end
  end
  methods % Implemented User-Functions
	 function setup(obj) % formerly setupVideoInput(obj)
		checkProperties(obj)
		obj.camAdapter = 'hamamatsu';
		if ~isempty(obj.videoInputObj) && isvalid(obj.videoInputObj)
		  delete(obj.videoInputObj)
		end
		setup@MatlabCompatibleCamera(obj);
		
	 end
	 function reset(obj)
		%       camReset(obj.hardwareSettingsInterface,'hard');
		obj.resolution = obj.default.resolution;
		obj.frameRate = obj.default.frameRate;
		obj.gain = obj.default.gain;
		obj.offset = obj.default.offset;
		reset@MatlabCompatibleCamera(obj);
	 end
  end
  methods (Access = protected) % UI-Query	 
	 % TODO: move to MatlabCompatibleCamera? would have to change properties from ABSTRACT and modify
	 % WebCamera class....
	 function queryResolutionFcn(obj)
		prompt = 'Select On-Chip Binning/Resolution';
		resOptions = cell(1,4);
		for n = 1:size(obj.resolutionOptions,1)
		  resOptions{n} = [num2str(obj.resolutionOptions(n,1)),'x',...
			 num2str(obj.resolutionOptions(n,2))];
		end
		selection = menu(prompt,resOptions);
		if selection
		  obj.resolution = obj.resolutionOptions(selection,1);
		else
		  % Default to 256x256 if user hits cancel
		  obj.resolution = obj.resolutionOptions(2,1);
		end
	 end
	 function queryFrameRateFcn(obj)
		prompt = 'Set Camera Frame-Rate';
		selection = inputdlg(prompt,'Frame Rate',1,{'30'});
		if ~isempty(selection)
		  obj.frameRate = str2double(selection{1});
		else % Default to 20 fps if user selects cancel
		  obj.frameRate = 20;
		end
	 end	 	 
  end
  methods % Hardware Setting Methods	 	
	 function set.resolution(obj,resolution)
		if ~isnumeric(resolution)
		  resolution = eval(resolution);
		end
		if length(resolution)>1
		  resolution = resolution(1);
		end
		if isempty(find(resolution==obj.resolutionOptions, 1)) && ~isempty(obj.resolutionOptions)
		  if resolution>max(obj.resolutionOptions(:,1))
			 resolution = max(obj.resolutionOptions(:,1));
		  end
		  if resolution<min(obj.resolutionOptions(:,1))
			 resolution = min(obj.resolutionOptions(:,1));
		  end
		  resolution = 2^round(log2(resolution));
		  warndlg(['Resolution must be 512, 1024, or 2048: ',...
			 'Setting to ',num2str(resolution)],...
			 'Binning Error');
		end
		obj.resolution = resolution;
		fprintf('++>>>>>>> TODO: SET RESOLUTION\n')
	 end
  end
  
  
  
  
  
  
end




























