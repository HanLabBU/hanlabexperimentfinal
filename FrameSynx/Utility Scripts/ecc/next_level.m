function warp=next_level(warp_in, transform, high_flag)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%WARP=NEXT_LEVEL(WARP_IN, TRANSFORM, HIGH_FLAG)
% This function modifies appropriately the WARP values in order to apply 
% the warp in the next level. If HIGH_FLAG is equal to 1, the function 
% makes the warp appropriate for the next higher resolution level. If 
% HIGH_FLAG is equal to 0, the function makes the warp appropriate 
% for the previous lower resolution level. 
%
% Input variables:
% WARP_IN:      the current warp transform,
% TRANSFORM:    the type of adopted transform, accepted strings:
%               'affine','homography'.
% HIGH_FLAG:    The flag which defines the 'next' level. 1 means that the
%               the next level is a higher resolution level, 
%               while 0 means that is a lower resolution level.
% Output:
% WARP:         the next-level warp transform
%--------------------------------------
%
% $ Ver: 1.0.0, 1/3/2010,  released by Georgios D. Evangelidis, Fraunhofer IAIS.
% For any comment, please contact georgios.evangelidis@iais.fraunhofer.de
% or evagelid@ceid.upatras.gr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

warp=warp_in;
if high_flag==1
if strcmp(transform,'homography')
    warp(7:8)=warp(7:8)*2;
    warp(3)=warp(3)/2;
    warp(6)=warp(6)/2;
end

if strcmp(transform,'affine')
    warp(7:8)=warp(7:8)*2;
    
end

end

if high_flag==0
if strcmp(transform,'homography')
    warp(7:8)=warp(7:8)/2;
    warp(3)=warp(3)*2;
    warp(6)=warp(6)*2;
end

if strcmp(transform,'affine')
    warp(7:8)=warp(7:8)/2;
end

end