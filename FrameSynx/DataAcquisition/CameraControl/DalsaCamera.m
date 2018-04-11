classdef DalsaCamera < MatlabCompatibleCamera
  % ------------------------------------------------------------------------------
  % DalsaCamera
  % FrameSynx toolbox
  % 1/8/2009
  % Mark Bucklin
  % ------------------------------------------------------------------------------
  %
  % This class derives from the abstract class, CAMERA, to provide an
  % interface with the Dalstar 1M30P CCD Camera, made by Dalsa.
  %
  % SYNTAX:
  % >> cameraObject = DalsaCamera;
  % or
  % >> cameraObject = DalsaCamera('propertyname1',value1,...)
  %
  % where propertyname can be any one of the following properties.
  %
  % DalsaCamera Properties:
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
  %     hardwareSettingsInterface - object of class 'DalsaCamSerialConnection'
  %     previewFigure - Handle to the preview figure
  %     previewImageObj - Handle to preview image object
  %
  % Camera properties can be set on instantiation or using either set format, i.e.
  % set(cameraObject,'propertyname') or cameraObject.propertyname = value.
  %
  % DalsaCamera Methods:
  %   setup - creates videoinput object for 'coreco' framegrabber
  %   reset - reset videoinput object and serial connection
  %   softReset - resets camera via serial connection
  %   hardReset - resets camera via serial connection (power off-on)
  %
  % IMPORTANT:
  % Be sure to delete the DalsaCamera object at the end of a recording session
  % with the following syntax:
  %
  % >> delete(dalsaCameraObject)
  %
  %
  % See also MATLABCOMPATIBLECAMERA, CAMERA, DALSACAMSERIALCONNECTION,
  % WEBCAMERA, DALSACAMERADEFAULT, DALSACAMERAGUI, CAMERASYSTEM,
  % CAMERACONTROL
  
  
  
  properties (SetObservable,GetObservable)
    name
    frameRate
    resolution
    gain
    offset
    triggerMode
  end
  properties (SetObservable, GetObservable)
    serialPort
    configFileDirectory
  end
  properties (Dependent)
    configurationFile
  end
  properties (Access = private)
    default
  end
  
  
  
  
  
  
  methods % Constructor & Destructor
    function obj = DalsaCamera(varargin)
      if nargin > 1
        for k = 1:2:length(varargin)
          obj.(varargin{k}) = varargin{k+1};
        end
      end
      obj.default = DalsaCameraDefault; %subclass of DefaultFile class
    end
    function delete(obj)
      try
        if ~isempty(obj.videoInputObj)
          if isrunning(obj.videoInputObj)
            stop(obj)
          end
          delete(obj.videoInputObj);
        end
        delete(obj.hardwareSettingsInterface)
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
      if isempty(obj.triggerMode)
        obj.triggerMode = obj.default.triggerMode;
      end
      if isempty(obj.resolutionOptions)
        obj.resolutionOptions = [...
          128 128;...
          256 256;...
          512 512;...
          1024 1024];
      end
      if isempty(obj.serialPort)
        setComFcn(obj);
      end
      if isempty(obj.configFileDirectory)
        if isdir(obj.default.configFileDirectory)
          obj.configFileDirectory = obj.default.configFileDirectory;
        else
          queryConfigurationFilesFcn(obj);
        end
      end
      if char(obj.configFileDirectory(end)) ~= char('\')
        obj.configFileDirectory = [obj.configFileDirectory,'\'];
      end
      if isempty(obj.resolution)
        if isempty(obj.default.resolution)
          queryResolutionFcn(obj);
        else
          obj.resolution = obj.default.resolution;
        end
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
      warning off imaq:coreco:invalidvalue
      warning off imaq:coreco:framemissed
      obj.videoFormat = fullfile(obj.configFileDirectory, obj.configurationFile);
      obj.camAdapter = 'coreco';
      if isempty(obj.hardwareSettingsInterface)
        obj.hardwareSettingsInterface = DalsaCamSerialConnection(obj);
      end
      if ~isempty(obj.videoInputObj) && isvalid(obj.videoInputObj)
        delete(obj.videoInputObj)
      end
      setup@MatlabCompatibleCamera(obj);
      %BUILD GUI<<<<<<<<<<<<<<<<<<<<<<
      try
        if isempty(obj.gui)
          obj.gui = DalsaCameraGUI('cameraObj',obj);
        end
      catch me
        fprintf('Failure to create DalsaCameraGUI')
        me.message
        me.stack(1)
      end
    end
    function reset(obj)
      camReset(obj.hardwareSettingsInterface,'hard');
      obj.resolution = obj.default.resolution;
      obj.frameRate = obj.default.frameRate;
      obj.gain = obj.default.gain;
      obj.offset = obj.default.offset;
      reset@MatlabCompatibleCamera(obj);
    end
  end
  methods (Access = protected) % UI-Query Serial Port Configuration
    function setComFcn(obj)
      comOptions = instrhwinfo('serial');
      if length(comOptions.SerialPorts) > 1
        if any(strcmp(comOptions.AvailableSerialPorts,obj.default.serialPort))
          obj.serialPort = obj.default.serialPort;
        else
          prompt = 'Select Camera COM Port';
          selection = menu(prompt,comOptions.SerialPorts);
          if selection
            obj.serialPort = comOptions.SerialPorts{selection};
          else
            obj.serialPort = comOptions.SerialPorts{1};
          end
        end
      else
        obj.serialPort = comOptions.SerialPorts{1};
      end
    end
    function queryConfigurationFilesFcn(obj)
      obj.configFileDirectory = uigetdir(...
        userpath,'Choose the IFC Configuration Files Directory');
    end
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
      else % Default to 30 fps if user selects cancel
        obj.frameRate = 30;
      end
    end
  end
  methods % Hardware Setting Methods
    function filestring = get.configurationFile(obj)
      filestring = ['Dalstar 1M30p ',...
        num2str(obj.resolution),'.txt'];
    end
    function softReset(obj)
      camReset(obj.hardwareSettingsInterface,'soft')
      obj.resolution = obj.resolution;
      obj.frameRate = obj.frameRate;
      obj.gain = obj.gain;
      obj.offset = obj.offset;
    end
    function hardReset(obj)
      camReset(obj.hardwareSettingsInterface,'hard')
      obj.resolution = obj.resolution;
      obj.frameRate = obj.frameRate;
      obj.gain = obj.gain;
      obj.offset = obj.offset;
    end
    function set.gain(obj,gain)
      if gain<1
        warndlg('Gain will be set to 1','Gain Outside Bounds');
        gain = 1;
      end
      if gain>10
        warndlg('Gain will be set to 10','Gain Outside Bounds');
        gain = 10;
      end
      obj.gain = gain;
    end
    function set.offset(obj,offset)
      if offset<-4095
        warndlg('Offset will be set to -4095','Offset Outside Bounds');
        offset = -4095;
      end
      if offset>4095
        warndlg('Offset will be set to 4095','Offset Outside Bounds');
        offset = 4095;
      end
      obj.offset = offset;
    end
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
        warndlg(['Resolution must be 128, 256, 512, or 1024: ',...
          'Setting to ',num2str(resolution)],...
          'Binning Error');
      end
      obj.resolution = resolution;
    end
  end
  
  
  
  
  
  
end











