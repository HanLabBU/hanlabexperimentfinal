[data,info] = getData(vidfiles);
imaqmontage(data(:,:,:,1:16))

% Temporal Binning
redframes = data(:,:,:,1:4:end) + data(:,:,:,2:4:end);
greenframes = data(:,:,:,3:4:end-1) + data(:,:,:,4:4:end);

res = 1024;
binfactor = 4;
% ind = ones(res/binfactor,binfactor);
% for n = 1:binfactor
% 	ind(:,n) = n:binfactor:res;
% end

sb_red =  zeros(256,256,1,size(redframes,4));
sb_green =  zeros(256,256,1,size(greenframes,4));
for n = 1:size(sb_red,4)
	sb_red(:,:,1,n) = reshape(  sum(  im2col(redframes(:,:,1,n),[4 4],'distinct')        ,1)  ,256,[]);
end
for n = 1:size(sb_green,4)
	sb_green(:,:,1,n) = reshape(  sum(  im2col(greenframes(:,:,1,n),[4 4],'distinct')        ,1)  ,256,[]);
end






