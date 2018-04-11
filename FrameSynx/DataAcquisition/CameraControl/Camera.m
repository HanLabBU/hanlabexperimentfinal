classdef Camera < hgsetget
  % ------------------------------------------------------------------------------
  % Camera
  % FrameSynx toolbox
  % 1/8/2009
  % Mark Bucklin
  % ------------------------------------------------------------------------------
  %
  %
  % This class derives from the abstract class, CAMERA.
  % Camera is essentially an abstract class, because it has
  % abstract properties and has no constructor. This class was born out of
  % the original CAMERA class. This was done to provide methods for
  % use with any camera compatible with matlab's Image Acquisition Toolbox
  % (and the videoinput object), but leave the 'shell' CAMERA class which
  % still defined the most basic elements of any camera. This leaves the
  % ability to represent other cameras for which the acquisition and
  % control might be handled outside of matlab (this was done for the Andor
  % EMCCD camera).
  %
  % Most methods for controlling and acquiring data from both the
  % DALSACAMERA and the WEBCAMERA classes are in this class definition.
  %
  % Camera Properties:
  %   camAdaptor - string for input into videoinput()
  %   deviceID - number for multiple cameras on same adaptor
  %   videoFormat - string specific to each camera
  %   frameSyncMode - option for synchronization with other cameras
  %   videoInputObj - returned by videoinput()
  %
  %   camMonitorObj - unused
  %   previewFigure - figure handle
  %   previewAxes - axes object handle
  %   previewImageObj - image object handle
  %   imageDataDirectory - used for data-dumps in error scenarios
  %   videoDataType - datatype of data (a string)
  %
  % Camera Methods:
  %   setup -  prepares object
  %   reset -  cleans object
  %   start -  makes object 'ready' for acquisition
  %   stop -  stops acquisition
  %   trigger -  triggers image acquisition
  %   flushdata -  flushes data buffer in memory
  %   islogging -  returns true if camera is acquiring data
  %   isrunning -  returns true if camera is ready to acquire data
  %   getAllData -  returns all acquired frames
  %   getSomeData -  returns specified number of frames
  %   getNextFrame -  returns one frame
  %   flushdata - empties buffer
  %   getSyncFrame - gets from preview, may return repeats
  %   preview - restarts preview
  %   stoppreview - stops preview
  %
  % Camera Events:
  %   PreviewFrameAcquired - passes previewFrameMsg class (subclass of event.EventData) with
  % structure evnt.previewEvent, which has the following fields:
  %
  %     Data: [256x256 uint8]
  %     Resolution: ''
  %     Status: 'Waiting for START.'
  %     Timestamp: '21:03:30.392'
  %
  %	Potentially Useful System Blocks from Computer-Vision toolbox:
  %	vision.ImageDataTypeConverter
  %	vision.ConnectedComponentLabeler 
  %	vision.MorphologicalTopHat 
  %	vision.Autothresholder  
  %
  %
  % See also CAMERA, DALSACAMERA, WEBCAMERA, VIDEOINPUT
 
  
  
  
  
  properties (SetObservable,AbortSet)
	 name
	 frameRate
	 exposureTime
	 resolution
	 gain
	 offset
  end
  properties (SetObservable, AbortSet)
	 camAdaptor
	 deviceID
	 videoFormat
	 frameSyncMode % 'auto' or 'manual' or 'hardware'
	 triggerMode
	 triggerConfiguration
	 triggerOptions
	 triggerOptionList
  end
  properties (Hidden)
	 metaClassObj
	 propChangeListeners
	 triggerTime
	 framesAcquired
	 lastPreviewUpdateTime
	 minPreviewUpdateInterval = .05;
	 autoRangeTimer
	 autoRangeTimerPeriod = .5;
	 histogramTimer
	 histogramTimerPeriod = .25;
	 histogramUpdater
	 histogramObj
	 histogramAxes
	 configureContainer
	 configureTriggerButton
  end
  properties
	 videoInputObj
	 videoSrcObj
  end
  properties 
	 default
  end
  properties (Transient)
	 previewFigure
	 previewAxes
	 previewImageObj
  end
  
  
  
  events
	 CameraReady
	 CameraLogging
	 CameraStopped
	 CameraError
	 PreviewFrameAcquired
	 FrameAcquired
  end
  
  
  
  
  methods % SETUP & CLEANUP
	 function obj = Camera(varargin)
		if nargin > 1
		  for k = 1:2:length(varargin)
			 obj.(varargin{k}) = varargin{k+1};
		  end
		end
	 end
	 function setup(obj)
		if isempty(obj.camAdaptor)
		  obj.queryCamAdaptor();
		end
		if isempty(obj.deviceID)
		  obj.queryDeviceId();
		end
		if isempty(obj.videoFormat)
		  obj.queryVideoFormat();
		end
		if isempty(obj.triggerConfiguration)
		  obj.queryTriggerConfiguration();
		end
		% VIDEOINPUT & VIDEOSOURCE
		try
		   obj.videoInputObj = videoinput(...
			  obj.camAdaptor,obj.deviceID,obj.videoFormat);
		catch		   
		   obj.videoInputObj = videoinput(...
			  obj.camAdaptor,obj.deviceID)
		   warning('Camera:Setup','Unable to set using specified format')
		end
		obj.videoSrcObj = getselectedsource(obj.videoInputObj);
		set(obj.videoInputObj,...
		  'framespertrigger',inf,...
		  'name',imaqhwinfo(obj.videoInputObj,'DeviceName'),...
		  'FramesAcquiredFcnCount',1,...
		  'FramesAcquiredFcn',@(src,evnt)frameAcquiredFcn(obj,src,evnt));
		% TRIGGER CONFIGURATION
		if isempty(obj.triggerMode)
		  obj.triggerMode = 'manual';
		end
		if ~isempty(obj.triggerConfiguration)
		  triggerconfig(obj.videoInputObj,obj.triggerConfiguration);
		else
		  triggerconfig(obj.videoInputObj,'manual');
		end
		if isempty(obj.frameSyncMode)
		  obj.frameSyncMode = 'auto';
		end
		%TODO: wher to put this?
		obj.createPropertyListeners()
		obj.preview();
		obj.setupDefaultPreview();
		notify(obj,'CameraReady');
	 end
	 function reset(obj)
		notify(obj,'CameraStopped');
		if ~isempty(obj.videoInputObj) && isobject(obj.videoInputObj)
		  if isrunning(obj.videoInputObj)
			 stop(obj.videoInputObj)
		  end
		  if isvalid(obj.videoInputObj)
			 delete(obj.videoInputObj)
		  end
		end
		setup(obj)
	 end
	 function resetTrigConfig(obj,varargin)
		if ~obj.isvalid
		  setup(obj)
		end
		if nargin < 2
		  obj.queryTriggerConfiguration;
		else
		  obj.triggerConfiguration = varargin{1};
		end
		try
		  stop(obj)
		  triggerconfig(obj.videoInputObj, obj.triggerConfiguration)
		catch me
		  warning(me.message)
		  obj.queryTriggerConfiguration;
		end
		start(obj)
	 end 
	 function createPropertyListeners(obj)
		obj.metaClassObj = metaclass(obj);
		setObservableProps = findobj(obj.metaClassObj.PropertyList,'SetObservable',1);
		if ~isempty(obj.propChangeListeners)
		  delete(obj.propChangeListeners)
		end
		obj.propChangeListeners = event.listener.empty();
		for k=1:numel(setObservableProps)
		  propname = setObservableProps(k).Name;
		  obj.propChangeListeners(k) = addlistener(obj, propname, 'PostSet',...
			 @(src,evnt)propChangeFcn(obj,src,evnt));
		end
	 end
	 function delete(obj)
		if ~isempty(obj.histogramTimer)
		   stop(obj.histogramTimer)
		   delete(obj.histogramTimer)
		end
		if ~isempty(obj.autoRangeTimer)
		   stop(obj.autoRangeTimer)
		   delete(obj.autoRangeTimer)
		end
		if ~isempty(obj.videoInputObj)
		  if isrunning(obj.videoInputObj)
			 stop(obj)
		  end
		  delete(obj.videoInputObj);
		end
	 end
  end
  methods (Static) % QUERY MACHINE
	 function devices = allDevices()
		warning('off','imaq:dcam:nocamerasfound')
		devices = imaq.internal.Utility.getDeviceList';
	 end
	 function adaptors = allAdaptors()
		info = imaqhwinfo;
		adaptors = info.InstalledAdaptors';
		% 		devList = imaq.internal.Utility.getAllAdaptors'
	 end
	 function formats = allFormats()
		formats = imaq.internal.Utility.getAllFormats';
	 end
	 function adaptors = availableAdaptors()
		adaptors = imaq.internal.Utility.getAdaptorsWithDevices';
	 end
  end
  methods % QUERY USER
	 function varargout = queryCamAdaptor(obj)
		info = imaqhwinfo;
		if length(info.InstalledAdaptors) > 1
		  output = listdlg('PromptString','Select an Adaptor:',...
			 'SelectionMode','single',...
			 'ListString',info.InstalledAdaptors);
		  if output
			 obj.camAdaptor = info.InstalledAdaptors{output};
		  else
			 obj.camAdaptor = [];
		  end
		else
		  obj.camAdaptor = info.InstalledAdaptors{1};
		end
		if nargout
		  varargout{1} = obj.camAdaptor;
		end
	 end
	 function varargout = queryDeviceId(obj)
		adaptorinfo = imaqhwinfo(obj.camAdaptor);
		if length(adaptorinfo.DeviceIDs) > 1
		  output = listdlg('PromptString','Select a Device:',...
			 'SelectionMode','single',...
			 'ListString',adaptorinfo.DeviceIDs);
		  if output
			 obj.deviceID = adaptorinfo.DeviceIDs{output};
		  else
			 obj.deviceID = [];
		  end
		else
		  obj.deviceID = 1;
		end
		if nargout
		  varargout{1} = obj.deviceID;
		end
	 end
	 function varargout = queryVideoFormat(obj)
		adaptorinfo = imaqhwinfo(obj.camAdaptor);
		devinfo = adaptorinfo.DeviceInfo(obj.deviceID);
		if length(devinfo.SupportedFormats) > 1
		  output = listdlg('PromptString','Select a Format:',...
			 'SelectionMode','single',...
			 'ListString',devinfo.SupportedFormats,...
			 'ListSize',[400 300]);
		  if output
			 obj.videoFormat = devinfo.SupportedFormats{output};
		  else
			 obj.videoFormat = [];
		  end
		else
		  obj.videoFormat = devinfo.SupportedFormats{1};
		end
		if nargout
		  varargout{1} = obj.videoFormat;
		end
	 end
	 function varargout = queryTriggerConfiguration(obj)
		if ~isempty(obj.videoInputObj) && isvalid(obj.videoInputObj)
		   obj.triggerOptions = triggerinfo(obj.videoInputObj);
		   trigfields = fields(obj.triggerOptions);
		   for k = 1:numel(obj.triggerOptions)
			  trigsetting = '';
			  for f = 1:numel(trigfields)
				 trigfieldname = trigfields{f};
				 trigsetting = sprintf('%s%s:%s|',trigsetting, trigfieldname,obj.triggerOptions(k).(trigfieldname));
			  end
			  obj.triggerOptionList{k,1} = trigsetting;
		   end
		   [output, ok] = listdlg('PromptString','Select a Trigger Configuration:',...
			  'SelectionMode','single',...
			  'ListString',obj.triggerOptionList,...
			  'ListSize',[700 300],...
			  'Name','Camera TriggerConfig',...
			  'InitialValue',4);
		   if ok
			  obj.triggerConfiguration = obj.triggerOptions(output);			  
		   end
		end
		% Set triggerMode to auto for software trigger
		if nargout
		  varargout{1} = obj.triggerConfiguration;
		end
	 end
  end
  methods % CONTROL
	 function start(obj)
		if isempty(obj.videoInputObj) || ~isobject(obj.videoInputObj)
		  setup(obj)
		end
		% 		if ~isempty(obj.triggerConfiguration) && ~isrunning(obj.videoInputObj)
		% 		   triggerconfig(obj.videoInputObj, obj.triggerConfiguration)
		% 		end
		if ~isrunning(obj.videoInputObj)
		  start(obj.videoInputObj)
		end
		if strcmpi('manual',obj.triggerMode)		  		  
		  preview(obj)
		  obj.setupDefaultPreview();
		end
		if strcmpi('hardware', obj.triggerMode)
		   start(obj.videoInputObj)
		end
		notify(obj,'CameraReady');
	 end
	 function stop(obj)
		switch lower(obj.frameSyncMode)
		  case {'auto','manual'}
			 if ~isempty(obj.videoInputObj) && isobject(obj.videoInputObj)
				stop(obj.videoInputObj)
			 end
		  case 'hardware'
			 if islogging(obj.videoInputObj)
				stop(obj.videoInputObj);
			 end
		end
		notify(obj,'CameraStopped');
	 end
	 function trigger(obj)
		%TODO: support multiple objects with single call
		if isempty(obj.videoInputObj) || ~isobject(obj.videoInputObj)
		  setup(obj)
		  start(obj)
		end
		nframesinbuffer = get(obj.videoInputObj,'FramesAvailable');
		if nframesinbuffer
		  warning('Camera:trigger:FlushingFrames',...
			 'Frames remaining in buffer will be flushed: %i frames\n',nframesinbuffer);
		  flushdata(obj.videoInputObj)
		end
		if ~isrunning(obj.videoInputObj)
		  start(obj.videoInputObj)
		  notify(obj,'CameraReady');
		end
		switch lower(obj.triggerMode)%changed from obj.frameSyncMode
		  case {'auto','manual'}
			 trigger(obj.videoInputObj);
		  case 'hardware'
			 obj.framesAcquired = 0;
			 obj.triggerTime = now;
		  otherwise
			 try
				trigger(obj.videoInputObj);
			 catch me
				warning('FrameSynx:Camera:trigger',me.message)
			 end
		end
		notify(obj,'CameraLogging');
	 end
	 function flushdata(obj)
		if ~isempty(obj.videoInputObj) && isobject(obj.videoInputObj)
		  wasrunning = obj.isrunning();
		  stop(obj.videoInputObj)
		  flushdata(obj.videoInputObj)
		  if wasrunning
			 start(obj.videoInputObj)
		  else
			 notify(obj,'CameraStopped');
		  end
		end
	 end
	 function output = islogging(obj)
		try
		  if isempty(obj.videoInputObj) || ~isobject(obj.videoInputObj)
			 output = false;
		  else
			 if isrunning(obj.videoInputObj)
				output = islogging(obj.videoInputObj);
			 else
				output = false;
			 end
		  end
		catch me
		  output = false;
		end
	 end
	 function output = isrunning(obj)
		if isempty(obj.videoInputObj) || ~isobject(obj.videoInputObj)
		  output = false;
		else
		  output = islogging(obj.videoInputObj);
		  if output
		  elseif isrunning(obj.videoInputObj)
			 output = true;
		  end
		end
	 end
	 function imData = getAllData(obj)
		nFrames = obj.videoInputObj.FramesAvailable;
		[imData.vid,imData.time,imData.meta] = ...
		  getdata(obj.videoInputObj,nFrames);
	 end
	 function imData = getSomeData(obj,nFrames)
		framesavail = obj.videoInputObj.FramesAvailable;
		if nFrames > framesavail
		  warning('Camera:Camera:notenoughframesavailable',...
			 'Only %d of %d frames available',framesavail,nFrames)
		  nFrames = framesavail;
		end
		[imData.vid,imData.time,imData.meta] = ...
		  getdata(obj.videoInputObj,nFrames);
	 end
	 function imFrame = getNextFrame(obj)
		[imFrame.vid, imFrame.time, imFrame.meta] = ...
		  getdata(obj.videoInputObj, 1);		
	 end
	 function imData = getSyncFrame(obj)
		abstime = now;
		framenum = obj.framesAcquired + 1;
		try
		  imData.time = (abstime - obj.triggerTime)*60*60*24;
		catch
		  imData.time = abstime*60*60*24;
		end
		imData.vid = getsnapshot(obj.videoInputObj,1);
		imData.meta.AbsTime = datevec(abstime);
		imData.meta.FrameNumber = framenum;
		imData.meta.RelativeFrame = framenum;
		obj.framesAcquired = framenum;
	 end
	 function dumpData(obj)
		if obj.videoInputObj.FramesAvailable > 0
		  data = getAllData(obj);
		  dumpDir = datapath();
		  if isempty(dumpDir)
			 dumpDir = pwd;
		  end
		  if ~isdir(dumpDir)
			 [succ, ~, ~] = mkdir(dumpDir);
			 if ~succ
				dumpDir = userpath;
			 end
		  end
		  dumpFullPath = fullfile(dumpDir, sprintf('datadump_%s.mat',datestr(now,'yyyy_mm_dd_HHMMSS')));
		  save(dumpFullPath,'data');
		  fprintf('\t------DATA-DUMP------\nDumped data to: %s\n\t------DATA-DUMP------\n',dumpFullPath)
		end
	 end
  end
  methods % PROPERTY CHANGE RESPONSE
	 function propChangeFcn(obj,src,evnt)		
		prop = src.Name;
		info = imaqhwinfo(obj.videoInputObj);
		wasrunning = obj.isrunning();
		waslogging = obj.islogging();
		stop(obj.videoInputObj)
		switch prop
		  % setObservableProps = findobj(obj.metaClassObj.PropertyList,'SetObservable',1);
		  % fprintf('case ''%s''\n\n',setObservableProps.Name)
		  case 'name'
			 
		  case 'frameRate'			 
			 obj.videoSrcObj.ExposureTime = 1/obj.frameRate;
		  case 'exposureTime'
			 obj.videoSrcObj.ExposureTime = obj.exposureTime;
		  case 'resolution'
			 
		  case 'gain'
			 
		  case 'offset'
			 
		  case 'camAdaptor'
			 
		  case 'deviceID'
			 
		  case 'videoFormat'
			 
		  case 'frameSyncMode'
			 
		  case 'triggerMode'
			 
		  case 'triggerConfiguration'			 
			 switch obj.triggerConfiguration.TriggerType
				case 'immediate'
				  obj.triggerMode = 'auto';
				case 'manual'
				  obj.triggerMode = 'manual';
				case 'hardware'
				  obj.triggerMode = 'hardware';
				  obj.videoInputObj.TriggerRepeat = inf;
				otherwise
				  obj.triggerMode = 'manual';
			 end
			 triggerconfig(obj.videoInputObj, obj.triggerConfiguration)
		end
		if wasrunning
		  start(obj.videoInputObj)
		end
		%TODO: if waslogging
	 end
  end
  methods % PREVIEW
	 function stoppreview(obj)
		stoppreview(obj.videoInputObj)
		if ~isempty(obj.previewImageObj)
		  set(obj.previewImageObj,'CData',0.*get(obj.previewImageObj,'CData'))
		end
	 end
	 function preview(obj)
		if ~isempty(obj.previewImageObj) && ishandle(obj.previewImageObj)
		  preview(obj.videoInputObj,obj.previewImageObj)
		else
		  obj.previewImageObj = preview(obj.videoInputObj);
		end
		if isempty(obj.previewAxes) || ~ishandle(obj.previewAxes)
		  obj.previewAxes = ancestor(obj.previewImageObj, 'Axes');
		end
		if isempty(obj.previewFigure) || ~ishandle(obj.previewFigure)
		  obj.previewFigure = ancestor(obj.previewImageObj, 'Figure');
		end
		if ~strcmpi('on', obj.videoInputObj.Previewing)
		  preview(obj.videoInputObj);
		end		
	 end
	 % FIGURE HANDLE SETTINGS
	 function setupDefaultPreview(obj)
		obj.setPreviewFigureDefaults();
		obj.setPreviewAxesDefaults();
		obj.setPreviewImageDefaults();
		obj.setPreviewAutoRangeTimer();
		obj.setPreviewHistogramTimer();
		obj.setPreviewConfigureControls();		
	 end
	 function setPreviewFigureDefaults(obj)
		set(obj.previewFigure,...
		  'Renderer','opengl',...
		  'GraphicsSmoothing','off',...
		  'HandleVisibility','callback',...
		  'Interruptible','on',...
		  'MenuBar','none',...
		  'NextPlot','add',...
		  'ToolBar','none',...
		  'BusyAction','cancel',...
		  'Color',[.1 .1 .1],...
		  'IntegerHandle','off',...
		  'Clipping','off')
		set(obj.previewFigure.Children, 'BusyAction', 'cancel');
	 end
	 function setPreviewAxesDefaults(obj)
		% AXES HANDLE SETTINGS
		set(obj.previewAxes,...
		  'xlimmode','manual',...
		  'ylimmode','manual',...
		  'zlimmode','manual',...
		  'climmode','manual',...
		  'alimmode','manual',...
		  'GridColor',[0 0 0],...
		  'GridLineStyle','none',...
		  'MinorGridColor',[0 0 0],...
		  'TickLabelInterpreter','none',...
		  'XGrid','off',...
		  'YGrid','off',...
		  'Visible','off',...
		  'Clipping','off',...
		  'NextPlot','add',...
		  'Interruptible','on',...
		  'YDir','reverse',...
		  'Units','normalized',...
		  'DataAspectRatio',[512 512 1],...
		  'BusyAction','cancel');% added 4/19
		if isprop(obj.previewAxes, 'SortMethod')
		  obj.previewAxes.SortMethod = 'childorder';
		else
		  obj.previewAxes.DrawMode = 'fast';
		end
	 end
	 function setPreviewImageDefaults(obj)
		% IMAGE HANDLE SETTINGS
		set(obj.previewImageObj,...
		  'BusyAction','cancel',...
		  'Interruptible','on');
	 end
	 function setPreviewFrameAcquiredFcn(obj,fcn)
		if nargin < 2
		  fcn = @(vidobj,event,imhandle)previewFrameAcquiredFcn(obj,vidobj,event,imhandle);
		end
		stoppreview(obj.videoInputObj)
		if ~isempty(obj.previewImageObj)
		  setappdata(obj.previewImageObj,'UpdatePreviewWindowFcn', fcn);
		else
		  warning('Camera:setup:NoPreviewUpdateFcn',...
			 'The UpdatePreviewWindowFcn could not be set');
		end
		warning('off','imaq:peekdata:tooManyFramesRequested') %annoying once cam starts acquiring
	 end
	 function setPreviewAutoRangeTimer(obj)
		if ~isempty(obj.autoRangeTimer)
		  delete(obj.autoRangeTimer)
		end
		obj.autoRangeTimer = timer(...
		  'Name','autoRangeTimer',...
		  'ExecutionMode', 'fixedSpacing',...
		  'StartDelay', 0,...
		  'TimerFcn', @(src,evnt)autoRangePreviewLimFcn(obj,src,evnt),...
		  'TasksToExecute', inf,...
		  'Period',obj.autoRangeTimerPeriod,...
		  'BusyMode','drop');
		if ~isempty(obj.previewImageObj)
		  start(obj.autoRangeTimer)
		end
	 end
	 function setPreviewHistogramTimer(obj)
		if ~isempty(obj.histogramTimer)
		  delete(obj.histogramTimer)
		end
		obj.histogramTimer = timer(...
		  'Name','histogramTimer',...
		  'ExecutionMode', 'fixedSpacing',...
		  'StartDelay', 0,...
		  'TimerFcn', @(src,evnt)updatePreviewHistogramFcn(obj,src,evnt),...
		  'TasksToExecute', inf,...
		  'Period',obj.histogramTimerPeriod,...
		  'BusyMode','drop');
		if ~isempty(obj.previewImageObj)
		  start(obj.histogramTimer)
		end
	 end
	 function setPreviewConfigureControls(obj)
		% 		obj.configureContainer = uicontainer(...
		% 		   'units','pixels',...
		% 		   'parent',obj.previewFigure,...
		% 		   'position', [10 10 100 300],...
		% 		   'BackgroundColor', [0 0 .5 .2]);
		% 		% Trigger Configuration Button
		% 		obj.configureTriggerButton = uicontrol(...
		% 		   'Parent',obj.configureContainer,...
		% 		   'style', 'pushbutton',...
		% 		   'string', 'Trigger',...
		% 		   'callback', @(~,~)queryTrigConfig(obj)		   );
			 end
  end
  methods % FRAME ACQUIRED & TIMER CALLBACKS
	 function autoRangePreviewLimFcn(obj,src,evnt)
		% 		persistent lastframe
		% 		if isempty(lastframe)
		% 		  lastframe = 0;
		% 		end
		% 		thisframe = obj.videoInputObj.FramesAcquired;
		% 		if thisframe < (lastframe+1)
		% 		  return
		% 		end
		% 		lastframe = thisframe;
		% 		if strcmpi('on',obj.videoInputObj.Previewing) && ~islogging(obj.videoInputObj)
		% 		  % Proceed with Image Preview Update
		% 		  if ~isempty(obj.videoInputObj) ...
		% 				&& isrunning(obj.videoInputObj) ...
		% 				&& ~isempty(obj.previewAxes) ...
		% 				&& ishandle(obj.previewAxes)
		try
		   data = getsnapshot(obj.videoInputObj);
		   if ~isempty(data)
			  obj.previewAxes.CLim =  [min(data(:)) max(data(:))];
		   end
		   % 		  end
		end
	 end
	 function updatePreviewHistogramFcn(obj,src,evnt)
		% 	 if isempty(obj.histogramUpdater)
		% 		obj.histogramUpdater = vision.Histogram;
		% 		info = imaqhwinfo(obj.videoInputObj)
		% 		obj.histogramUpdater.LowerLimit = 0;
		% 		obj.histogramUpdater.UpperLimit = intmax(info.NativeDataType);
		% 		obj.histogramUpdater.OverflowAction = 'Saturate';
		% 	 end
		% 	 histData = obj.histogramUpdater.step(getsnapshot(obj.videoInputObj));
		  % 		persistent lastframe
		  % 		if isempty(lastframe)
		  % 		  lastframe = 0;
		  % 		end
		  % 		thisframe = obj.videoInputObj.FramesAcquired;
		  % 		if thisframe < (lastframe+1)
		  % 		  return
		  % 		end
		  % 		lastframe = thisframe;
		if strcmpi('on',obj.videoInputObj.Previewing) && ~islogging(obj.videoInputObj)
		  % Proceed with Histogram Update
		  if ~ishandle(obj.previewAxes)
			 stop(src)
			 return
		  end
		  if isempty(obj.histogramAxes) || ~ishandle(obj.histogramAxes)
			 obj.histogramObj = histogram(getsnapshot(obj.videoInputObj), 128);
			 hfig = gcf;
			 obj.histogramAxes = ancestor(obj.histogramObj ,'Axes');
			 obj.histogramAxes.Position = [.025 .04 .95 .15];
			 obj.histogramAxes.Color = 'none';
			 obj.histogramAxes.Visible = 'off';
			 obj.histogramAxes.Parent = obj.previewAxes.Parent;
			 obj.histogramAxes.Layer = 'top';
			 obj.histogramAxes.BusyAction = 'cancel';
			 obj.histogramAxes.HandleVisibility = 'callback';
			 obj.histogramObj.BusyAction = 'cancel';
			 obj.histogramObj.FaceAlpha = .25;
			 close(hfig);
		  else
			 obj.histogramObj.Data = getsnapshot(obj.videoInputObj);
			 drawnow update
		  end
		end
	 end
	 function frameAcquiredFcn(obj,vidObject,evnt)
		% 		if obj.videoInputObj.FramesAvailable > 0
		% 		  notify(obj,'FrameAcquired',...
		% 			 newFrameMsg(evnt.Data));
		% 		  %TODO: Find which thread this evaluates in... add timer instead?
		% 		  % 		  function imaqcallback(obj, event, varargin)
		% 		  % 		  %IMAQCALLBACK Display event information for the event.
		% 		  % 		  %
		% 		  % 		  %    IMAQCALLBACK(OBJ, EVENT) displays a message which contains the
		% 		  % 		  %    type of the event, the time of the event and the name of the
		% 		  % 		  %    object which caused the event to occur.
		% 		  % 		  %
		% 		  % 		  %    If an error event occurs, the error message is also displayed.
		% 		  % 		  %
		% 		  % 		  %    IMAQCALLBACK is an example callback function. Use this callback
		% 		  % 		  %    function as a template for writing your own callback function.
		% 		  % 		  %
		% 		  % 		  %    Example:
		% 		  % 		  %       obj = videoinput('winvideo', 1);
		% 		  % 		  %       set(obj, 'StartFcn', {'imaqcallback'});
		% 		  % 		  %       start(obj);
		% 		  % 		  %       wait(obj);
		% 		  % 		  %       delete(obj);
		% 		  % 		  %
		% 		  % 		  %    See also IMAQHELP.
		% 		  % 		  %
		% 		  %
		% 		  % 		  %    CP 10-01-02
		% 		  % 		  %    Copyright 2001-2010 The MathWorks, Inc.
		% 		  %
		% 		  % 		  % Define error identifiers.
		% 		  % 		  errID = 'imaq:imaqcallback:invalidSyntax';
		% 		  % 		  errID2 = 'imaq:imaqcallback:zeroInputs';
		% 		  %
		% 		  % 		  switch nargin
		% 		  % 			 case 0
		% 		  % 				error(message(errID2));
		% 		  % 			 case 1
		% 		  % 				error(message(errID));
		% 		  % 			 case 2
		% 		  % 				if ~isa(obj, 'imaqdevice') || ~isa(event, 'struct')
		% 		  % 				  error(message(errID));
		% 		  % 				end
		% 		  % 				if ~(isfield(event, 'Type') && isfield(event, 'Data'))
		% 		  % 				  error(message(errID));
		% 		  % 				end
		% 		  % 		  end
		% 		  %
		% 		  % 		  % Determine the type of event.
		% 		  % 		  EventType = event.Type;
		% 		  %
		% 		  % 		  % Determine the time of the error event.
		% 		  % 		  EventData = event.Data;
		% 		  % 		  EventDataTime = EventData.AbsTime;
		% 		  %
		% 		  % 		  % Create a display indicating the type of event, the time of the event and
		% 		  % 		  % the name of the object.
		% 		  % 		  name = get(obj, 'Name');
		% 		  % 		  fprintf('%s event occurred at %s for video input object: %s.\n', ...
		% 		  % 			 EventType, datestr(EventDataTime,13), name);
		% 		  %
		% 		  % 		  % Display the error string.
		% 		  % 		  if strcmpi(EventType, 'error')
		% 		  % 			 fprintf('%s\n', EventData.Message);
		% 		  % 		  end
		% 		end
	 end
	 function previewFrameAcquiredFcn(obj,src,evnt,hImage) % called on each preview frame
		persistent avgMinMax
		if ~isempty(obj.lastPreviewUpdateTime)
		  if (hat - obj.lastPreviewUpdateTime) > obj.minPreviewUpdateInterval
			 if isempty(avgMinMax)
				avgMinMax(1) = min(evnt.Data(:));
				avgMinMax(2) = max(evnt.Data(:));
			 else
				newMinMax = [min(evnt.Data(:)) max(evnt.Data(:))];
				avgMinMax(1) = ceil(avgMinMax(1)*.95 + newMinMax(1)*.05);
				avgMinMax(2) = ceil(avgMinMax(2)*.95 + newMinMax(2)*.05);
				% 			 fprintf('\b\b\b%3g',avgMinMax(2))
			 end
			 % 			scaleFactor = single(255/avgMinMax(2));
			 % 			data = uint8(single(evnt.Data) .* scaleFactor);
			 % 			set(obj.previewImageObj,'CData',data)
			 % 		  set(obj.previewAxes,'CLim',avgMinMax(:)')
			 obj.previewImageObj.CData = evnt.Data;
			 obj.previewAxes.CLim = avgMinMax(:)';
			 % 		  notify(obj,'PreviewFrameAcquired',previewFrameMsg(evnt,hImage))
		  end
		end
		obj.lastPreviewUpdateTime = hat;
	 end
  end
end


% Format of data returned from getSomeData() :
% viddata =
%      vid: [4-D uint16]    size=([ 256   256     1   162])
%     time: [162x1 double]
%     meta: [162x1 struct]

