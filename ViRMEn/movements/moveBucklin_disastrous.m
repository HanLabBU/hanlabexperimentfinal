function velocity = moveBucklin (vr)

% DEFINE SCALING CONSTANTS
lowPassLength = 60; 
omegascale = .001; % changed from .3
xscale = .01; % changed from .25
yscale = .0001; %previously .9
zeroCountTolerance = 5;

% PERSISTENT VARIABLES
persistent previousVelocity
if isempty(previousVelocity)
    previousVelocity = [0 0 0 0];
end
persistent zeroCount
if isempty(zeroCount)
    zeroCount = 0;
end
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

% IF ALL SENSOR READINGS ARE ZERO WE PROJECT PREVIOUS VELOCITY (GAP)
if ~any([leftX, leftY, rightX, rightY])
    zeroCount = zeroCount + 1;
    if zeroCount <= zeroCountTolerance
        velocity = previousVelocity;
    else
        velocity = previousVelocity/2;
        velocityBuffer = velocityBuffer.*((zeroCountTolerance-1)/zeroCountTolerance);
    end
    return
end
% OTHERWISE GO ON TO COMPUTE VELOCITY IN WORLD-REFERENCE FROM SENSOR INPUT


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
velocity = .5*velocity/zeroCount + .45*mean(velocityBuffer,1);
previousVelocity = velocity;
velocityBuffer = [velocity ; velocityBuffer(1:end-1,:)];
vr.vrSystem.rawVelocity(5,:) = velocity;

zeroCount = 0;






