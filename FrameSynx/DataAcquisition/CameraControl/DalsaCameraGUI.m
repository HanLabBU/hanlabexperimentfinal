classdef DalsaCameraGUI < hgsetget
  % ------------------------------------------------------------------------------
  % DalsaCameraGUI
  % FrameSynx toolbox
  % 1/8/2009
  % Mark Bucklin
  % ------------------------------------------------------------------------------
  %
  % This class creates a small graphical interface for controlling an
  % object of the DALSACAMERA class. The DalsaCamera class will create a
  % DalsaCameraGUI when DalsaCamera.setup method is called, unless
  % something has been assigned to the 'gui' property of DalsaCamera, such
  % as is the case when a DalsaCamera is created by the
  % ExperimentControlGUI class. In this case, a similar GUI is used, and
  % it's handled by gode within the ExperimentControlGUI class.
  %
  % DalsaCameraGUI Properties:
  %   hFig - figure handle
  %   cameraObj - DalsaCamera object
  %   prop - unused
  %   default - hardcoded structure
  %   pos - default position structure
  %   camControl - structure of uicontrol handles
  %   resolution - resolution to set
  %   frameRate - frameRate to set
  %   gain - gain to set
  %   offset - offset to set
  %   configFileDirectory - string in edit box
  %   serialPort - string from pop box
  %
  % DalsaCameraGUI Methods:
  %
  %
  % See also EXPERIMENTCONTROLGUI, DALSACAMERA
  %
  
  
  
  
  
  
  properties
    hFig %figure handle of main GUI figure
    cameraObj %camera object
    prop %unused
    default %structure of settings, hardcoded in method: defineDefaults
  end
  properties %TEMPORARY
    pos %structure of default positions
    camControl %structure of handles to uicontrol objects and panels
  end
  properties (Dependent, SetAccess = private) %CAMERA PROPERTIES
    resolution % default: 4096
    frameRate % default: 30
    gain % default: 1
    offset % default: 0
    configFileDirectory % default: '~\...\CameraControl\IFC Configuration Files'
    serialPort % default: COM5 or COM7, etc. Configurable in Windows Device Manager. Use instrhwinfo('serial').
  end
  
  
  methods
    function obj = DalsaCameraGUI(varargin)
      if nargin > 1
        for k = 1:2:length(varargin)
          obj.(varargin{k}) = varargin{k+1};
        end
      end
      obj.definePositionStructure();
      obj.defineDefaults();
      obj.buildFigure();
      set(obj.hFig,'HandleVisibility','callback');
      addlistener(obj.cameraObj,'PreviewFrameAcquired',...
        @(src,evnt)updateHistWindow(obj,src,evnt));
    end
    function definePositionStructure(obj)
      sz = get(0,'MonitorPositions');
      if size(sz,1) > 1
        obj.pos.dualmonitor = true;
        obj.pos.rightmonwidth = sz(1,3)-sz(1,1);
        obj.pos.rightmonheight = sz(1,4);
        obj.pos.rightmonpos = sz(1,1:2);
        obj.pos.leftmonwidth = sz(2,3);
        obj.pos.leftmonheight = sz(2,4);
      else
        obj.pos.dualmonitor = false;
        obj.pos.monwidth = sz(1,3);
        obj.pos.monheight = sz(1,4);
      end
      obj.pos.sliderlength = 190;
      obj.pos.sliderwidth = 25;
      obj.pos.standard = [10 10];
      obj.pos.bigbutton = [90 30];
      obj.pos.medbutton = [60 20];
      obj.pos.smallbutton = [40 15];
      obj.pos.shorttext = [40 20];
      obj.pos.medtext = [60 20];
      obj.pos.longtext = [90 20];
      obj.pos.xlongtext = [120 20];
      obj.pos.panwidth1 = 110;
      
      obj.pos.campanel = [40 100 420 460];
      obj.pos.datapanel = [500 100 240 560];
      obj.pos.bhvpanel = [750 100 250 600];
      obj.pos.illumpanel = [40 590 260 100];
      if obj.pos.dualmonitor
        obj.pos.mainfig = [40 60 1000 900];
      else
        obj.pos.mainfig = [40 60 1000 900];
      end
    end
    function defineDefaults(obj)
      obj.default.maxminoffset = 4096;
      obj.default.offset = 0;
      obj.default.gain = 1;
      obj.default.maxgain = 10;
      obj.default.configFileDir = [fileparts(which('Camera')),filesep,'IFC Configuration Files'];
      obj.default.maxFR = 30;
    end
    function buildFigure(obj)
      % This function handles the creation/construction of the figure and
      % all its buttons, sliders, text-boxes, etc., and stores all the
      % returned handles in the camControl property (a struct)
      
      %% Initialize Figure
      obj.hFig = figure;
      set(obj.hFig,...
        'units','pixels',...
        'tag','camconfigpanel',...
        'menubar','none',...
        'name','Camera Configuration',...
        'numbertitle','off',...
        'resize','off',...
        'position',obj.pos.campanel);
      %% Resolution Control
      obj.camControl.resBg = uibuttongroup(obj.hFig,...
        'units','pix',...
        'pos',[10 10 obj.pos.panwidth1 110],...
        'tag','resbuttongroup',...
        'title','Resolution');
      obj.camControl.resradio(1) = uicontrol(obj.camControl.resBg,...
        'style','rad',...
        'unit','pix',...
        'position',[10 70 obj.pos.medtext],...
        'string','1024');
      obj.camControl.resradio(2) = uicontrol(obj.camControl.resBg,...
        'style','rad',...
        'unit','pix',...
        'position',[10 50 obj.pos.medtext],...
        'string','512');
      obj.camControl.resradio(3) = uicontrol(obj.camControl.resBg,...
        'style','rad',...
        'unit','pix',...
        'position',[10 30 obj.pos.medtext],...
        'string','256',...
        'value',1); % Make 256 the Default
      obj.camControl.resradio(4) = uicontrol(obj.camControl.resBg,...
        'style','rad',...
        'unit','pix',...
        'position',[10 10 obj.pos.medtext],...
        'string','128');
      set(obj.camControl.resradio,...
        'callback',@(src,evnt)resolutionControlFcn(obj,src,evnt));
      %% FrameRate Control
      panpos = get(obj.camControl.resBg,'position');
      pany= panpos(4)+15;
      obj.camControl.frPan = uipanel(obj.hFig,...
        'units','pixels',...
        'tag','frpanel',...
        'position',[10 pany obj.pos.panwidth1 50],...
        'title','Frame Rate');
      obj.camControl.frTxt = uicontrol(obj.camControl.frPan,...
        'style','edit',...
        'tag','fredit',...
        'units','pixels',...
        'position',[10 10 obj.pos.shorttext],...
        'string','30',...
        'callback',@(src,evnt)framerateControlFcn(obj,src,evnt));
      %% Gain Control
      obj.camControl.gainPan =  uipanel(obj.hFig,...
        'units','pixels',...
        'tag','gainpanel',...
        'position',[10 180 50 260 ],...
        'title','Gain');
      obj.camControl.gainTxt = uicontrol(obj.camControl.gainPan,...
        'units','pixels',...
        'style','edit',...
        'tag','gainedit',...
        'position',[5 5 30 20],...
        'string','1');
      obj.camControl.gainSlider = uicontrol(obj.camControl.gainPan,...
        'units','pixels',...
        'style','slider',...
        'tag','gainslider',...
        'position',[5 30 26 195],...
        'max',obj.default.maxgain,...
        'min',obj.default.gain,...
        'value',obj.default.gain);
      obj.camControl.gainResetButt = uicontrol(obj.camControl.gainPan,...
        'style','pushbutton',...
        'tag','gainresetbutton',...
        'units','pixels',...
        'position',[3 230 40 15],...
        'string','Reset');
      set([obj.camControl.gainTxt, obj.camControl.gainSlider obj.camControl.gainResetButt],...
        'callback',@(src,evnt)gainControlFcn(obj,src,evnt));
      %% Offset Control
      obj.camControl.offsetPan = uipanel(obj.hFig,...
        'units','pixels',...
        'tag','offsetpanel',...
        'position',[70 180 50 260 ],...
        'title','Offset');
      obj.camControl.offsetTxt = uicontrol(obj.camControl.offsetPan,...
        'units','pixels',...
        'style','edit',...
        'tag','offsetedit',...
        'position',[2 5 34 20],...
        'string','0');
      obj.camControl.offsetSlider = uicontrol(obj.camControl.offsetPan,...
        'units','pixels',...
        'style','slider',...
        'tag','offsetslider',...
        'position',[5 30 26 195],...
        'max',obj.default.maxminoffset,...
        'min',-obj.default.maxminoffset,...
        'value',obj.default.offset);
      obj.camControl.offsetResetButt = uicontrol(obj.camControl.offsetPan,...
        'style','pushbutton',...
        'tag','offsetresetbutton',...
        'units','pixels',...
        'position',[3 230 40 15],...
        'string','Reset');
      set([obj.camControl.offsetTxt, obj.camControl.offsetSlider, obj.camControl.offsetResetButt],...
        'callback',@(src,evnt)offsetControlFcn(obj,src,evnt));
      %% Pixel Intensity Histogram Frame
      obj.camControl.intensityHistAx = axes('parent',obj.hFig);
      set(obj.camControl.intensityHistAx,...
        'units','pixels',...
        'position',[130 182 280 250],...
        'tag','intensityhist');
      axis off
      %% Configuration File Control
      obj.camControl.configFilePan = uipanel(obj.hFig,...
        'units','pixels',...
        'tag','configfilepanel',...
        'position',[127 10 280 55],...
        'title','Configuration File');
      obj.camControl.configFileTxt = uicontrol(obj.camControl.configFilePan,...
        'style','edit',...
        'tag','configfileedit',...
        'units','pixels',...
        'horizontalalignment','left',...
        'position',[10 10 180 20],...
        'string',obj.default.configFileDir);
      obj.camControl.configFileChgDirButt = uicontrol(obj.camControl.configFilePan,...
        'style','pushbutton',...
        'tag','configfilechangebutt',...
        'units','pixels',...
        'position',[210 10 60 20],...
        'string','Open');
      set([obj.camControl.configFileTxt, obj.camControl.configFileChgDirButt],...
        'callback',@(src,evnt)configFileControlFcn(obj,src,evnt));
    end
  end
  methods % UICONTROL RESPONSE
    function resolutionControlFcn(obj,src,evnt)
      if ~isempty(obj.cameraObj)
        obj.cameraObj.resolution = obj.resolution;
        axis(obj.cameraObj.previewAxes,'image','off','ij')
      end
      figure(obj.hFig)
    end
    function framerateControlFcn(obj,src,evnt)
      txt = get(obj.camControl.frTxt,'string');
      try
        num = eval(txt);
      catch me
        errordlg(['Frame rate must be numeric (',me.message,')'])
      end
      if num > obj.default.maxFR
        set(obj.camControl.frTxt,'string',num2str(obj.default.maxFR))
      end
      if ~isempty(obj.cameraObj)
        set(obj.cameraObj,'frameRate',obj.frameRate);
      end
    end
    function gainControlFcn(obj,src,~)
      switch src
        case obj.camControl.gainTxt
          L = get(obj.camControl.gainSlider,{'min','max','value'});  % Get the slider's info.
          E = str2double(get(src,'string'));  % Numerical edit string.
          if E >= L{1} && E <= L{2}
            set(obj.camControl.gainSlider,'value',E)  % E falls within range of slider.
          else
            set(src,'string',L{3}) % User tried to set slider out of range.
          end
        case obj.camControl.gainSlider
          set(obj.camControl.gainTxt,'string',get(src,'value'));
        case obj.camControl.gainResetButt
          set(obj.camControl.gainTxt,'string',obj.default.gain);
          set(obj.camControl.gainSlider,'value',obj.default.gain);
      end
      if ~isempty(obj.cameraObj)
        obj.cameraObj.gain = obj.gain;
      end
    end
    function offsetControlFcn(obj,src,evnt)
      switch src
        case obj.camControl.offsetTxt
          L = get(obj.camControl.offsetSlider,{'min','max','value'});  % Get the slider's info.
          E = str2double(get(src,'string'));  % Numerical edit string.
          if E >= L{1} && E <= L{2}
            set(obj.camControl.offsetSlider,'value',round(E))  % E falls within range of slider.
          else
            set(src,'string',round(L{3})) % User tried to set slider out of range.
          end
        case obj.camControl.offsetSlider
          set(obj.camControl.offsetSlider,'value',round(get(obj.camControl.offsetSlider,'value')))
          set(obj.camControl.offsetTxt,'string',get(src,'value'));
        case obj.camControl.offsetResetButt
          set(obj.camControl.offsetTxt,'string',obj.default.offset);
          set(obj.camControl.offsetSlider,'value',obj.default.offset);
      end
      if ~isempty(obj.cameraObj)
        obj.cameraObj.offset = obj.offset;
      end
    end
    function configFileControlFcn(obj,src,evnt)
      switch src
        case obj.camControl.configFileTxt
          txt = get(src,'string');
          if isdir(txt)
            return
          else
            cfdir = uigetdir(obj.default.configFileDir);
          end
        case obj.camControl.configFileChgDirButt
          cfdir = uigetdir(obj.default.configFileDir);
      end
      set(obj.camControl.configFileTxt,'string',cfdir);
      if ~isempty(obj.cameraObj)
        obj.cameraObj.configFileDirectory = cfdir;
      end
      figure(obj.hFig)
    end
  end
  methods % GET FUNCTIONS
    function res = get.resolution(obj)
      if ~isempty(obj.camControl) && isfield(obj.camControl,'resradio')
        res = eval(get(findobj(obj.camControl.resradio,'val',1),'string'));
      else
        res = [];
      end
    end
    function fr = get.frameRate(obj)
      fr = eval(get(obj.camControl.frTxt,'string'));
    end
    function offset = get.offset(obj)
      offset = get(obj.camControl.offsetSlider,'value');
    end
    function gain = get.gain(obj)
      gain = get(obj.camControl.gainSlider,'value');
    end
    function configdir = get.configFileDirectory(obj)
      configdir = get(obj.camControl.configFileTxt,'string');
    end
    function hserial = get.serialPort(obj)
      comlist = get(obj.camControl.camObjComPoplist,'string');
      hserial = comlist{get(obj.camControl.camObjComPoplist,'val')};
    end
  end
  methods % EVENT RESPONSE
    function updateHistWindow(obj,camobj,previewmsg) 
      %Respond to Camera PreviewFrameAcquired event, which is broadcast for
      %every frame that is sent from the camera to the computer but not
      %necessarily acquired (put in the frame buffer).
      try
        if ishandle(obj.hFig) && strcmp(get(obj.hFig,'visible'),'on')
          evnt = previewmsg.previewEvent;
          hist(obj.camControl.intensityHistAx,double(evnt.Data(:)),1:256);
          set(obj.camControl.intensityHistAx,...
            'xlim',[1 256],...
            'ytick',[],...
            'yticklabel',[],...
            'xtick',[])
        end
      catch me % error thrown when camera is restarted
        warning(me.message)
        disp(me.stack(1))
      end
    end
  end
  
  
  
  
  
  
end