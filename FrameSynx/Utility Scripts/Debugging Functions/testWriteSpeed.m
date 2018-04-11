function varargout = testWriteSpeed(writepath,varargin)
% Usage:
%
% testWriteSpeed(writepath)
% or
% testWriteSpeed(writepath,framesize,nsecs)

if nargin>1
		vidres = varargin{1};
else
		vidres = 256;
end
if nargin>2
		nsecs = varargin{2};
else
		nsecs = 10;
end
if ~isdir(writepath)
		error('%s  is not a path',writepath)
end
fps = 30;
nframes = fps*nsecs;
disp(' ')
disp(sprintf('Testing Write to: %s',writepath))
disp(sprintf('Resolution: %i x %i',vidres,vidres))
disp(sprintf('Frames: %i',nframes))
disp(sprintf('Seconds: %i  (%i fps)',nsecs,fps))

% Make Video
vidframe = uint16(rand(vidres).*2^16);
a = whos('vidframe');
framesizeKB = a.bytes/1e3;
disp(sprintf('Frame Size: %0.1f KB',framesizeKB))
vid = repmat(vidframe,[1 1 1 nframes]);
a = whos('vid');
vidsizeMB = a.bytes/1e6;
disp(sprintf('Video Size: %0.1f MB',vidsizeMB))
disp(' ')

% Open File
tic
fid = fopen(fullfile(writepath,'videotestfile.dat'),'wb');
opentime = toc;
disp(sprintf('Time to open a file: %0.3f ms',opentime*1000))
disp(' ');

% Timed Sequential Writes
singleframewritetime = zeros(nframes,1);
timerperiod = zeros(nframes,1);
n=1;
warning('off','MATLAB:TIMER:RATEPRECISION')
t = timer(...
		'ExecutionMode','fixedRate',...
		'BusyMode','queue',...
		'Period',1/fps,...
		'TasksToExecute',nframes,...
		'TimerFcn',@saveSingleFrame);
start(t);
disp(sprintf('Testing Single-Frame Write Speed...'))
waitfor(t);
sfsum = sum(singleframewritetime)*1000;
disp(sprintf('Single-Frame Max: %0.3f ms',max(singleframewritetime)*1000))
disp(sprintf('Single-Frame Average: %0.3f ms',mean(singleframewritetime)*1000))
disp(sprintf('Single-Frame Sum: %0.3f ms',sfsum))
disp(' ')

% Large video save
disp(sprintf('Testing Whole-Video Write Speed...'))
fclose(fid);
fid = fopen(fullfile(writepath,'videotestfile.dat'),'wb');
tic
fwrite(fid,vid,'uint16');
wholevidwritetime = toc;
fclose(fid);
wvsum = wholevidwritetime*1000;
disp(sprintf('Whole-Vid Sum: %0.3f ms',wvsum))
disp(' '),disp(' '),disp(' ')

% Cleanup
delete(t)
if nargout>0
		dtest.res = vidres;
		dtest.nframes = nframes;
		dtest.fps = fps;
		dtest.framesizeKB = framesizeKB;
		dtest.singleframeavg = mean(singleframewritetime)*1000;
		dtest.singleframemax = max(singleframewritetime)*1000;
		dtest.singleframesum = sfsum;
		dtest.wholevidsum = wvsum;
		varargout{1} = dtest;
end
bar([sfsum wvsum])
title('Single-Frame Saving vs. Whole-Video Saving')

		function saveSingleFrame(src,evnt)
				tic
				fwrite(fid,vidframe(:),'uint16');
				singleframewritetime(n) = toc;
				timerperiod(n) = src.InstantPeriod;
				n=n+1;
		end
end


