function code = BlanderRodeo
% BlanderRodeo   Code for the ViRMEn experiment BlanderRodeo.
%   code = BlanderRodeo   Returns handles to the functions that ViRMEn
%   executes during engine initialization, runtime and termination.


% Begin header code - DO NOT EDIT
code.initialization = @initializationCodeFun;
code.runtime = @runtimeCodeFun;
code.termination = @terminationCodeFun;
% End header code - DO NOT EDIT




% --- INITIALIZATION code: executes before the ViRMEn engine starts.
function vr = initializationCodeFun(vr)
try
	%% MOVE WINDOW ONTO PROJECTOR SCREEN (will need to be changed for different
	% screen sizes and setups)
	vr.window.TopMost = false;
	vr.window.WindowState = System.Windows.Forms.FormWindowState.Normal;
	
	%% SETUP VARIABLES FOR "BLAND"-RODEO
	w = vr.worlds{vr.currentWorld};
	%set triangles
	vr.PWallIndx = 26:33; %indices of Purple walls, may change if world altered
	vr.PBallIndx = w.objects.indices.PurpleBall;
	ElectricVertices = w.objects.vertices(vr.PWallIndx, :);
	PurpleBallIndices = w.objects.vertices(vr.PBallIndx, :);
	vr.PTargetVertices = [min(ElectricVertices):max(ElectricVertices) PurpleBallIndices(1):PurpleBallIndices(2)];
	vr.PTargetIndx = [26:33 34];
	
	vr.GWallIndx = 18:25 ;%indices of green walls, may change if world altered
	vr.GBallIndx = w.objects.indices.GreenBall;
	DotVertices = w.objects.vertices(vr.GWallIndx, :);
	GreenBallIndices = w.objects.vertices(vr.GBallIndx, :);
	vr.GTargetVertices = [min(DotVertices):max(DotVertices) GreenBallIndices(1):GreenBallIndices(2)];
	vr.GTargetIndx = [18:25 35];
	
	%original Colors
	vr.originalColor.P = w.surface.colors(2, vr.PTargetVertices);
	vr.originalColor.G = w.surface.colors(3,vr.GTargetVertices);
	
	%% REWARD CONDITIONS USING DISTANCE FROM TARGET
	%target Locations
	vr.target.location.G = [vr.exper.worlds{1}.objects{34}.x; vr.exper.worlds{1}.objects{34}.y];
	vr.target.location.P = [vr.exper.worlds{1}.objects{35}.x'; vr.exper.worlds{1}.objects{35}.y'];
	%Cartesian Distance from the Target
	vr.target.cDFT.G = [vr.target.location.G(1)' - vr.position(1:2);...
		vr.target.location.G(2)' - vr.position(1:2);...
		vr.target.location.G(3)' - vr.position(1:2);...
		vr.target.location.G(4)' - vr.position(1:2)];
	vr.target.cDFT.P = [vr.target.location.P(1)' - vr.position(1:2);...
		vr.target.location.P(2)' - vr.position(1:2);...
		vr.target.location.P(3)' - vr.position(1:2);...
		vr.target.location.P(4)' - vr.position(1:2)];
	%calculate the hypotenuse
	vr.target.distFromTargetCenter.G = hypot(vr.target.cDFT.G(:,1), vr.target.cDFT.G(:,2));
	vr.target.distFromTargetCenter.P = hypot(vr.target.cDFT.P(:,1), vr.target.cDFT.P(:,2));
	%threshold
	vr.target.threshold = eval(vr.exper.variables.ceilingHeight)/2;
	%initial Distance
	vr.target.initialDistance = vr.target.threshold*5;
	vr.vrSystem.distanceFromTarget.P = vr.target.initialDistance;
	vr.vrSystem.distanceFromTarget.G = vr.target.initialDistance;
	%rewards
	vr.vrSystem.numRewardsGiven = 0;
	vr.vrSystem.rewardCondition = 'obj.distanceFromTarget < 0';
	vr.eligible = false;
	
	vr.inTarget.G = false;
	vr.inTarget.P = false;
	
	vr.targetOn.G = false;
	vr.targetOn.P = true;
	
	vr.colorChange.G = false;
	vr.colorChange.P = false;
		
	%% ATTEMPT TO CLEAR ANY PREVIOUS HARDWARE CONNECTIONS
	daq.reset
	instrreset
	fclose('all');
	
	%% AUTOMATIC FILE NAMING
	disp('Initializing...')
	% Data recording interfaces (and File Naming)
	persistent instancenum
	if isempty(instancenum)
		instancenum = 1;
	else
		instancenum = instancenum+1;
	end
	global CURRENT_EXPERIMENT_NAME
	global CURRENT_EXPERIMENT_PATH
	if isempty(CURRENT_EXPERIMENT_NAME)
		CURRENT_EXPERIMENT_NAME = sprintf('RODEO_%g',instancenum);
	else
		expNameRoot = strtok(CURRENT_EXPERIMENT_NAME,'_');
		CURRENT_EXPERIMENT_NAME = sprintf('%s_%g',expNameRoot,instancenum);
	end
	name = inputdlg('Name this experiment, please','Experiment Name',1,{CURRENT_EXPERIMENT_NAME});
	name = name{1};
	CURRENT_EXPERIMENT_NAME = name;
	
	%% VRSYSTEM FOR DATA SAVING AND MOVEMENT INTERFACE
	vr.vrSystem = VrSystem(...
		'rewardCondition','true',...
		'autoSyncTrialTime',30,...
		'currentExperimentName',name);
	% Set VrSystem('rewardCondition') to false so reward can be handled in the runtimeCodeFunction
	vr.vrSystem.rewardCondition = 'false';
	
	% Enable Experiment and Trial State Listeners
	vr.vrSystem.start();
	fprintf('VrSystem initialized\n');
	
	% Movement interface
	vr.movementInterface = VrMovementInterface;
	vr.movementInterface.start();
	
	% Initialize RAW VELOCITY for recording direct optical sensor input
	vr.vrSystem.rawVelocity = zeros(5,4);
	vr.vrSystem.forwardVelocity = 0;
	
	% Begin data-recording systems
	fprintf('Sending ExperimentStart notification...\n');
	notify(vr.vrSystem,'ExperimentStart');
	
	
	win = vr.window;
	ogl = vr.oglControl;
	assignin('base','win',win);
	assignin('base','ogl',ogl);
	assignin('base','vr',vr);
catch me
	disp(me.message)
	disp(me.stack(1))
end







% --- RUNTIME code: executes on every iteration of the ViRMEn engine.
function vr = runtimeCodeFun(vr)

%% REWARD FOR FORWARD PROGRESS
if vr.vrSystem.forwardVelocity>100 && rand<.01
	vr.vrSystem.rewardPulseObj.sendPulse(.025);
	vr.vrSystem.numRewardsGiven = vr.vrSystem.numRewardsGiven + .0249999;
end
%% UPDATE DISTANCE TO TARGET
try
	%target Locations
	vr.target.location.G = [vr.exper.worlds{1}.objects{34}.x'; vr.exper.worlds{1}.objects{34}.y'];
	vr.target.location.P = [vr.exper.worlds{1}.objects{35}.x'; vr.exper.worlds{1}.objects{35}.y'];
	%Cartesian Distance from the Target
	vr.target.cDFT.G = [...
		vr.target.location.G(:,1)' - vr.position(1:2);...
		vr.target.location.G(:,2)' - vr.position(1:2);...
		vr.target.location.G(:,3)' - vr.position(1:2);...
		vr.target.location.G(:,4)' - vr.position(1:2)];
	vr.target.cDFT.P = [...
		vr.target.location.P(:,1)' - vr.position(1:2);...
		vr.target.location.P(:,2)' - vr.position(1:2);...
		vr.target.location.P(:,3)' - vr.position(1:2);...
		vr.target.location.P(:,4)' - vr.position(1:2)];
	%calculate the hypotenuse
	vr.target.distFromTargetCenter.G = hypot(vr.target.cDFT.G(:,1), vr.target.cDFT.G(:,2));
	vr.target.distFromTargetCenter.P = hypot(vr.target.cDFT.P(:,1), vr.target.cDFT.P(:,2));
	%threshold
	vr.target.threshold = eval(vr.exper.variables.ceilingHeight)/2;
	%distance from Target
	vr.vrSystem.distanceFromTarget.P = ...
		vr.target.distFromTargetCenter.P(:) - vr.target.threshold;
	vr.vrSystem.distanceFromTarget.G = ...
		vr.target.distFromTargetCenter.G(:) - vr.target.threshold;
	% 	assignin('base','vr',vr)
catch me
	disp(me.message)
	disp(me.stack(1))
end
%% DIST FROM TARGET CENTER
persistent downCounter
if isempty(downCounter)
	downCounter = 200;
end
if downCounter <= 0
	%     fprintf('NE:%f\nSE:%f\nNW:%f\nSW:\n\n',...
% 	fprintf('Puple distance: %f\nGreen distance: %f\ncDFT: \n',...
% 		vr.target.distFromTargetCenter.P,...
% 		vr.target.distFromTargetCenter.G,...
% 		vr.target.cDFT.P)
	downCounter = 200;
else
	downCounter = downCounter -1;
end
%% REWARD ELIGIBLE
if vr.eligible == true
	vr.vrSystem.rewardCondition = 'obj.distanceFromTarget<0';
	vr.vrSystem.numRewardsGiven = vr.vrSystem.numRewardsGiven + 1;
	vr.eligible = false;
	disp('The animal recieved a reward!!')
	disp(['The total amount of rewards received is ' ...
		num2str(vr.vrSystem.numRewardsGiven)])
else
	vr.vrSystem.rewardCondition = 'false'; %prevent multiple rewards
end
 %% MOUSE INSIDE TARGET AREA
try
	%purple
	if (any(vr.vrSystem.distanceFromTarget.P < 0))&(vr.targetOn.P == true)
		vr.worlds{vr.currentWorld}.surface.colors(2,vr.PTargetVertices) = 0;
		if vr.colorChange.P == false
			vr.eligible = true;
		else
			vr.eligible = false;
		end
		vr.targetOn.P = false;
		vr.targetOn.G = true;
		vr.colorChange.P = true;
		disp(vr.colorChange.P)
	end
	%green
	if (any(vr.vrSystem.distanceFromTarget.G < 0) == true)&(vr.targetOn.G == true)
		vr.worlds{vr.currentWorld}.surface.colors(3,vr.GTargetVertices) = 0;
		vr.targetOn.G = false;
		vr.targetOn.P = true;
		disp('OH MY GOD')
		%        if vr.colorChange.G == false
		%             vr.eligible = true;
		%        else
		%            vr.eligible = false;
		%        end
		vr.colorChange.G = true;
% 		vr.experimentEnded =true;
	end
catch me
	disp(me.message)
	disp(me.stack(1))
end
%% COLOR RESET
try
	if (vr.vrSystem.distanceFromTarget.P>0)
		%disp('YEA BUDDY')
% 		disp(vr.colorChange.P)
		if (vr.colorChange.P == true)
			vr.colorChange.P = false;
			assignin('base','vr',vr)
			vr.worlds{vr.currentWorld}.surface.colors(2,vr.PTargetVertices) = vr.originalColor.P;
		elseif vr.colorChange.G == true
			vr.colorChange.G = false;
			vr.worlds{vr.currentWorld}.surface.colors(3,vr.GTargetVertices) = vr.originalColor.G;
		end
	end
catch me
	disp(me.message)
	disp(me.stack(1))
end
%% NOTIFY VRSYSTEM TO SAVE DATA
try
	notify(vr.vrSystem,'FrameAcquired',vrMsg(vr))
catch me	
end










% --- TERMINATION code: executes after the ViRMEn engine stops.
function vr = terminationCodeFun(vr)
try
	vr.vrSystem.saveDataFile;
	vr.vrSystem.saveDataSet;
	fclose('all')
	disp(vr.vrSystem.numRewardsGiven)
catch me
	instrreset
end























