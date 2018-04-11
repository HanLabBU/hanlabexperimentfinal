classdef DalsaCamSerialConnection < handle
  % ------------------------------------------------------------------------------
  % DalsaCamSerialConnection
  %
  % 1/8/2009
  % Mark Bucklin
  % ------------------------------------------------------------------------------
  %
  % This class is implemented by the DalsaCamera class to connect to and
  % communicate with the Camera on a Dalstar 1M30P Camera. This does not need to
  % be instantiated or dealt with by the user. However, an object of this class
  % can be instantiated from the command line by passing an object of the
  % DalsaCamera class to this object's input. e.g.
  %
  % >> obj = DalsaCamSerialConnection(dalsaCameraObject)
  %
  % This class communicates with the Camera hardware via a serial connection using
  % protocols outlined in the Dalstar 1M30P user's manual (Doc# 03-32-10001)
  %
  % ------------------------------------------------------------------------------
  
  
  
  
  
  properties (SetAccess = protected)
    hSerial
    port
    cameraObj
  end
  
  
  
  
  
  methods
    function obj = DalsaCamSerialConnection(camObject)
      if nargin>0
        obj.port = camObject.serialPort;
      else
        warndlg(...
          'Camera configuration port not specified: setting to COM5',...
          'No COM');
        obj.port = 'COM5';
      end
      obj.cameraObj = camObject;
      obj.hSerial = openSerial(obj);
      try
        try
          checkSerial(obj)
        catch
          warndlg('Turn on the Camera!')
          checkSerial(obj);
        end
        addlistener(camObject,'resolution','PostSet',...
          @DalsaCamSerialConnection.changeCamSetting);
        addlistener(camObject,'frameRate','PostSet',...
          @DalsaCamSerialConnection.changeCamSetting);
        addlistener(camObject,'gain','PostSet',...
          @DalsaCamSerialConnection.changeCamSetting);
        addlistener(camObject,'offset','PostSet',...
          @DalsaCamSerialConnection.changeCamSetting);
        addlistener(camObject,'triggerMode','PostSet',...
          @DalsaCamSerialConnection.changeCamSetting);
        setResolution(obj.hSerial,obj.cameraObj.resolution);
        setFrameRate(obj.hSerial,obj.cameraObj.frameRate);
        setGain(obj.hSerial,obj.cameraObj.gain);
        setOffset(obj.hSerial,obj.cameraObj.offset);
        setTriggerSetting(obj.hSerial,obj.cameraObj.triggerMode)
      catch me
        warning(me.message)
      end
    end
    function delete(obj)
      if ~isempty(instrfind('Name',obj.cameraObj.name))
        fclose(obj.hSerial);
        delete(obj.hSerial);
      end
    end
    function camReset(obj,hos)
      switch hos
        case 'hard'
          setCamRegistry(obj.hSerial,'80');
        case 'soft'
          setCamRegistry(obj.hSerial,'00');
      end
    end
  end
  methods (Static)
    function changeCamSetting(src,evnt)
      serialObj = evnt.AffectedObject.hardwareSettingsInterface.hSerial;
      camObj = evnt.AffectedObject;
      switch src.Name
        case 'resolution'
          if isrunning(camObj)
            stop(camObj)
            setResolution(serialObj,camObj.resolution)
            setup(camObj)
            start(camObj)
          else
            setResolution(serialObj,camObj.resolution)
            setup(camObj)
          end
        case 'frameRate'
          setFrameRate(serialObj,camObj.frameRate)
        case 'gain'
          setGain(serialObj,camObj.gain)
          setOffset(serialObj,camObj.offset)
        case 'offset'
          setOffset(serialObj,camObj.offset)
        case 'triggerMode'
          setTriggerSetting(serialObj,camObj.triggerMode)
      end
    end
  end
  methods (Hidden)
    function cam = openSerial(obj)
      cam = instrfind('Type', 'serial', 'Port',obj.port);
      if isempty(cam)
        cam = serial(obj.port);
      else
        fclose(cam);
        cam = cam(1);
      end
      set(cam,'Name',obj.cameraObj.name,...
        'timeout',1);
      fopen(cam);
    end
    function checkSerial(obj)
      lastwarn('');
      [~] = readCamRegistry(obj.hSerial,'C3');
      [~,warnmsg] = lastwarn;
      if ~isempty(warnmsg)
        if strcmp(warnmsg,'MATLAB:serial:fread:unsuccessfulRead')
          error('Failure to communicate with the Camera.')
        end
      end
    end
  end
  
  
  
  
  
end


%% Utility Functions
function setResolution(cam,resolution)
switch resolution
  case 128
    binn = '00';
  case 256
    binn = '44';
  case 512
    binn = '22';
  case 1024
    binn = '11';
  otherwise
    %         error('Resolution must be 128, 256, 512, or 1024');
end
setCamRegistry(cam,'85',binn)
end
function setFrameRate(cam,frameRate)

frameRateTime = 1e6/frameRate;
hexByte = dec2hex(round(frameRateTime));
while length(hexByte)<6
  hexByte = cat(2,'0',hexByte);
end
LSbyte = hexByte(5:6);
Cbyte = hexByte(3:4);
MSbyte = hexByte(1:2);
setCamRegistry(cam,'8D',LSbyte);
setCamRegistry(cam,'8E',Cbyte);
setCamRegistry(cam,'8F',MSbyte);
end
function setGain(cam,gain)
%gain varies between 1 and 10
% is converted to value=32768xlog(gain)
gainValue = 32768*log10(gain);
hexByte = dec2hex(round(gainValue));
while length(hexByte)<4
  hexByte = cat(2,'0',hexByte);
end
LSbyte = hexByte(3:4);
MSbyte = hexByte(1:2);
setCamRegistry(cam,'06',MSbyte);
setCamRegistry(cam,'05',LSbyte);

end
function setOffset(cam,offset)
%offset varies between -4095 and 4095

gainMSB = readCamRegistry(cam,'46');
gainLSB = readCamRegistry(cam,'45');
gainValue = hex2dec(gainMSB)*256 + hex2dec(gainLSB);
gain = 10^(gainValue/32768);
if isempty(gain)
  gain = 1;
  warndlg('Camera communication problems')
end
% Adjust gain to -4096 to 4096 from -100 to 100
if offset >= 0
  offsetValue = 8*offset/gain;
else
  offsetValue = 8*offset/gain+65536;
end
hexByte = dec2hex(round(offsetValue));
while length(hexByte)<4
  hexByte = cat(2,'0',hexByte);
end
LSbyte = hexByte(3:4);
MSbyte = hexByte(1:2);
setCamRegistry(cam,'03',MSbyte);
setCamRegistry(cam,'02',LSbyte);
end
function setTriggerSetting(cam,triggerMode)
controlreg = '82';
switch triggerMode(1:3)
  case 'man'
    externalexternal = '88';
    setCamRegistry(cam,controlreg,externalexternal);
  case 'syn'
    internalexternal = '08';
    setCamRegistry(cam,controlreg,internalexternal);
  case 'aut'
    internalinternal = '00';
    setCamRegistry(cam,controlreg,internalinternal);
end
end
function setCamRegistry(cam,hexreg,hexdata)
rbyte = hex2dec(hexreg);
rbyte = char(rbyte);
if nargin>2
  dbyte = hex2dec(hexdata);
  dbyte = char(dbyte);
  fwrite(cam,rbyte);
  fwrite(cam,dbyte);
else
  fwrite(cam,rbyte);
end
end
function out = readCamRegistry(cam,hexbyte)
%SYNTAX: output = readCamRegistry(cam,'c3')
%call the mfile 'openCamSerial' first
%cam is a serial object
%hexbyte is a string type hexadecimal number, e.g. 'c3'
cbyte = hex2dec(hexbyte);
cbyte = char(cbyte);
fwrite(cam,cbyte);
out = fread(cam,1);
out = dec2hex(out);
end
















