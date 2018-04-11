function velocity = moveBucklin (vr)


% DEFINE SCALING CONSTANTS
lowPassLength = 10;             % changed from 60 to 30 on 1/19/2014
omegascale = .1/lowPassLength; % changed from .3
xscale = .25/lowPassLength; % changed from .25
yscale = .3/lowPassLength; %previously .9
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
xrot = -(leftY + rightY);        % pitch
yrot = (leftY - rightY);         % roll
zrot = (leftX + rightX);         % yaw
vr.vrSystem.rawVelocity(2,:) = [xrot, yrot, zrot, 0];
vr.vrSystem.forwardVelocity = xrot;
vr.vrSystem.rotationalVelocity = zrot;

% MAP BALL ROTATION TO CARTESIAN MOVEMENT RELATIVE TO MOUSE (squeaky mouse)
vM.x = -yrot*xscale;            % side-stepping
vM.y = xrot*yscale;             % forwards/backwards movement
vM.z = 0;
vM.omega = -zrot*omegascale;    % twisting the ball
velocity = [vM.x vM.y vM.z vM.omega]; % relative to mouse
vr.vrSystem.rawVelocity(3,:) = [vM.x vM.y vM.z vM.omega];


% MAP MOUSE-RELATIVE MOVEMENT TO MOVEMENT IN VIRTUAL WORLD (rotate velocity vector)
vrOmega = vr.position(4);
velocity(1:2) = [cos(vrOmega) -sin(vrOmega); sin(vrOmega) cos(vrOmega)]*velocity(1:2)';
vr.vrSystem.rawVelocity(4,:) = velocity;

% 'LOW-PASS' FILTER VELOCITY BY DAMPENING WITH PREVIOUS VALUES
velocity = sum([velocity ; velocityBuffer(1:end-1,:)],1);
velocityBuffer = [velocity/lowPassLength ; velocityBuffer(1:end-1,:)*.99];
vr.vrSystem.rawVelocity(5,:) = velocity;




