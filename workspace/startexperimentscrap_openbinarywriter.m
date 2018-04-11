global BFW
global EFW
global CLK

% GLOBAL FRAME CLOCK
frameClk = setGlobalFrameClock(25);


imaqreset
% BRAIN CAMERA
braincam = Camera(...
'camAdaptor', 'hamamatsu',...
'videoFormat',  'MONO16_BIN2x2_1024x1024_FastMode');
setup(braincam)
% obj.videoSrcObj.ExposureTime = .015 %TODO
braincam.videoInputObj.FramesPerTrigger = 1;
braincam.videoInputObj.LoggingMode = 'memory';
% braincam.videoInputObj.TriggerRepeat = 25*60;
% braincam.videoInputObj.FramesAcquiredFcn =  @bfwFcn;
% braintfig = braincam.queryTriggerConfiguration;	
braincam.triggerConfiguration = struct(...
   'TriggerType', 'hardware',...
   'TriggerCondition', 'RisingEdge',...
   'TriggerSource', 'SynchronousReadoutTrigger');

% EYE CAMERA
eyecam = Camera(...
'camAdaptor', 'pointgrey',...
'videoFormat',  'F7_Mono8_656x524_Mode4');
setup(eyecam)
% obj.videoSrcObj.ExposureTime = .015 %TODO
eyecam.videoInputObj.FramesPerTrigger = 1;
eyecam.videoInputObj.LoggingMode = 'memory';
eyecam.videoInputObj.TriggerRepeat = 25*60;
% eyecam.videoInputObj.FramesAcquiredFcn =  @bfwFcn;
% eyetfig = eyecam.queryTriggerConfiguration;	
eyecam.triggerConfiguration = struct(...
   'TriggerType', 'hardware',...
   'TriggerCondition', 'risingEdge',...
   'TriggerSource', 'externalTriggerMode0-Source0');








% BINARY VIDEO-FILE WRITER
BFW = vision.BinaryFileWriter;
BFW.Filename = fullfile('F:\Data\FW\test3','bfw_test3.bin');
BFW.VideoFormat = 'Custom';
BFW.BitstreamFormat = 'planar';
BFW.VideoComponentCount = 1;
BFW.VideoComponentBits = 16;
BFW.VideoComponentBitsSource = 'property';
mkdir('F:\Data\FW')
mkdir('F:\Data\FW\test3');

% 
% 
% % ADJUST WITH PREVIEW
% preview(braincam)
% start(braincam)


% BEGIN
frameClk.startBackground

