 figure,imaqmontage(obj.greenTriggeredAverage.stim2 ./ ...
		 repmat(mean(obj.greenTriggeredAverage.stim2(:,:,:,10:15),4),...
		 [1 1 1 size(obj.greenTriggeredAverage.stim2,4)]), [.99 1.01])
 
 
 
 figure
 for n = 1:size(data,4)
		 imaqmontage(cat(4,...
				 data(:,:,:,n)./data(:,:,:,1),...
				 alignedData(:,:,:,n)./alignedData(:,:,:,1)),[.99 1.01])
		 title(num2str(n))
		 pause
 end
 
 
 
 figure,imaqmontage(double(alignedData(:,:,:,1:10))./double(repmat(alignedData(:,:,:,1),[1 1 1 10])),[.965 1.035])
 figure,imaqmontage(double(data(:,:,:,1:10))./double(repmat(data(:,:,:,1),[1 1 1 10])),[.965 1.035])