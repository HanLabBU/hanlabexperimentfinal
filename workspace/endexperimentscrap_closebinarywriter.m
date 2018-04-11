global BFW
clk.stop;
BFW.release;
stoppreview(obj);
evlog = obj.videoInputObj.EventLog;%TODO


% CONSTRUCT BINARY FILE READER USING INFORMATION FROM CAMERA AND WRITER
info = imaqhwinfo(obj.videoInputObj);
bfr = vision.BinaryFileReader;
fldr = fieldnames(bfr);
fldw = fieldnames(BFW);
for k=1:numel(fldr)
  if ismember(fldr(k),fldw)
	 bfr.(fldr{k}) = BFW.(fldr{k});
  end
end

N = obj.videoInputObj.TriggersExecuted;
frameSize = fliplr(obj.videoInputObj.VideoResolution);
bfr.VideoComponentSizes = frameSize;


multiWaitbar('Loading Video from Binary File',0);
data(frameSize(1), frameSize(2), N) = cast(0,info.NativeDataType);
tic
for k=1001:N
  data(:,:,k) = bfr.step;
  multiWaitbar('Loading Video from Binary File', 'Increment', 1/N);
end
toc % 1000 frames/minute at commandline
