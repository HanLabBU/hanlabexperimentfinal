function velocity = moveMike(vr)
% try

% DEFINE SCALING CONSTANTS
lowPassLength = 5;             % changed from 60 to 30 on 1/19/2014
omegascale = .002/lowPassLength; % changed from .15
xscale = .02/lowPassLength; % changed from .25
yscale = .03/lowPassLength; %previously .9
persistent velocityBuffer;
if isempty(velocityBuffer)
	velocityBuffer = zeros(lowPassLength,4);
end

% NEW +++++  READING FROM DX (DIVIDED BY TIME)
% READ X,Y FROM SENSOR INTERFACES
if ~isfield(vr,'movementInterface')
	vr.movementInterface = VrMovementInterface;
	vr.movementInterface.start();
end


leftX = vr.movementInterface.mouse1.dx;
leftY = vr.movementInterface.mouse1.dy;
rightX = vr.movementInterface.mouse2.dx;
rightY = vr.movementInterface.mouse2.dy;
vr.vrSystem.rawVelocity(1,:) = [leftX, leftY, rightX, rightY];
vr.movementInterface.mouse1.dx = 0;
vr.movementInterface.mouse1.dy = 0;
vr.movementInterface.mouse2.dx = 0;
vr.movementInterface.mouse2.dy = 0;
velocity = [0 0 0 0];