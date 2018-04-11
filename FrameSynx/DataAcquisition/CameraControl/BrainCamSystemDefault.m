classdef BrainCamSystemDefault < DefaultFile
  % ------------------------------------------------------------------------------
  % BrainCamSystemDefault
  % FrameSynx toolbox
  % 1/8/2009
  % Mark Bucklin
  % ------------------------------------------------------------------------------
  %
  %
  % This class derives from the abstract class, DEFAULTFILE, and
  % specifies default settings for the DALSACAMERA class.
  %
  % BrainCamSystemDefault Properties:
  %
  % BrainCamSystemDefault Methods:
  %
  %
  % See also DEFAULTFILE, DALSACAMERA
  %
  
  
  
  
  
  
  
  properties
  end
  
  
  
  
  
  
  
  methods
    function obj = BrainCamSystemDefault(varargin)
      obj = obj@DefaultFile(...
        'className','BrainCamSystem');
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
		  'sessionPath','F:\Data\DefaultSessionPath',...
        'systemName','braincamsystem',...
        'triggerMode','manual',...
		  'videoFormat','MONO16_BIN2x2_1024x1024_FastMode',...        
        'exposureTime',30);
%         'configFileDirectory',fullfile(imaqroot,'CameraControl\IFC Configuration Files\'));
    end
    function evaluateStrings(obj)
    end
  end
  
  
end









