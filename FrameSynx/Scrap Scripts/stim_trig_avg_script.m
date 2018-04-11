% Get Averages for Each Stimulus
prestim = -30;
poststim = 30;
stim_min = 7;
stimrelative_index = prestim:stim_min-1+poststim;
stimlengths = find(diff(obj.stimStatusFS)<0)-find(diff(obj.stimStatusFS)>0);
stimstarts = find(diff(obj.stimStatusFS)>0);
stimnums = obj.stimNumberFS(stimstarts+1);
stim = unique(stimnums);
for n=1:numel(stim)
		ind = stimnums == stim(n);
		ind = ind & stimlengths == stim_min | stimlengths == stim_min+1;
		ind = ind & stimstarts+stim_min+poststim <=size(obj.redData,4);
		firstframe = stimstarts(ind);
		[X,Y] = meshgrid(firstframe, stimrelative_index );
		index_mat = X+Y;
		redtrigavg.(sprintf('stim%i',n)) = mean(reshape(obj.redData(:,:,:,index_mat), [obj.resolution 1 size(index_mat)]),5);
end

% Find Blank Trials
s = redtrigavg;




% Display
imaqmontage(s.stim1-s.stim2)
colormap('jet')
% Label Montage
nframes = poststim+stim_min-prestim;
imres = obj.resolution;
nrows = ceil(sqrt(nframes));
ncols = floor(sqrt(nframes));
vdist = imres/6;
hdist = imres/6;
nframe = 1;
for row = 1:nrows
		for col = 1:ncols
				if nframe > nframes
						break
				end
				if ismember(stimrelative_index(nframe), 0:stim_min-1)
						textcol = [.8 0 0];
				else
						textcol = [0 .6 0];
				end
				text(imres*col-hdist , imres*row-vdist , num2str(stimrelative_index(nframe)),...
						'FontSize',12,...
						'Color',textcol);
				nframe = nframe+1;
		end
end