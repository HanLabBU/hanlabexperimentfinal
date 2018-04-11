classdef HamamatsuCameraDefault < DefaultFile
  % ------------------------------------------------------------------------------
  % DcamCameraDefault
  % FrameSynx toolbox
  % 1/8/2009
  % Mark Bucklin
  % ------------------------------------------------------------------------------
  %
  %
  % This class derives from the abstract class, DEFAULTFILE, and
  % specifies default settings for the DALSACAMERA class.
  %
  % DcamCameraDefault Properties:
  %
  % DcamCameraDefault Methods:
  %
  %
  % See also DEFAULTFILE, DALSACAMERA
  %
  
  
  
  
  
  
  
  properties
  end
  
  
  
  
  
  
  
  methods
    function obj = HamamatsuCameraDefault(varargin)
      obj = obj@DefaultFile(...
        'className','DcamCamera');
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
        'name','hamcam',...
        'gain',1,...
        'offset',100,...
        'triggerMode','manual',...
		  'videoFormat','MONO16_BIN2x2_1024x1024_FastMode',...
        'resolution',2048,...
        'frameRate',30);
%         'configFileDirectory',fullfile(imaqroot,'CameraControl\IFC Configuration Files\'));
    end
    function evaluateStrings(obj)
      obj.gain = sscanf(obj.gain,'%f');
      obj.offset = sscanf(obj.offset,'%f');
      obj.resolution = sscanf(obj.resolution,'%f');
      obj.frameRate = sscanf(obj.frameRate,'%f');
    end
  end
  
  
end









