vid = videoinput('hamamatsu', 1, 'MONO16_BIN2x2_1024x1024_FastMode');
src = getselectedsource(vid);

vid.FramesPerTrigger = 1;

src.ExposureTime = 0.05;

vid.LoggingMode = 'disk&memory';

imaqmem(60000000000);

diskLogger = VideoWriter('F:\Testing\synctest\usingtool\straightfromtool.avi', 'Grayscale AVI');

vid.DiskLogger = diskLogger;

diskLogger = VideoWriter('F:\Testing\synctest\usingtool\straightfromtool_0001.avi', 'Grayscale AVI');

vid.DiskLogger = diskLogger;

diskLogger = VideoWriter('F:\Testing\synctest\usingtool\straightfromtool.avi', 'Grayscale AVI');

vid.DiskLogger = diskLogger;

diskLogger = VideoWriter('F:\Testing\synctest\usingtool\straightfromtool_0001.avi', 'Grayscale AVI');

vid.DiskLogger = diskLogger;

diskLogger = VideoWriter('F:\Testing\synctest\usingtool\straightfromtool_0001.mj2', 'Archival');

vid.DiskLogger = diskLogger;

diskLogger.FrameRate = 20;

diskLogger.MJ2BitDepth = 16;

% TriggerRepeat is zero based and is always one
% less than the number of triggers.
vid.TriggerRepeat = Inf;

triggerconfig(vid, 'manual');

triggerconfig(vid, 'hardware', 'FallingEdge', 'EdgeTrigger');

triggerconfig(vid, 'hardware', 'FallingEdge', 'SynchronousReadoutTrigger');

triggerconfig(vid, 'hardware', 'RisingEdge', 'SynchronousReadoutTrigger');

triggerconfig(vid, 'hardware', 'RisingEdge', 'EdgeTrigger');

triggerconfig(vid, 'hardware', 'FallingEdge', 'EdgeTrigger');

triggerconfig(vid, 'hardware', 'RisingEdge', 'EdgeTrigger');

triggerconfig(vid, 'manual');

vid.ROIPosition = [0 0 1023 1024];

vid.ROIPosition = [0 0 1024 1024];

vid.ROIPosition = [0 0 512 1024];

vid.ROIPosition = [0 0 512 512];

vid.ROIPosition = [256 0 512 512];

vid.ROIPosition = [255 0 512 512];

vid.ROIPosition = [255 255 512 512];

vid.ROIPosition = [0 0 1024 1024];

preview(vid);

vid.FramesPerTrigger = Inf;

imaqmem(Inf);

stoppreview(vid);

preview(vid);

stoppreview(vid);

stoppreview(vid);

diskLogger = VideoWriter('F:\Testing\synctest\usingtool\straightfromtool_0002.mj2', 'Archival');

diskLogger.FrameRate = 20;

diskLogger.MJ2BitDepth = 16;

vid.DiskLogger = diskLogger;

