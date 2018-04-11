% a script that uses MATLAB's CP tools to align image input to image base

[w,h] = size(base);
[x,y] = meshgrid((1:w)-w/2,(1:h)-h/2);

sig = 3;
fltr = fftshift(exp(-(x.^2+y.^2)/(2*sig^2)));

input = (input-real(ifft2(fft2(input).*fltr)));

base = (base-real(ifft2(fft2(base).*fltr)));

input = uint16((input-min(input(:)))/(max(input(:))-min(input(:)))*2^16);
base = uint16((base-min(base(:)))/(max(base(:))-min(base(:)))*2^16);

figure, imshow(input)
figure, imshow(base)

% Block the tool until you pick some more control points
H = cpselect(input,base);

t_concord = cp2tform(input_points,base_points,'projective');
input_registered = imtransform(input, t_concord,'XData',[1 w],'YData',[1 h]);

figure, imshow(input_registered);