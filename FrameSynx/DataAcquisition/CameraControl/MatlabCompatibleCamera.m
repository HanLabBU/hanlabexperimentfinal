classdef MatlabCompatibleCamera < Camera
  % ------------------------------------------------------------------------------
  % MatlabCompatibleCamera
  % FrameSynx toolbox
  % 1/8/2009
  % Mark Bucklin
  % ------------------------------------------------------------------------------
  %
  %
  % This class derives from the abstract class, CAMERA.
  % MatlabCompatibleCamera is essentially an abstract class, because it has
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
  % MatlabCompatibleCamera Properties:
  %   camAdapter - string for input into videoinput()
  %   deviceID - number for multiple cameras on same adapter
  %   videoFormat - string specific to each camera
  %   frameSyncMode - option for synchronization with other cameras
  %   videoInputObj - returned by videoinput()
  %   hardwareSettingsInterface - used by DalsaCamera only
  %   camMonitorObj - unused
  %   previewFigure - figure handle
  %   previewAxes - axes object handle
  %   previewImageObj - image object handle
  %   imageDataDirectory - used for data-dumps in error scenarios
  %   videoDataType - datatype of data (a string)
  %
  % MatlabCompatibleCamera Methods:
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
  % MatlabCompatibleCamera Events:
  %   PreviewFrameAcquired - passes previewFrameMsg class (subclass of event.EventData) with
  % structure evnt.previewEvent, which has the following fields:
  %
  %     Data: [256x256 uint8]
  %     Resolution: ''
  %     Status: 'Waiting for START.'
  %     Timestamp: '21:03:30.392'
  %
  %
  %
  % See also CAMERA, DALSACAMERA, WEBCAMERA, VIDEOINPUT
  
  
  
  
  
  properties (SetObservable,GetObservable, Abstract)
	 name
	 frameRate
	 resolution
	 gain
	 offset
  end
  properties (SetObservable, GetObservable)
	 camAdapter % 'coreco' or 'winvideo'
	 deviceID %  1
	 videoFormat % IFC configFile or 'RGB24_640x480'
	 frameSyncMode % 'auto' or 'external'
	 triggerMode
	 triggerConfiguration
  end
  properties (Hidden)
	 isembedded
	 triggerTime
	 framesAcquired
  end
  properties (SetAccess = protected)
	 videoInputObj
	 hardwareSettingsInterface % (DalsaCamSerialConnection)
	 camMonitorObj
  end
  
  
  
  
  
  methods % User-Functions (obligatory)
	 function setup(obj)
		info = imaqhwinfo;
		if isempty(obj.camAdapter)
		  if length(info.InstalledAdaptors) > 1
			 output = listdlg('PromptString','Select an Adapter:',...
				'SelectionMode','single',...
				'ListString',info.InstalledAdaptors);
			 if output
				obj.camAdapter = info.InstalledAdaptors{output};
			 else
				obj.camAdapter = 'winvideo';
			 end
		  else
			 obj.camAdapter = info.InstalledAdaptors{1};
		  end
		end
		adapterinfo = imaqhwinfo(obj.camAdapter);
		if isempty(obj.deviceID)
		  obj.deviceID = 1;
		  if length(adapterinfo.DeviceIDs) > 1
			 output = listdlg('PromptString','Select an Device:',...
				'SelectionMode','single',...
				'ListString',adapterinfo.DeviceIDs);
			 if output
				obj.deviceID = adapterinfo.DeviceIDs{output};
			 else
				obj.deviceID = 1;
			 end
		  else
			 obj.deviceID = 1;
		  end
		end
		devinfo = adapterinfo.DeviceInfo(obj.deviceID);
		if isempty(obj.videoFormat)
		  if length(devinfo.SupportedFormats) == 1
			 obj.videoFormat = devinfo.SupportedFormats{1};
		  end
		  if length(devinfo.SupportedFormats)>1
			 output = listdlg('PromptString','Select a Format:',...
				'SelectionMode','single',...
				'ListString',devinfo.SupportedFormats,...
				'ListSize',[400 300]);
			 if output
				obj.videoFormat = devinfo.SupportedFormats{output};
			 else
				obj.videoFormat = devinfo.DefaultFormat;
			 end
		  end
		  % TRIGGER CONFIGURATION (moved from DcamCamera)
		  if isempty(obj.triggerConfiguration)
			 obj.queryTriggerConfigFcn();
		  end
		end
		obj.videoInputObj = videoinput(...
		  obj.camAdapter,obj.deviceID,obj.videoFormat);
		set(obj.videoInputObj,...
		  'framespertrigger',inf,...
		  'name',devinfo.DeviceName,...
		  'startfcn',@(src,event)previewAtStartFcn(obj,src,event),...
		  'FramesAcquiredFcnCount',1,...
		  'FramesAcquiredFcn',@(src,evnt)frameAcquiredFcn(obj,src,evnt));
		if isempty(obj.triggerMode)
		  obj.triggerMode = 'manual';
		end
		if ~isempty(obj.triggerConfiguration)
		  triggerconfig(obj.videoInputObj,obj.triggerConfiguration);
		else
		  triggerconfig(obj.videoInputObj,'manual');
		end
		if isempty(obj.frameSyncMode)
		  obj.frameSyncMode = 'auto'; % added 7/22
		end
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
	 function start(obj)
		if isempty(obj.videoInputObj) || ~isobject(obj.videoInputObj)
		  setup(obj)
		end
		if ~isrunning(obj.videoInputObj)
		  start(obj.videoInputObj)
		end
		notify(obj,'CameraReady');
	 end
	 function stop(obj)
		switch lower(obj.frameSyncMode)
		  case 'auto'
			 if ~isempty(obj.videoInputObj) && isobject(obj.videoInputObj)
				stop(obj.videoInputObj)
			 end
		  case 'external'
			 if islogging(obj.videoInputObj)
				stop(obj.videoInputObj);
			 end
		end
		notify(obj,'CameraStopped');
	 end
	 function trigger(obj)
		if isempty(obj.videoInputObj) || ~isobject(obj.videoInputObj)
		  setup(obj)
		  start(obj)
		end
		nframesinbuffer = get(obj.videoInputObj,'FramesAvailable');
		if nframesinbuffer
		  warning('MatlabCompatibleCamera:trigger:FlushingFrames',...
			 'Frames remaining in buffer will be flushed: %i frames\n',nframesinbuffer);
		  flushdata(obj.videoInputObj)
		end
		if ~isrunning(obj.videoInputObj)
		  start(obj.videoInputObj)
		  notify(obj,'CameraReady');
		end
		switch lower(obj.frameSyncMode)%changed from obj.frameSyncMode
		  case 'auto'
			 try
				if any(strcmpi(obj.triggerMode,{'manual','immediate','auto'}))
				  trigger(obj.videoInputObj);
				end
			 catch me
				warning('FrameSynx:MatlabCompatibleCamera:trigger',me.message)
			 end
		  case 'external'
			 obj.triggerTime = now;
			 obj.framesAcquired = 0;
		  otherwise
			 try
				trigger(obj.videoInputObj);
			 catch me
				warning('FrameSynx:MatlabCompatibleCamera:trigger',me.message)
			 end
		end
		notify(obj,'CameraLogging');
	 end
	 function flushdata(obj)
		if ~isempty(obj.videoInputObj) && isobject(obj.videoInputObj)
		  stop(obj.videoInputObj)
		  flushdata(obj.videoInputObj)
		end
		notify(obj,'CameraStopped');
	 end
	 function output = islogging(obj)
		try
		  if isempty(obj.videoInputObj) || ~isobject(obj.videoInputObj)
			 output = false;
			 notify(obj,'CameraStopped');
		  else
			 if isrunning(obj.videoInputObj)
				output = islogging(obj.videoInputObj);
			 else
				output = false;
			 end
			 % 								if output
			 % 										notify(obj,'CameraLogging');
			 % 								elseif isrunning(obj.videoInputObj)
			 % 										notify(obj,'CameraReady');
			 % 								end
			 
		  end
		catch me
		  output = false;
		end
	 end
	 function output = isrunning(obj)
		if isempty(obj.videoInputObj) || ~isobject(obj.videoInputObj)
		  output = false;
		  notify(obj,'CameraStopped');
		else
		  output = islogging(obj.videoInputObj);
		  if output
			 notify(obj,'CameraLogging');
		  elseif isrunning(obj.videoInputObj)
			 notify(obj,'CameraReady');
			 output = true;
		  end
		end
	 end
	 function imData = getAllData(obj)
		nFrames = obj.videoInputObj.FramesAvailable;
		[imData.vid,imData.time,imData.meta] = ...
		  getdata(obj.videoInputObj,nFrames);
		notify(obj,'DataLogged')
	 end
	 function imData = getSomeData(obj,nFrames)
		framesavail = obj.videoInputObj.FramesAvailable;
		if nFrames > framesavail
		  warning('Camera:MatlabCompatibleCamera:notenoughframesavailable',...
			 'Only %d of %d frames available',framesavail,nFrames)
		  nFrames = framesavail;
		end
		[imData.vid,imData.time,imData.meta] = ...
		  getdata(obj.videoInputObj,nFrames);
		notify(obj,'DataLogged') %commented out on 5/6/2010
	 end
	 function imFrame = getNextFrame(obj)
		[imFrame.vid, imFrame.time, imFrame.meta] = ...
		  getdata(obj.videoInputObj, 1);
		notify(obj,'DataLogged')
	 end
  end
  methods % User-Functions
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
		  previewAtStartFcn(obj)
		end
		axis image off ij
	 end
	 function imData = getSyncFrame(obj)
		abstime = now;
		framenum = obj.framesAcquired + 1;
		try
		  imData.time = (abstime - obj.triggerTime)*60*60*24;
		catch
		  imData.time = abstime*60*60*24;
		end
		imData.vid = peekdata(obj.videoInputObj,1);
		imData.meta.AbsTime = datevec(abstime);
		imData.meta.FrameNumber = framenum;
		imData.meta.RelativeFrame = framenum;
		obj.framesAcquired = framenum;
	 end
	 function queryTriggerConfigFcn(obj)
		if ~isempty(obj.videoInputObj) && isvalid(obj.videoInputObj)
		  vti = triggerinfo(obj.videoInputObj);
		  trigfields = fields(vti);
		  for k = 1:numel(vti)
			 trigsetting = '';
			 for f = 1:numel(trigfields)
				trigfieldname = trigfields{f};
				trigsetting = sprintf('%s%s:%s|',trigsetting, trigfieldname,vti(k).(trigfieldname));
			 end
			 trigSettingList{k,1} = trigsetting;
		  end
		  output = listdlg('PromptString','Select a Trigger Configuration:',...
			 'SelectionMode','single',...
			 'ListString',trigSettingList,...
			 'ListSize',[700 300],...
			 'Name','Camera TriggerConfig',...
			 'InitialValue',4);
		  obj.triggerConfiguration = vti(output);
		  switch obj.triggerConfiguration.TriggerType
			 case 'immediate'
				obj.triggerMode = 'auto';
			 case 'manual'
				obj.triggerMode = 'manual';
			 case 'hardware'
				obj.triggerMode = 'hardware';
			 otherwise
				obj.triggerMode = 'manual';
		  end
		  % Set triggerMode to auto for software trigger
		end
	 end
	 function resetTrigConfig(obj,varargin)
		if ~obj.isvalid
		  setup(obj)
		end
		if nargin < 2
		  obj.queryTriggerConfigFcn;
		else
		  obj.triggerConfiguration = varargin{1};
		end
		try
		  stop(obj)
		  triggerconfig(obj.videoInputObj, obj.triggerConfiguration)
		catch me
		  warning(me.message)
		  obj.queryTriggerConfigFcn;
		end
		start(obj)
	 end
	 function dumpData(obj)
		if obj.videoInputObj.FramesAvailable > 0
		  data = getAllData(obj);
		  if isempty(obj.imageDataDirectory)
			 obj.imageDataDirectory = datapath();
		  end
		  if ~isdir(obj.imageDataDirectory)
			 [succ, ~, ~] = mkdir(obj.imageDataDirectory);
			 if ~succ
				obj.imageDataDirectory = userpath;
			 end
		  end
		  save('datadump','data','-append');
		  fprintf('Dumped data to: %s\n',fullfile(obj.imageDataDirectory,'datadump.mat'))
		end
	 end
  end
  methods % Set Methods
  end
  methods (Hidden)
	 function previewAtStartFcn(obj,vidObject,~)
		if nargin<2
		  vidObject = obj.videoInputObj;
		end
		% 	previewAtStartFcn@Camera(obj,vidObject,evnt);
		if ~isempty(obj.previewFigure) && ishandle(obj.previewFigure)
		  % If the 'previewFigure' has been set by another source
		  % (e.g. a GUI) the 'isembedded' property will be set to
		  % true. If the Camera is started without first assigning a
		  % 'previewFigure', then the rest of this method will handle
		  % the creation of a generic preview figure.
		  h = obj.previewFigure;
		  if ~obj.isembedded
			 obj.isembedded = false;
		  else
			 obj.isembedded = true;
		  end
		else
		  h = figure;
		  obj.isembedded = false;
		end
		if ~isempty(obj.previewImageObj) && ishandle(obj.previewImageObj)
		  hImage = obj.previewImageObj;
		else
		  uicontrol('String', 'Close',...
			 'Callback', 'close(gcf)',...
			 'position',[10 10 80 20]);
		  uicontrol('String','Flip',...
			 'Callback',@(src,evnt)flipimage(obj,src,evnt),...
			 'position',[100 10 80 20]);
		  vidRes = get(vidObject,'videoresolution');
		  nBands = get(vidObject,'NumberOfBands');
		  hImage = image;
		end
		if isempty(fields(getappdata(hImage)))
		  % Throws error if preview is started before setting UpdatePreviewWindowFcn with new camera object
		  preview(vidObject,hImage);
		end
		obj.previewAxes = handle(get(hImage,'parent'));
		if ~obj.isembedded
		  set(obj.previewAxes,...
			 'position',[0 0 1 1]);
		end
		obj.previewFigure = handle(h);
		obj.previewImageObj = handle(hImage);
		axis(obj.previewAxes,'image','ij','off')
		stoppreview(vidObject)
		if ~isempty(obj.previewImageObj)
		  setappdata(obj.previewImageObj,'UpdatePreviewWindowFcn',...
			 @(vidobj,event,imhandle)previewFrameAcquiredFcn(obj,vidobj,event,imhandle));
		else
		  warning('MatlabCompatibleCamera:setup:NoPreviewUpdateFcn',...
			 'The UpdatePreviewWindowFcn could not be set');
		end
		warning('off','imaq:peekdata:tooManyFramesRequested') %annoying once cam starts acquiring
		preview(vidObject,hImage)
		axis image off ij
		% moved several lines down on 7/12/14
		try
		  vidRes = get(obj.videoInputObj,'VideoResolution');
		  set(obj.previewFigure,...
			 'Renderer','opengl',...
			 'GraphicsSmoothing','off',...
			 'HandleVisibility','callback',...
			 'Interruptible','on',...
			 'MenuBar','none',...
			 'NextPlot','replacechildren',...
			 'ToolBar','none',...
			 'BusyAction','cancel',...
			 'Color',[.1 .1 .1],...
			 'IntegerHandle','off',...
			 'Clipping','off')%,...
		  % 			  'Position',[100 100 vidRes(1)+60 vidRes(2)+60]);
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
			 'Layer','top',...
			 'Clipping','off',...
			 'NextPlot','replacechildren',...
			 'YDir','reverse',...
			 'Units','normalized',...
			 'DataAspectRatio',[1 1 1],...
			 'BusyAction','cancel');% added 4/19
		  if isprop(obj.previewAxes, 'SortMethod')
			 obj.previewAxes.SortMethod = 'childorder';
		  else
			 obj.previewAxes.DrawMode = 'fast';
		  end
		  % 			set(obj.previewAxes,...
		  % 			   'DrawMode','fast') % added 7/12/14
		  setpixelposition(obj.previewAxes, [0 0 vidRes(1) vidRes(2)],'recursive',true);
		  set(obj.previewImageObj,...
			 'BusyAction','cancel');
		catch me
		end
		% TODO: Need to add something that flips the YData of the image object
		% set(a,'YData',fliplr(get(a,'YData')))
		function flipimage(obj,src,evnt)
		  hImage = obj.previewImageObj;
		  if ~isempty(hImage)
			 set(hImage,'YData',fliplr(get(hImage,'YData')))
		  end
		end
	 end
	 function frameAcquiredFcn(obj,vidObject,evnt)
		if obj.videoInputObj.FramesAvailable > 0
		  notify(obj,'FrameAcquired',...
			 newFrameMsg(evnt.Data));
		  % 										newFrameMsg(evnt.Data,peekdata(obj.videoInputObj,1)))
		end
	 end
	 function previewFrameAcquiredFcn(obj,src,evnt,hImage) % called on each preview frame
		persistent avgMinMax
		persistent k
		if isempty(k) || k<1
		  % 		 try
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
		  % 		 catch me
		  % 			warning(me.message)
		  % 		 end
		  k = 5;
		else
		  k = k - 1;
		end
	 end
  end
end


% Format of data returned from getSomeData() :
% viddata =
%      vid: [4-D uint16]    size=([ 256   256     1   162])
%     time: [162x1 double]
%     meta: [162x1 struct]

% Lost Methods
% createVideoInput
% startVideoAcq
% stopVideoAcq




