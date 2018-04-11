function velocity = moveStraightOnly (vr)


% DEFINE SCALING CONSTANTS
lowPassLength = 5;             % changed from 60 to 30 on 1/19/2014
omegascale = .08/lowPassLength; % changed from .15
xscale = .2/lowPassLength; % changed from .25
yscale = .2/lowPassLength; %previously .9
persistent velocityBuffer;
if isempty(velocityBuffer)
    velocityBuffer = zeros(lowPassLength,4);
end

% READ X,Y FROM SENSOR INTERFACES
leftX = vr.movementInterface.mouse1.x;
leftY = vr.movementInterface.mouse1.y;
rightX = vr.movementInterface.mouse2.x;
rightY = vr.movementInterface.mouse2.y;
vr.vrSystem.rawVelocity(1,:) = [leftX, leftY, rightX, rightY];

% CALCULATE ROTATION AROUND AXES
xrot = (leftY + rightY);        % pitch
yrot = (leftY - rightY);         % roll
zrot = -(leftX + rightX);         % yaw
vr.vrSystem.rawVelocity(2,:) = [xrot, yrot, zrot, 0];
vr.vrSystem.forwardVelocity = xrot;
vr.vrSystem.rotationalVelocity = zrot;




% MAP BALL ROTATION TO CARTESIAN MOVEMENT RELATIVE TO MOUSE (squeaky mouse)
vM.x = -yrot*xscale;            % side-stepping
vM.y = xrot*yscale;             % forwards/backwards movement
vM.z = 0;
% vM.omega = -zrot*omegascale;    % twisting the ball
% velocity = [vM.x vM.y vM.z vM.omega]; % relative to mouse
% vr.vrSystem.rawVelocity(3,:) = [vM.x vM.y vM.z vM.omega];

% SET ZROT TO ZERO SO MOUSE ONLY MOVES STRAIGHT
% vM.omega = -zrot*omegascale;    % twisting the ball
vM.omega = 0;
vM.x = 0;

velocity = [vM.x vM.y vM.z vM.omega]; % relative to mouse
vr.vrSystem.rawVelocity(3,:) = [vM.x vM.y vM.z vM.omega];


% MAP MOUSE-RELATIVE MOVEMENT TO MOVEMENT IN VIRTUAL WORLD (rotate velocity vector)
vrOmega = vr.position(4);
velocity(1:2) = [cos(vrOmega) -sin(vrOmega); sin(vrOmega) cos(vrOmega)]*velocity(1:2)';
vr.vrSystem.rawVelocity(4,:) = velocity;

% 'LOW-PASS' FILTER VELOCITY BY DAMPENING WITH PREVIOUS VALUES
velocityBuffer = [velocity/lowPassLength ; velocityBuffer(1:end-1,:)];
velocity = .5*mean(velocityBuffer,1)...
    + .25*min(velocityBuffer,[],1) ...
    + .25*max(velocityBuffer,[],1);
vr.vrSystem.rawVelocity(5,:) = velocity;




