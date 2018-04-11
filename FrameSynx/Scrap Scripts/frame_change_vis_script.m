frameseq = 1:30;

stimstarts = obj.stimStartTS;
stimnums = obj.stimNumberTS;
nframes = size(obj.greenData,4);
% stim1fig = subplot(1,3,1);
% stim2fig = subplot(1,3,2);
% stim3fig = subplot(1,3,3);
try
		for n = 2:numel(stimstarts)-1
				frames = stimstarts(n)+frameseq;
				prestim = repmat(mean(...
						obj.greenData(:,:,:,stimstarts(n)-15:stimstarts(n)-5),4), [1 1 1 numel(frames)])  ;
				imdif = double(obj.greenData(:,:,:,frames)) ./ prestim;
				switch stimnums(n)
						case 0
								subplot(1,3,1)
						case 1
								subplot(1,3,2)
						case 2
								subplot(1,3,3)
				end
				for fn = 1:numel(frames)
						imagesc(imdif(5:250,5:250,:,fn),[.91  1.09])
						title(sprintf('Stim: %i',stimnums(n)))
						pause(1/7.5)
				end
		end
catch me
		me.message
		me.stack(1)
		beep
		close all
end