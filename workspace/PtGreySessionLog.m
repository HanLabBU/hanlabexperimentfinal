vid = videoinput('pointgrey', 1, 'F7_Mono8_1328x1048_Mode0');
src = getselectedsource(vid);

vid.FramesPerTrigger = 1;

vid.FramesPerTrigger = Inf;

src.Brightness = 3;

src.Exposure = 0;

src.FrameRatePercentage = 99;

src.FrameRatePercentage = 100;

src.FrameRatePercentageMode = 'Off';

src.Gain = 13.6382;

src.GainMode = 'Auto';

src.GammaMode = 'Off';

src.Sharpness = 1;

src.Sharpness = 0;

src.Strobe1 = 'On';

src.ShutterMode = 'Manual';

src.ShutterMode = 'Auto';

src.Strobe1Delay = 0.005;

src.Strobe1Duration = 0.005;

src.Strobe1Polarity = 'High';

vid.LoggingMode = 'disk&memory';

diskLogger = VideoWriter('F:\Testing\synctest\usingtool\ptgrey_using_PGRUsbCam_driver.avi', 'Grayscale AVI');

vid.DiskLogger = diskLogger;

triggerconfig(vid, 'manual');

triggerconfig(vid, 'hardware', 'fallingEdge', 'externalTriggerMode0-Source0');

triggerconfig(vid, 'hardware', 'fallingEdge', 'externalTriggerMode1-Source2');

triggerconfig(vid, 'hardware', 'risingEdge', 'externalTriggerMode1-Source2');

triggerconfig(vid, 'hardware', 'risingEdge', 'externalTriggerMode15-Source3');

triggerconfig(vid, 'hardware', 'fallingEdge', 'externalTriggerMode15-Source3');

triggerconfig(vid, 'hardware', 'fallingEdge', 'externalTriggerMode0-Source0');

triggerconfig(vid, 'hardware', 'risingEdge', 'externalTriggerMode0-Source0');

triggerconfig(vid, 'manual');

vid.ROIPosition = [0 0 1327 1048];

vid.ROIPosition = [0 0 1327 1048];

vid.ROIPosition = [0 0 1327 1048];

vid.ROIPosition = [0 0 1328 500];

vid.ROIPosition = [0 100 1328 500];

vid.ROIPosition = [0 100 500 500];

vid.ROIPosition = [400 100 512 502];

vid.ROIPosition = [0 0 1328 1048];

preview(vid);

