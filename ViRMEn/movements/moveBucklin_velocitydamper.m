function velocity = moveBucklin (vr)


% DEFINE SCALING CONSTANTS
omegascale = 1/10; % ballpark 1/10 is good
xscale = 1/3;
yscale = 1/2;
dampCoefficient = .4;

% READ X,Y FROM SENSOR INTERFACES
leftX = vr.movementInterface.mouse1.x;
leftY = vr.movementInterface.mouse1.y;
rightX = vr.movementInterface.mouse2.x;
rightY = vr.movementInterface.mouse2.y;

% CALCULATE ROTATION AROUND AXES
xrot = -(leftY + rightY);        % pitch
yrot = (leftY - rightY);         % roll
zrot = (leftX + rightX);         % yaw

% MAP BALL ROTATION TO CARTESIAN MOVEMENT RELATIVE TO MOUSE (squeaky mouse)
vM.x = -yrot*xscale;
vM.y = xrot*yscale;
vM.z = 0;
vM.omega = -zrot*omegascale;
velocity = [vM.x vM.y vM.z vM.omega]; % relative to mouse

% MAP MOUSE-RELATIVE MOVEMENT TO MOVEMENT IN VIRTUAL WORLD (rotate velocity vector)
vrOmega = vr.position(4);
velocity(1:2) = [cos(vrOmega) -sin(vrOmega); sin(vrOmega) cos(vrOmega)]*velocity(1:2)';

% 'LOW-PASS' FILTER VELOCITY BY DAMPENING WITH PREVIOUS VALUES
velocity = dampCoefficient*velocity + (1-dampCoefficient)*vr.dampVelocity;
vr.dampVelocity = velocity;





