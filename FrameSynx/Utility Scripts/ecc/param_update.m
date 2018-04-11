function warp_out=param_update(warp_in,delta_p,transform)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% WARP_OUT=PARAM_UPDATE(WARP_IN,DELTA_P,TRANSFORM)
% This function updates the parameter values by adding the correction values
% of DELTA_P to current WARP values.
%
% Input variables:
% WARP_IN:      the current warp transform,
% DELTA_P:      the current correction parameter vector,
% TRANSFORM:    the type of adopted transform, accepted strings:
%               'affine','homography'.
% Output:
% WARP:         the new (updated) warp transform
%--------------------------------------
% $ Ver: 1.0.0, 1/3/2010,  released by Georgios D. Evangelidis, Fraunhofer IAIS.
% For any comment, please contact georgios.evangelidis@iais.fraunhofer.de
% or evagelid@ceid.upatras.gr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if strcmp(transform,'homography')
    delta_p=[delta_p; 0];
    warp_out=warp_in + reshape(delta_p, 3, 3);
    warp_out(3,3)=1;
end

if strcmp(transform,'affine')
    warp_out(1:2,:)=warp_in(1:2,:)+reshape(delta_p, 2, 3);
    warp_out=[warp_out;zeros(1,3)];
end