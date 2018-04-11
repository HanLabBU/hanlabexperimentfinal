classdef Camera < hgsetget
  % -----------------------------------------------------------------------
  % Camera
  % FrameSynx Toolbox
  % 1/8/2010
  % Mark Bucklin
  % -----------------------------------------------------------------------
  %
  % The Camera class is an abstract class, meant to define a uniform set of
  % methods (start, stop, etc.) and properties (frameRate, resolution,
  % etc.) for various subclasses which can define specific cameras. This
  % enables scripts, functions, or other classes (e.g. the CameraSystem
  % class) to interact with multiple types of cameras in a predictable way.
  %
  %
  %
  %
  % Camera Properties:
  %   name - Name of specific camera
  %   frameRate - Frame rate
  %   resolution - resolution of image
  %   gain - image gain
  %   offset - offset of pixel data
  %   previewFigure - figure handle
  %   previewAxes - matlab axes object handle
  %   previewImageObj - matlab image object handle
  %   imageDataDirectory - directory to store image data
  %   savedData - memmapfile objects (rarely used)
  %   resolutionOptions - resolution restrictions defined by subclass
  %   videoFileObj - object of the VideoFile class used to save data
  %   videoDataType - data-type, e.g. 'uint16'
  %   gui - graphical interface to object properties
  %
  % Camera Methods:
  %   saveData - dumps all frames in buffer to a '.buk' file
  %   mapVidFile - recovers data dumped to a .buk file
  %   mapVidFileStatic - recovers data without an instance of the class
  %
  %
  %
  % See also CAMERACONTROL, MATLABCOMPATIBLECAMERA, DALSACAMERA, WEBCAMERA,
  % FRAMESYNX, DATAACQUISITION
  %
  
  
  
    
  
  properties (SetObservable, GetObservable, Abstract)
    name %set by subclass
    frameRate %frame rate of acquisition (set in hardare or software)
    resolution %resolution of images acquired
    gain
    offset
  end
  properties
    previewFigure
    previewAxes
    previewImageObj
    imageDataDirectory
    savedData
  end
  properties (SetAccess = protected)
    resolutionOptions
    videoFileObj
    videoDataType
  end
  properties (Access = private)
    default
  end
  properties (Transient)
    gui
  end
  
  
  
  
  
  
  events
    CameraLogging
    CameraStopped
    CameraReady
    CameraError
    FrameAcquired
    PreviewFrameAcquired
    DataLogged
    DataDumped
  end
  
  
  
  
  
  
  
  methods (Abstract)
    setup(obj)
    reset(obj)
    start(obj)
    stop(obj)
    trigger(obj)
    flushdata(obj)
    output = islogging(obj)
    output = isrunning(obj)
    output = getAllData(obj);
    output = getSomeData(obj,nFrames);
    output = getNextFrame(obj);
  end
  methods
    function varargout = saveData(obj,varargin)
      % -----------------------------------------------------------------------
      % USAGE:
      % mapobj = saveData(obj,bukfilepath)
      %
      % EXAMPLE:
      % >> mapobject = saveData(obj,'Z:\dumpedfiles\dumpfile00123.buk')
      %
      % This function is not used in the FrameSynx toolbox, but can be
      % used to dump data in an experimental situation. If outputs are
      % specified, this method will return the filename of the dumped
      % data.
      % -----------------------------------------------------------------------
      try
        % Check inputs
        vid = getAllData(obj);
        n = length(obj.savedData)+1;
        if isa(vid,'struct') %standard returned format
          vidtimes = vid.time;
          vidmeta = vid.meta;
          vid = vid.vid;
        end
        if nargin > 1 %filename is specified by caller
          fname = varargin{1};
        else %filename is VideoDump_date-time.buk
          if isempty(obj.imageDataDirectory) ...
              || ~isdir(obj.imageDataDirectory)
            obj.imageDataDirectory = pwd;
          end
          fname = fullfile(obj.imageDataDirectory,...
            ['VideoDump_',...
            datestr(now,'mmmdd_HHMMSS_'),...
            obj.videoDataType,'.buk']);
        end
        obj.savedData(n).time = clock;
        if isempty(obj.videoDataType)
          obj.videoDataType = 'uint16';
        end
        vidSize = size(vid);
        vidDimensions = size(vidSize,2);
        fid = fopen(fname,'wb');
        fwrite(fid,[vidDimensions,vidSize],'uint16');
        fwrite(fid,vid(:),obj.videoDataType);
        fclose(fid);
        
        obj.savedData(n).filename = fname;
        obj.savedData(n).presentDirectory = pwd;
        if ~isempty(vidtimes) && ~isempty(vidmeta)
          obj.savedData(n).time = vidtimes;
          obj.savedData(n).meta = vidmeta;
        end
        
        % Return Filename
        if nargout > 0
          varargout{1} = fname; % filename can then be used with mapVidFile()
        end
        % Return memmapped file if requested
        if nargout > 1
          varargout{2} = memmapfile(fname,...
            'Format',{...
            'uint16'    [1 1]           'vidDimensions';...
            'uint16'    [1 vidDimensions]   'vidSize';...
            obj.videoDataType   vidSize   'video'});
        end
        
        % Notify of the Data Dumping
        notify(obj,'DataDumped',...
          dataDumpMsg(obj.savedData(n)));
      catch me
        disp(me.message)
        disp(me.stack(1))
      end
    end
    function mapobj = mapVidFile(obj,bukfilepath)
      % -----------------------------------------------------------------------
      % USAGE:
      % mapobj = mapVidFile(obj,bukfilepath)
      %
      % EXAMPLE:
      % >> mapobject = mapVidFile(obj,'Z:\dumpedfiles\dumpfile00123.buk')
      %
      % This method is used to create a memmapfile object from
      % previously used '.buk' files. This would be useful in the case
      % of a data-dump, which could occur in an experimental situation
      % where the camera dumps all the data in the buffer rather than
      % crashing matlab. Use this method to recover that dumped data.
      % -----------------------------------------------------------------------
      fid = fopen(bukfilepath,'r');
      vidDimensions = fread(fid,1,'uint16');
      vidSize = fread(fid,vidDimensions,'uint16')';
      fclose(fid);
      mapobj  = memmapfile(bukfilepath,...
        'Format',{...
        'uint16'    [1 1]           'vidDimensions';...
        'uint16'    [1 vidDimensions]   'vidSize';...
        obj.videoDataType   vidSize   'video'});
    end
  end
  methods (Static)
    function mapobject = mapVidFileStatic(bukfilepath,vidformat)
      % -----------------------------------------------------------------------
      % USAGE:
      % mapobject = mapVidFileStatic(bukfilepath,vidformat)
      %
      % EXAMPLE:
      % >> mapobject = mapVidFileStatic('Z:\dumpedfiles\dumpfile00123.buk','uint16')
      %
      % A static version of the mapVidFile method. This can be used
      % without creating an object derived from the Camera class with
      % syntax like:
      % mapobj = Camera.mapVidFileStatic('./dumpfile00123.buk','uint16')
      % -----------------------------------------------------------------------
      fid = fopen(bukfilepath,'r');
      vidDimensions = fread(fid,1,'uint16');
      vidSize = fread(fid,vidDimensions,'uint16')';
      fclose(fid);
      mapobject = memmapfile(bukfilepath,...
        'Format',{...
        'uint16'    [1 1]           'vidDimensions';...
        'uint16'    [1 vidDimensions]   'vidSize';...
        vidformat   vidSize   'video'});
	 end
	 function devices = allDevices()
		devices = imaq.internal.Utility.getDeviceList';
	 end%move to matlabcompatiblecamera
	 function adaptors = allAdaptors()
		info = imaqhwinfo;
		adaptors = info.InstalledAdaptors';
		% 		devList = imaq.internal.Utility.getAllAdaptors'
	 end%move to matlabcompatiblecamera
	 function constructors = allConstructors()
      % -----------------------------------------------------------------------
      % This method is not implemented often, it is used by the
      % SystemSynchronizer class to keep a tab of how many DalsaCamera
      % and WebCamera objects could be made.
      % -----------------------------------------------------------------------
      constructors = cell.empty;
      info = imaqhwinfo;
      for n = 1:numel(info)
        adapterinfo = imaqhwinfo(info.InstalledAdaptors{n});
        nDevices = numel(adapterinfo.DeviceIDs);
        for m = 1:nDevices
          switch info.InstalledAdaptors{n}
            case 'coreco'
              constructors{numel(constructors)+1} = 'DalsaCamera';
            case 'winvideo'
              constructors{numel(constructors)+1} = 'WebCamera';
			 case 'hamamatsu'
				constructors{numel(constructors)+1} = 'DcamCamera';
          end
        end
      end
	 end
	 function formats = allFormats()%move to matlabcompatiblecamera
		formats = imaq.internal.Utility.getAllFormats';
	 end
  end
  
  
  
  
end

% TODO:
% Methods for class imaq.internal.Utility:
% 
% Utility                   
% 
% Static methods:
% 
% convertCellToStr          getDeviceList             
% getAdaptor                getDeviceListInSLFormat   
% getAdaptorsWithDevices    getMetaDataInfo           
% getAllAdaptors            getObjectConstructor      
% getAllBayerTypes          getObjectConstructorList  
% getAllDataTypes           isKinectDepthDevice       
% getAllDevIDs              supportPackageInstaller   
% getAllFormats             validateAdaptor           
% getDefaultFormat          validateFormat            
% getDevice                 
% getDeviceID             


