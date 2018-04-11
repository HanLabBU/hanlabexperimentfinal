%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is a demo execution of ECC image alignment algorithm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% comment one of the two following lines
transform='affine';
% transform = 'homography';

im_demo=imread('cameraman.tif'); % ... or try your image
[A,B,C]=size(im_demo);

if C==3
    im=rgb2gray(im_demo);
end

im_demo=double(im_demo);

% ROI definition example (rectangular ROI) 
Nx=21:B-20;
Ny=11:A-10;

if strcmp(transform,'affine')
% warp example for affine case
warp_demo=[-0.02 .03 1.5;...
    0.02 -0.05 -2.5];
init=zeros(2,3);
end

if strcmp(transform,'homography')
% warp example for homography case
warp_demo=[-0.02 .03 1.5;...
    0.02 -0.05 -2.5;...
    .0001 .0002 1];
init=zeros(3,3);
end

% create template artificially
template_demo = spatial_interp(im_demo, warp_demo, 'linear', transform, Nx, Ny);

% Run ECC algorithm. The initialization here is just a translation
% by 20 pixels in both direction due to Nx, Ny. Notice that template_demo is a
% geometrically distorted subimage of im_demo. This initialization gives
% rise to sufficient overlap. Otherwise, you can give as input image the
% image im_demo(Ny,Nx) without initialization (i.e. init*0)

init(1:2,3)=20;

%results=ecc(im_demo, template_demo, 1, 35, transform, init);
results=ecc(im_demo(Ny,Nx), template_demo, 1, 15, transform, init*0);