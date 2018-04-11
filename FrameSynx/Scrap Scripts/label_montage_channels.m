% Define Data and Channel-Info
channel = obj.channelF;
channel(channel==32) = 120;
% channel(info.FrameNumber-info.FrameNumber(1)+1) = info.Channel;


for firstframe = 1:100:length(channel)
		lastframe = min([length(channel) firstframe+99]);
		channelset = channel(firstframe:lastframe);
		disp(char(channelset))
		dataset = data(:,:,:,firstframe:lastframe);
		
		% Produce Figure
		imaqmontage(dataset)
		title(sprintf('Frame %i to Frame %i  (of %i)',firstframe,lastframe,length(channel)))
		
		nframes = lastframe-firstframe+1;
		nrows = ceil(sqrt(nframes));
		ncols = nrows;
		imres = 256;
		
		nframe = 1;		
		for row = 1:nrows
				for col = 1:ncols
						if nframe > nframes
								fprintf('row: %i\ncolumn: %i\nnframe: %i\nchannel: %s\n',row,col,nframe,char(channelset(nframe)))
								break
						end
						switch char(channelset(nframe))
								case 'r'
										textcol = [.8 0 0];
								case 'g'
										textcol = [0 .6 0];
								otherwise
										textcol = [1 1 1];
						end
						text(imres*col-imres/2 , imres*row-imres/2 , upper(char(channelset(nframe))),...
								'FontSize',16,...
								'Color',textcol);
						nframe = nframe+1;
				end
		end
		pause
		clf
end
