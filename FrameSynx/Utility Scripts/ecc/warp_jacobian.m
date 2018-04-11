function J = warp_jacobian(nx, ny, warp, transform)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%J = WARP_JACOBIAN(NX, NY, WARP, TRANSFORM)
% This function computes the jacobian J of warp transform with respect 
% to parameters. In case of homography transform, the jacobian depends on
% the parameter values, while in affine case is totally invariant.
%
% Input variables:
% NX:           the x-coordinate values of horizontal side of ROI (i.e. [xmin:xmax]),
% NY:           the y-coordinate values of vertical side of ROI (i.e. [ymin:ymax]),
% WARP:         the warp transform (it is used only in homography case),
% TRANSFORM:    the type of adopted transform, accepted strings: 'affine','homography'
% 
% Output:
% J:            The jacobian matrix J
%--------------------------------------
% $ Ver: 1.0.0, 1/3/2010,  released by Georgios D. Evangelidis, Fraunhofer IAIS.
% For any comment, please contact georgios.evangelidis@iais.fraunhofer.de
% or evagelid@ceid.upatras.gr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

snx=length(nx);
sny=length(ny);

Jx=nx(ones(1,sny),:);
Jy=ny(ones(1,snx),:)';
J0=0*Jx;
J1=J0+1;

if strcmp(transform,'homography')

    xy=[Jx(:)';Jy(:)';ones(1,snx*sny)];


    %3x3 matrix transformation
    A = warp;
    A = A + eye(3);
    A(3,3) = 1;

    % new coordinates
    xy_prime = A * xy;



    % division due to homogeneous coordinates
    xy_prime(1,:) = xy_prime(1,:)./xy_prime(3,:);
    xy_prime(2,:) = xy_prime(2,:)./xy_prime(3,:);

    den = xy_prime(3,:)';

    Jx(:) = Jx(:) ./ den;
    Jy(:) = Jy(:) ./ den;
    J1(:) = J1(:) ./ den;

    Jxx_prime = Jx;
    Jxx_prime(:) = Jxx_prime(:) .* xy_prime(1,:)';
    Jyx_prime = Jy;
    Jyx_prime(:) = Jyx_prime(:) .* xy_prime(1,:)';

    Jxy_prime = Jx;
    Jxy_prime(:) = Jxy_prime(:) .* xy_prime(2,:)';
    Jyy_prime = Jy;
    Jyy_prime(:) = Jyy_prime(:) .* xy_prime(2,:)';


    J = [Jx, J0, -Jxx_prime, Jy, J0, - Jyx_prime, J1, J0;
        J0, Jx, -Jxy_prime, J0, Jy, -Jyy_prime, J0, J1];

else

    J = [Jx, J0, Jy, J0, J1, J0; J0, Jx, J0, Jy, J0, J1];
end







