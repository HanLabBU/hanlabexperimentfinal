function bfwFcn(src,evnt)
global BFW
if isempty(BFW)
  BFW = vision.BinaryFileWriter
  BFW.Filename = fullfile('F:\Data\BFW\test1','test1.bin')
  BFW.VideoFormat = 'Custom'
  BFW.BitstreamFormat = 'planar';
  BFW.VideoComponentCount = 1;
  BFW.VideoComponentBits = 16
  BFW.VideoComponentBitsSource = 'property'
end
%make directory
BFW.step(getdata(src));









% JAVA ALTERNATIVE WITH PREALLOCATION
% fh = javaObject('java.io.RandomAccessFile', fpath, 'rw');
% fh.setLength(1024*1024*4*N)
% writeShort(fh,uint16(59))
% fh.close
% fh = javaObject('java.io.File', fpath);
% fsh = javaObject('java.io.FileOutputStream',fh)
% dsh = javaObject('java.io.DataOutputStream', fsh)

% feature getpid

% abstime = event.Data.AbsTime;
% AbsTime: [2004 12 29 16 40 52.5990]
% FrameMemoryLimit: 139427840
% FrameMemoryUsed: 0
% FrameNumber: 0
% RelativeFrame: 0
% TriggerIndex: 1


