% Lucas-Kanade / Gradient-Descent Image Registration
% Mark Bucklin
% June 1, 2010
% --------------------------------------------------------------------------------------------------

% Setup
rs_scale = 5;
max_iterations = 5;
template = imresize(double(obj.greenData(:,:,:,1)),rs_scale,'bicubic');
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
crop_vec = [min(roi_J) min(roi_I) max(roi_J) max(roi_I)]; % used with imcrop()??

firstframe = 40;
lastframe = 40;
data = double(obj.greenData(:,:,:,firstframe:lastframe));
Gshift = zeros([lastframe 2]);
tic
% matlabpool open
% For Each Frame
try
for n = firstframe:lastframe
		G = imresize(data(:,:,:,n-firstframe+1),rs_scale,'bicubic');
		G = reshape(G(roi_mask),sz,[]);
		iter = 1;
		h = zeros(max_iterations,2);
		Fshift = [0 0];
		
		% Repeating Section (Gradient Descent)
		while iter <= max_iterations
				I = roi_I + round(Fshift(1)); % row subscripts
				J = roi_J + round(Fshift(2)); % column subscripts
				if any(I<1) || any(J<1)
						keyboard
				end
				F = reshape(template(sub2ind(size(roi_mask),I,J)),sz,[]);% F(x+h)				
				[Fx,Fy] = gradient(F); % dF = Fx + Fy		
				% 				Fxy = Fx.^2 + Fy.^2 + Fx.*Fy;
				% 				Fxy(:,:,1) = Fx;
				% 				Fxy(:,:,2) = Fy;
				% 				Fw = Fx.^2 + Fy.^2 + Fx.*Fy;
				% Fw = Fx' * Fx;
				% 				hx = sum(sum((Fx' * (G-F)),1),2) ./ sum(sum(Fx^2,1),2);
				% 				hy = sum(sum((Fy' * (G-F)),1),2) ./ sum(sum(Fy^2,1),2);
				hx = sum(sum((Fx' * (G-F)) ./ Fx^2 ,1),2);
				hy = sum(sum((Fy' * (G-F)) ./ Fy^2 ,1),2);
				h(iter,:) = [hx hy]/1e6;
				Fshift = sum(h,1);
				% Fshift = h(iter,:);
				if max(abs(h(iter,:))) < 1
						iter = max_iterations+1;
				end
				iter = iter + 1;
		end
		Gshift(n,:) = sum(h,1);
end
% matlabpool close
catch me
		disp('Error during parfor loop')
		disp(me.message)
		keyboard
% 		matlabpool close
end
toc
plot(Gshift)




% dFdX = [fy(:) fx(:) ];
% h(iter,:) = (dFdX' * (G - F))' / (dFdX' * dFdX);


% G = reshape(G(roi_mask),sz,[]); % reshape unnecessary?
% G = repmat(reshape(G(roi_mask),sz,[]),[1 1 2]);
% dFdX = cat(3,dFi,fy);
% F = repmat(F,[1 1 2]);