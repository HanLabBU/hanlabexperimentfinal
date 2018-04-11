

rs_scale = 4;
template = imresize(obj.greenData(:,:,:,1),rs_scale,'bicubic');
cmap = min(template(:)):max(template(:));
[outerTemplate,outerRect] = imcrop(template);
[innerTemplate,innerRect] = imcrop(outerTemplate);
% [fx,fy] =  gradient(double(outerTemplate));
% fxy = fx.^2 + fy.^2 + fx.*fy;

% Repeating Part
n = 40;
imageBefore =  imresize(obj.greenData(:,:,:,n),rs_scale,'bicubic');
outerImageBefore = imcrop(imageBefore,outerRect);
% [gx, gy]  = gradient(double(outerImageBefore));
% gxy = gx.^2 + gy.^2 + gx.*gy;
% w = uint16(abs(fxy - gxy));
% w_inner = imcrop(w,innerRect);
c = normxcorr2(innerTemplate(:,:,1),outerImageBefore(:,:,1));



% offset found by correlation
[max_c, imax] = max(abs(c(:)));
[ypeak, xpeak] = ind2sub(size(c),imax(1));
corr_offset = [(xpeak-size(innerTemplate,2))
		(ypeak-size(innerTemplate,1))];

shift_needed = innerRect(1:2)' - corr_offset(:) - .51;
shiftRect = outerRect - [shift_needed' 0 0];
outerImageAfter = imcrop(imageBefore,shiftRect);

figure,imagesc(outerTemplate-outerImageBefore)
title('Before')
figure,imagesc(outerTemplate-outerImageAfter)
title('After')


% % relative offset of position of subimages
% rect_offset = [(innerRect(1)-outerRect(1))
% 		(innerRect(2)-outerRect(2))];
% 
% % total offset
% offset = corr_offset + rect_offset;
% xoffset = offset(1);
% yoffset = offset(2);
% 
% 
% % Figure out where template falls inside of peppers.
% xbegin = round(xoffset+1);
% xend   = round(xoffset+ size(template,2));
% ybegin = round(yoffset+1);
% yend   = round(yoffset+size(template,1));
% 
% % extract region from peppers and compare to template
% extracted_onion = template(ybegin:yend,xbegin:xend,:);
