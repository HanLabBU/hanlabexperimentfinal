% ImageRegistration
% Mark Bucklin
% June 1, 2010
% --------------------------------------------------------------------------------------------------

% Make Template
template = double(obj.greenData(:,:,:,1));

% Get ROI (default is central 75%)
hfig = imagesc(template);
hax = gca;
rectObj = imrect(hax);
setPosition(rectObj,...
		[size(template,2)/8    size(template,1)/8 ...
		size(template,2)*3/4 size(template,1)*3/4] );
setFixedAspectRatioMode(rectObj,true);
wait(rectObj);
roi_mask = rectObj.createMask();
sz = sqrt(sum(roi_mask(:)));
[roi_I roi_J] = find(roi_mask);
clf

% Align Images Using Outside Functions
first_frame = 1;
last_frame = 100;
data = obj.greenData(:,:,:,first_frame:last_frame);
n_frames = max(size(data,4),last_frame-first_frame+1);
alignedData = zeros(size(data),class(data));
M = zeros([3 3 n_frames]);

matlabpool open
try
		parfor n = 1:n_frames
				fn = n + first_frame - 1;
				[~, imOut] = alignImages(template,double(data(:,:,:,n)));
				alignedData(:,:,:,n) = uint16(imOut);
		end
		matlabpool close
catch me
		disp(me.message)
		disp(me.stack(1))
		beep
		matlabpool close
end






