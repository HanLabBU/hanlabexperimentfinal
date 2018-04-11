classdef WebCamera < MatlabCompatibleCamera
  % ------------------------------------------------------------------------------
  % WebCamera
  % FrameSynx toolbox
  % 1/8/2009
  % Mark Bucklin
  % ------------------------------------------------------------------------------
  %
  % This class derives from the abstract class, CAMERA, to provide an
  % interface with any camera that uses the 'winvideo' video adapter in
  % MATLAB's Image Acquisition toolbox. The cameras that can use the
  % winvideo adapter are generally those that are 'plugnplay' compatible or
  % have drivers that are 'Windows Driver Model' (WDM) compatible, which
  % includes most webcams, and could also include many other types of
  % cameras.
  %
  % SYNTAX:
  % >> cameraObject = WebCamera;
  % or
  % >> cameraObject = WebCamera('propertyname1',value1,...)
  %
  % where propertyname can be any one of the following properties.
  %
  % WebCamera Properties:
  %     triggerMode - Camera hardware setting, 'auto', 'manual', or 'sync'
  %     resolutionOptions - taken from imaqhwinfo
  %     name
  %     frameRate - Can be set as high as 30 or higher at low resolution
  %     resolution - Set to one of four optional resolution values
  %     camAdapter - 'winvideo'
  %     deviceID - Usually set to 1, can set for multiple Camera use
  %     videoInputObj
  %     previewFigure - Handle to the preview figure
  %     previewImageObj - Handle to preview image object
  %
  % Camera properties can be set on instantiation or using either set format, i.e.
  % set(cameraObject,'propertyname') or cameraObject.propertyname = value.
  %
  % WebCamera Methods:
  %   resetResolution - query resolution from user
  %
  % IMPORTANT:
  % Be sure to delete the WebCamera object at the end of a recording session
  % with the following syntax:
  %
  % >> delete(webCameraObject)
  %
  %
  % See also MATLABCOMPATIBLECAMERA, CAMERA, CAMERASYSTEM, DALSACAMERA
  % CAMERACONTROL
  
  
  
  
  
  
  
  
  properties (SetObservable,GetObservable)
    name
    frameRate
    resolution
    gain
    offset
  end
  properties (SetAccess = protected)
    defaultFormat
    framesPerTrigger
  end
  properties (Dependent , SetAccess = protected)
    frameGrabInterval
  end
  
  
  
  
  
  
  
  
  
  methods % Constructor/Destructor
    function obj = WebCamera(varargin)
      if nargin > 1
        for k = 1:2:length(varargin)
          obj.(varargin{k}) = varargin{k+1};
        end
      end
      % Setup Video Input
      obj.camAdapter = 'winvideo';
      % 						response = questdlg('Setup WebCamera Now?');
      % 						if strcmpi(response,'Yes')
      setup(obj)
      % 						end
    end
    function delete(obj)
      if isrunning(obj.videoInputObj)
        stop(obj.videoInputObj)
      end
      if isvalid(obj.videoInputObj)
        delete(obj.videoInputObj)
      end
    end
  end
  
  methods % User-Functions
    function setup(obj)
      if ~isempty(obj.videoInputObj) && isvalid(obj.videoInputObj)
        delete(obj.videoInputObj)
      end
      checkProperties(obj)
      setup@MatlabCompatibleCamera(obj);
      set(obj.videoInputObj,'FrameGrabInterval',obj.frameGrabInterval);
    end
    function reset(obj)
      checkProperties(obj)
      reset@MatlabCompatibleCamera(obj);
      if obj.isrunning()
        if ishandle(obj.previewImageObj)
          delete(obj.previewImageObj)
        end
        start(obj)
      end
    end
    function resetResolution(obj)
      obj.resolution = [];
      reset(obj)
    end
  end
  
  methods % Set/Get
    function set.framesPerTrigger(obj,numframes)
      if ~isempty(obj.videoInputObj) && isrunning(obj.videoInputObj)
        stop(obj.videoInputObj)
      end
      obj.framesPerTrigger = numframes;
      if ~isempty(obj.videoInputObj)
        set(obj.videoInputObj,'FramesPerTrigger',numframes)
        start(obj.videoInputObj);
      end
    end
    function set.frameRate(obj,framerate)
      shouldrestart = ~isempty(obj.videoInputObj) && isrunning(obj.videoInputObj);
      if framerate>30
        framerate = 30;
        warning('WebCamera:setframeRate:MaxFrameRateWarning','Frame rate set to 30 (maximum)')
      end
      grabInterval = round(30/framerate);
      obj.frameRate = 30/grabInterval;
      disp(['Frame Rate set to ',num2str(obj.frameRate)]);
      reset(obj)
      if shouldrestart
        start(obj)
      end
    end
    function interval = get.frameGrabInterval(obj)
      interval = round(30/obj.frameRate);
    end
  end
  
  methods (Access = protected)
    function checkProperties(obj)
      if isempty(obj.gain)
        obj.gain = 1;
      end
      if isempty(obj.offset)
        obj.offset = 0;
      end
      if isempty(obj.frameRate)
        obj.frameRate = 30;
      end
      if isempty(obj.framesPerTrigger)
        obj.framesPerTrigger = inf;
      end
      if isempty(obj.deviceID)
        obj.deviceID = 1;
      end
      if isempty(obj.name)
        caminfo = imaqhwinfo('winvideo');
        camname = caminfo.DeviceInfo(obj.deviceID).DeviceName;
        obj.name = camname;
      end
      if isempty(obj.defaultFormat)
        devinfo = imaqhwinfo('winvideo',obj.deviceID);
        obj.defaultFormat = devinfo.DefaultFormat;
      end
      if isempty(obj.resolutionOptions)
        devinfo = imaqhwinfo('winvideo',obj.deviceID);
        output = textscan(char(devinfo.SupportedFormats)',...
          '%s%n%n','delimiter','_x ','MultipleDelimsAsOne',1);
        rgbformats = find(char(output{1})=='R');
        if rgbformats
          hres = output{2}(rgbformats);
          vres = output{3}(rgbformats);
        else
          hres = output{2};
          vres = output{3};
        end
        obj.resolutionOptions = [hres,vres];
      end
      if isempty(obj.resolution) || isempty(obj.videoFormat)
        queryResolutionFcn(obj);
      end
      if isempty(obj.videoDataType)
        obj.videoDataType = 'uint8';
      end
    end
    function queryResolutionFcn(obj)
      devinfo = imaqhwinfo('winvideo',obj.deviceID);
      allformats = devinfo.SupportedFormats;
      rgbformats = find(char(allformats)=='R');
      try
        if rgbformats
          availableformats = allformats(rgbformats);
        else
          availableformats = allformats;
        end
        prompt = 'Select Resolution';
        defnum = find(strcmp(availableformats,obj.defaultFormat),1,'first');
        [selection,ok] = listdlg(...
          'PromptString',prompt,...
          'ListString',availableformats,...
          'SelectionMode','single',...
          'CancelString',obj.defaultFormat(min(7,numel(obj.defaultFormat)):end),...
          'InitialValue',defnum);
        if ok
          obj.resolution = obj.resolutionOptions(selection,:);
          obj.videoFormat = availableformats{selection};
        else
          obj.videoFormat = obj.defaultFormat;
          defaultformat =  textscan(char(obj.defaultFormat)',...
            '%s%n%n','delimiter','_x ','MultipleDelimsAsOne',1);
          obj.resolution = [defaultformat{2} defaultformat{3}];
        end
      catch
        obj.resolution = obj.resolutionOptions(1);
        obj.videoFormat = devinfo.DefaultFormat;
      end
    end
  end
  
  
  
  
end




