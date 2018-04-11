function vidfile = makehamcamfcn()
obj =  Camera(...
  'camAdaptor', 'hamamatsu',...
  'videoFormat',  'MONO16_BIN2x2_1024x1024_FastMode',...
  'triggerConfiguration', 'manual');
setup(obj);
start(obj);
vidfile = VideoFile();
vidfile.experimentName = 'TSP2';
t = timer(...
  'ExecutionMode', 'singleShot',...
  'startFcn',@(~,~)trigger(obj),...
  'StartDelay', 10,...
  'TimerFcn', @(~,~)stop(obj),...
  'TasksToExecute', 1,...
  'StopFcn',@(src,evnt)stopsavefcn(obj,vidfile,src,evnt));
pause(1)
start(t)

  function stopsavefcn(obj,vidfile,src,evnt)
	 nFrames = obj.videoInputObj.FramesAvailable
	 [data,tstamp,meta] =  getdata(obj.videoInputObj,nFrames);
	 data = squeeze(data);
	 for k=1:nFrames
		meta(k).AbsTime = datenum(meta(k).AbsTime);
		vidfile.addFrame2File(data(:,:,k), meta(k))
	 end
	 fname = fullfile(vidfile.rootPath, vidfile.experimentName);
	 save(fname, 'vidfile');
	 delete(src)
	 delete(obj)
  end
end