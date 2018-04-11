classdef DalsaCameraDefault < DefaultFile
  % ------------------------------------------------------------------------------
  % DalsaCameraDefault
  % FrameSynx toolbox
  % 1/8/2009
  % Mark Bucklin
  % ------------------------------------------------------------------------------
  %
  %
  % This class derives from the abstract class, DEFAULTFILE, and
  % specifies default settings for the DALSACAMERA class.
  %
  % DalsaCameraDefault Properties:
  %
  % DalsaCameraDefault Methods:
  %
  %
  % See also DEFAULTFILE, DALSACAMERA
  %
  
  
  
  
  
  
  
  properties
  end
  
  
  
  
  
  
  
  methods
    function obj = DalsaCameraDefault(varargin)
      obj = obj@DefaultFile(...
        'className','DalsaCamera');
      if nargin > 1
        for k = 1:2:length(varargin)
          obj.(varargin{k}) = varargin{k+1};
        end
      end
      if isempty(obj.hardCodeDefault)
        defineHardCodeDefaults(obj)
      end
      checkFile(obj)
      readFile(obj)
      evaluateStrings(obj)
    end
  end
  methods (Hidden)
    function defineHardCodeDefaults(obj)
      obj.hardCodeDefault = struct(...
        'name','Dalsa 1M30P',...
        'gain',1,...
        'offset',0,...
        'triggerMode','auto',...
        'serialPort','COM5',...
        'resolution',256,...
        'frameRate',30,...
        'configFileDirectory',fullfile(imaqroot,'CameraControl\IFC Configuration Files\'));
    end
    function evaluateStrings(obj)
      obj.gain = sscanf(obj.gain,'%f');
      obj.offset = sscanf(obj.offset,'%f');
      obj.resolution = sscanf(obj.resolution,'%f');
      obj.frameRate = sscanf(obj.frameRate,'%f');
    end
  end
  
  
end









