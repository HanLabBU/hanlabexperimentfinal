function code = jiaming
% jiaming   Code for the ViRMEn experiment jiaming.
%   code = jiaming   Returns handles to the functions that ViRMEn
%   executes during engine initialization, runtime and termination.


% Begin header code - DO NOT EDIT
code.initialization = @initializationCodeFun;
code.runtime = @runtimeCodeFun;
code.termination = @terminationCodeFun;
% End header code - DO NOT EDIT







% --- INITIALIZATION code: executes before the ViRMEn engine starts.
function vr = initializationCodeFun(vr)
%% MOVE WINDOW ONTO PROJECTOR SCREEN (will need to be changed for different set ups)
	vr.window.TopMost = false;
	vr.window.WindowState = System.Windows.Forms.FormWindowState.Normal;
	% screen sizes and setups)

%% SET VARIABLES AND TRIANGLES FOR THE TARGETS
%disappearing
w = vr.worlds{vr.currentWorld};

%set NE target triangles
vr.NWIndx = w.objects.indices.NWtarget;
NWvertexFirstLast = vr.worlds{vr.currentWorld}.objects.vertices(vr.NWIndx,:);
vr.NWConeIndx = w.objects.indices.NWcone;
NWConeVertexFirstLast = vr.worlds{vr.currentWorld}.objects.vertices(vr.NWConeIndx,:);
vr.NWtargetIndx = [NWvertexFirstLast(1):NWvertexFirstLast(2) NWConeVertexFirstLast(1):NWConeVertexFirstLast(2)];

%set SW target triangles
vr.SWIndx = w.objects.indices.SWtarget;
SWvertexFirstLast = vr.worlds{vr.currentWorld}.objects.vertices(vr.SWIndx,:);
vr.SWConeIndx = w.objects.indices.SWcone;
SWConeVertexFirstLast = vr.worlds{vr.currentWorld}.objects.vertices(vr.SWConeIndx,:);
vr.SWtargetIndx = [SWvertexFirstLast(1):SWvertexFirstLast(2) SWConeVertexFirstLast(1):SWConeVertexFirstLast(2)];

%set NE target triangles
vr.NEIndx = w.objects.indices.NEtarget;
NEvertexFirstLast = vr.worlds{vr.currentWorld}.objects.vertices(vr.NEIndx,:);
vr.NEConeIndx = w.objects.indices.NEcone;
NEConeVertexFirstLast = vr.worlds{vr.currentWorld}.objects.vertices(vr.NEConeIndx,:);
vr.NEtargetIndx = [NEvertexFirstLast(1):NEvertexFirstLast(2) NEConeVertexFirstLast(1):NEConeVertexFirstLast(2)];

%set SE target triangles
vr.SEIndx = w.objects.indices.SEtarget;
SEvertexFirstLast = vr.worlds{vr.currentWorld}.objects.vertices(vr.SEIndx,:);
vr.SEConeIndx = w.objects.indices.SEcone;
SEConeVertexFirstLast = vr.worlds{vr.currentWorld}.objects.vertices(vr.SEConeIndx,:);
vr.SEtargetIndx = [SEvertexFirstLast(1):SEvertexFirstLast(2) SEConeVertexFirstLast(1):SEConeVertexFirstLast(2)];

%original color for reset
vr.originalColor = w.surface.colors(2,vr.NWtargetIndx);

%start visible
vr.worlds{vr.currentWorld}.surface.colors(4,vr.NEtargetIndx) = 1;
vr.worlds{vr.currentWorld}.surface.colors(4,vr.SEtargetIndx) = 0;
vr.worlds{vr.currentWorld}.surface.colors(4,vr.NWtargetIndx) = 0;
vr.worlds{vr.currentWorld}.surface.colors(4,vr.SWtargetIndx) = 0;

%randomization indx
vr.allTargets = {vr.NEtargetIndx, vr.NWtargetIndx, vr.SEtargetIndx, vr.SWtargetIndx};
vr.randTarget = [];
vr.randCone = [];

%% ATTEMPT TO CLEAR ANY PREVIOUS HARDWARE CONNECTIONS
daq.reset
instrreset
fclose('all');
 
%% AUTOMATIC FILE NAMING

try %data recording/file saving

disp('Initializing...')
% Data recording interfaces (and File Naming)
persistent instancenum
	if isempty(instancenum)
		instancenum = 1;
	else
		instancenum = instancenum+1;
	end
	global CURRENT_EXPERIMENT_NAME
	if isempty(CURRENT_EXPERIMENT_NAME)
		CURRENT_EXPERIMENT_NAME = sprintf('MOUSE99_%g',instancenum);
	else
		expNameRoot = strtok(CURRENT_EXPERIMENT_NAME,'_');
		CURRENT_EXPERIMENT_NAME = sprintf('%s_%g',expNameRoot,instancenum);
	end
name = inputdlg('Name this experiment, please','Experiment Name',1,{CURRENT_EXPERIMENT_NAME});
name = name{1};
CURRENT_EXPERIMENT_NAME = name;
catch me 
	disp(me.message)
	disp(me.stack(1))
end

%% VRSYSTEM FOR DATA SAVING AND MOVEMENT INTERFACE
try
vr.vrSystem = VrSystem(...
	'rewardCondition','true',...
	'autoSyncTrialTime', 30,... % was 'autoSyncTrialTime', autoSyncTrialTime,
	'currentExperimentName',name);
% Set VrSystem('rewardCondition') to false so reward can be handled in the runtimeCodeFunction
vr.vrSystem.rewardCondition = 'obj.distanceFromTarget < 0';

% Enable Experiment and Trial State Listeners
vr.vrSystem.start();  
fprintf('VrSystem intialized\n');

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

catch me
disp(me.message)
disp(me.stack(1))
end

%% REWARD CONDITIONS
try
	%Set Reward Condition using Distance from Target
	vr.floor_width = eval(vr.exper.variables.floor_width);
	vr.ceiling_height = eval(vr.exper.variables.ceiling_height);
	vr.target_size = (eval(vr.exper.variables.target_size));
	%target locations
	vr.target.location.NE = [vr.exper.worlds{1}.objects{7}.x; vr.exper.worlds{1}.objects{7}.y];
	vr.target.location.SE = [vr.exper.worlds{1}.objects{13}.x; vr.exper.worlds{1}.objects{13}.y];
	vr.target.location.NW = [vr.exper.worlds{1}.objects{8}.x; vr.exper.worlds{1}.objects{8}.y];
	vr.target.location.SW = [vr.exper.worlds{1}.objects{11}.x; vr.exper.worlds{1}.objects{11}.y];
	%Cartesian Distance?
	vr.target.cartesianDistFromTarget.NE = vr.target.location.NE(:)'-vr.position(1:2);
	vr.target.cartesianDistFromTarget.SE = vr.target.location.SE(:)'-vr.position(1:2);
	vr.target.cartesianDistFromTarget.NW = vr.target.location.NW(:)'-vr.position(1:2);
	vr.target.cartesianDistFromTarget.SW = vr.target.location.SW(:)'-vr.position(1:2);
	%hypot
	vr.target.distFromTargetCenter.NE...
		= hypot(vr.target.cartesianDistFromTarget.NE(1), vr.target.cartesianDistFromTarget.NE(2));
	vr.target.distFromTargetCenter.SE...
		= hypot(vr.target.cartesianDistFromTarget.SE(1), vr.target.cartesianDistFromTarget.SE(2));
	vr.target.distFromTargetCenter.NW...
		= hypot(vr.target.cartesianDistFromTarget.NW(1), vr.target.cartesianDistFromTarget.NW(2));
	vr.target.distFromTargetCenter.SW ...
		= hypot(vr.target.cartesianDistFromTarget.SW(1), vr.target.cartesianDistFromTarget.SW(2));
	%set threshold
	vr.target.threshold = eval(vr.exper.variables.target_size);
	vr.target.initialDistance = 1000;
	%i dont even know
	vr.vrSystem.distanceFromTarget.NE = vr.target.initialDistance;
	vr.vrSystem.distanceFromTarget.SE = 1000;
	vr.vrSystem.distanceFromTarget.NW = 1000;
	vr.vrSystem.distanceFromTarget.SW = 1000;
	
	vr.vrSystem.numRewardsGiven = 0;

	vr.eligible = false;

	vr.inTarget.NE = false;
	vr.inTarget.SE = false;
	vr.inTarget.NW = false;
	vr.inTarget.SW = false;

	vr.vrSystem.numRewardsGiven = 0;
	vr.vrSystem.rewardCondition = 'obj.distanceFromTarget < 0';
catch me
	disp(me.message)
	disp(me.stack(1))
end





% --- RUNTIME code: executes on every iteration of the ViRMEn engine.
function vr = runtimeCodeFun(vr)

%% TRIAL TIME?
persistent trailTime 
trialTime = hat;

%% INIFINITE LOOP SAFETY COUNTER
a = 0;

%% UPDATE DISTANCE FROM TARGET
try
vr.target.threshold = eval(vr.exper.variables.target_size);
targets = fields(vr.vrSystem.distanceFromTarget);
targetNumbers = struct(...
    'NE',7,...
    'SE',13,...
    'NW',8,...
    'SW',11);
for k = 1:numel(targets)
    targetName = targets{k};
    targetNum = targetNumbers.(targetName);
    targetLocation = ...
        [vr.exper.worlds{1}.objects{targetNum}.x; vr.exper.worlds{1}.objects{targetNum}.y];
    vr.target.cartesianDistFromTarget.(targetName) = ...
        targetLocation(:)' - vr.position(1:2);
    cDFT = vr.target.cartesianDistFromTarget.(targetName);
    vr.target.distFromTargetCenter.(targetName) = ...
        hypot(cDFT(1),cDFT(2));
    vr.vrSystem.distanceFromTarget.(targetName) = ...
        vr.target.distFromTargetCenter.(targetName) - vr.target.threshold;
    
end

%% DISPLAY DISTANCES FROM TARGETS (OFF)
persistent downCounter
if isempty(downCounter)
    downCounter = 100;
end
if downCounter <= 0
%     fprintf('NE:%f\nSE:%f\nNW:%f\nSW:\n\n',...
fprintf('%f %f %f %f\n',...
        vr.vrSystem.distanceFromTarget.NE,...
        vr.vrSystem.distanceFromTarget.SE,...
        vr.vrSystem.distanceFromTarget.NW,...
        vr.vrSystem.distanceFromTarget.SW)
    downCounter = 300;
else
    downCounter = downCounter -1;
end
catch me
    disp(me.message)
    disp(stack(1))
   
end

%% REWARD FOR FORWARD PROGRESS
% if vr.vrSystem.forwardVelocity>100 && rand<.01
% 	vr.vrSystem.rewardPulseObj.sendPulse(.025);
% 	vr.vrSystem.numRewardsGiven = vr.vrSystem.numRewardsGiven + .0249999;
% end

%% REWARD ELIGIBLE 
if vr.eligible == true
    vr.vrSystem.rewardCondition = 'obj.distanceFromTarget<0';
    vr.vrSystem.rewardsGiven = vr.vrSystem.rewardsGiven + 1;
    vr.eligible = false;
    %      notify(vr.vrSystem, 'FrameAcquired',vrMsg(vr))
	vr.vrSystem.rewardPulseObj.sendPulse();
else 
            vr.vrSystem.rewardCondition = false; %prevent multiple rewards
end

%% NE TARGET
try %NE target
    %change color when steps on
    if (vr.vrSystem.distanceFromTarget.NE < 0)&(vr.worlds{vr.currentWorld}.surface.colors(4,vr.NEtargetIndx) == 1)%indicates distance From target fell below threshold
        vr.inTarget.NE = true;
        vr.worlds{vr.currentWorld}.surface.colors(2,vr.NEtargetIndx) = 1;
        vr.eligible = true;
%         disp('NE true')
%         disp([num2str(vr.target.threshold) 'threshold'])
    end
   
%% RESET COLOR AND RANDOM NEXT TARGET
       if (vr.vrSystem.distanceFromTarget.NE > 0)&(vr.inTarget.NE == true)
            vr.worlds{vr.currentWorld}.surface.colors(4,vr.NEtargetIndx) = 0;
            %vr.worlds{vr.currentWorld}.surface.colors(4,vr.NEConeIndx) = 0;
            vr.worlds{vr.currentWorld}.surface.colors(2,vr.NEtargetIndx) = vr.originalColor;
            
             %randomize next target
            vr.allTargets(1) = {[]};
			vr.randTarget = vr.allTargets{ceil(rand*4)};
            while isempty(vr.randTarget)
                vr.randTarget = vr.allTargets{ceil(rand*4)};
                a = a+1;
                 if a>10
                    break
                end
            end
%             disp(vr.allTargets)
            vr.worlds{vr.currentWorld}.surface.colors(4,vr.randTarget) = 1;
            vr.vrSystem.numRewardsGiven = vr.vrSystem.numRewardsGiven + 1;
            %pond stuff
            vr.inTarget.NE = false;
            vr.vrSystem.distanceFromTarget.NE = vr.target.initialDistance;
       end
    %      notify(vr.vrSystem, 'FrameAcquired',vrMsg(vr))
catch me
     disp(me.message)
     disp (me.stack(1))
    %      dbstop2
end

%% NW TARGET
try %NW target
    %change color when steps on
    if (vr.vrSystem.distanceFromTarget.NW < 0)&(vr.worlds{vr.currentWorld}.surface.colors(4,vr.NWtargetIndx) == 1)%indicates distance From target fell below threshold
        vr.inTarget.NW = true;
        vr.worlds{vr.currentWorld}.surface.colors(2,vr.NWtargetIndx) = 1;
         vr.eligible = true;
%         disp('NW true')
%         disp([num2str(vr.target.threshold) 'threshold'])
    end
   
%% RESET TARGET COLOR AND RANDOM NEXT TARGET
       if (vr.vrSystem.distanceFromTarget.NW > 0)&(vr.inTarget.NW == true)
            vr.worlds{vr.currentWorld}.surface.colors(4,vr.NWtargetIndx) = 0;
            %vr.worlds{vr.currentWorld}.surface.colors(4,vr.NWConeIndx) = 0;
            vr.worlds{vr.currentWorld}.surface.colors(2,vr.NWtargetIndx) = vr.originalColor;
            
            %randomize next target
            vr.allTargets(2) = {[]};
            vr.randTarget = vr.allTargets{ceil(rand*4)};
            while isempty(vr.randTarget)
                vr.randTarget = vr.allTargets{ceil(rand*4)};
                a = a + 1;
                 if a>10
                    break
                end
            end
%             disp(length(vr.randTarget))
            vr.worlds{vr.currentWorld}.surface.colors(4,vr.randTarget) = 1;
            vr.vrSystem.numRewardsGiven = vr.vrSystem.numRewardsGiven + 1;
            %pond stuff
            vr.inTarget.NW = false;
            vr.vrSystem.distanceFromTarget.NW = vr.target.initialDistance; 
       end
    %      notify(vr.vrSystem, 'FrameAcquired',vrMsg(vr))
catch me
     disp(me.message)
     disp (me.stack(1))
end

%% SW TARGET
try %SW target
    %change color when steps on
    if (vr.vrSystem.distanceFromTarget.SW < 0)...
            &(vr.worlds{vr.currentWorld}.surface.colors(4,vr.SWtargetIndx) == 1)
            %indicates distance From target fell below threshold
        vr.eligible = true;
        vr.inTarget.SW = true;
        vr.worlds{vr.currentWorld}.surface.colors(2,vr.SWtargetIndx) = 1;
       
%         disp('SW true')
%         disp([num2str(vr.target.threshold) 'threshold'])
    end
   
%% RESET COLOR AND RANDOMIZE NEXT
       if (vr.vrSystem.distanceFromTarget.SW > 0)&(vr.inTarget.SW == true)
            vr.worlds{vr.currentWorld}.surface.colors(4,vr.SWtargetIndx) = 0;
            %vr.worlds{vr.currentWorld}.surface.colors(4,vr.SWConeIndx) = 0;
            vr.worlds{vr.currentWorld}.surface.colors(2,vr.SWtargetIndx) = vr.originalColor;
            
            %randomize next target
            vr.allTargets(4) = {[]};
%             disp(vr.allTargets)
            vr.randTarget = vr.allTargets{ceil(rand*4)};
            while isempty(vr.randTarget) %if it chooses a target that has already been used 
                vr.randTarget = vr.allTargets{ceil(rand*4)};
                a = a+1;
                 if a>10
                    break
                end
            end
%             disp(length(vr.randTarget))
            vr.worlds{vr.currentWorld}.surface.colors(4,vr.randTarget) = 1;
            vr.vrSystem.numRewardsGiven = vr.vrSystem.numRewardsGiven + 1;
            %pond stuff
            vr.inTarget.SW = false;
            vr.vrSystem.distanceFromTarget.SW = vr.target.initialDistance;
       end
       
    %      notify(vr.vrSystem, 'FrameAcquired',vrMsg(vr))
catch me
     disp(me.message)
     disp (me.stack(1))
    %      dbstop2
end

%% SE TARGET
try %SE target
    %change color when steps on
    if (vr.vrSystem.distanceFromTarget.SE < 0)...
            &(vr.worlds{vr.currentWorld}.surface.colors(4,vr.SEtargetIndx) == 1)
            %indicates distance From target fell below threshold
        vr.eligible = true;
        vr.inTarget.SE = true;
        vr.worlds{vr.currentWorld}.surface.colors(2,vr.SEtargetIndx) = 1;
%         disp('SE true')
%         disp([num2str(vr.target.threshold) 'threshold'])
    end
   
%% COLOR RESET RANDOMIZE NEXT TARGET
       if (vr.vrSystem.distanceFromTarget.SE > 0)&(vr.inTarget.SE == true)
            vr.worlds{vr.currentWorld}.surface.colors(4,vr.SEtargetIndx) = 0;
            %vr.worlds{vr.currentWorld}.surface.colors(4,vr.SEConeIndx) = 0;
            vr.worlds{vr.currentWorld}.surface.colors(2,vr.SEtargetIndx) = vr.originalColor;
            
            %randomize next target
            vr.allTargets(3) = {[]};
            vr.randTarget = vr.allTargets{ceil(rand*4)};
            while isempty(vr.randTarget)
                vr.randTarget = vr.allTargets{ceil(rand*4)};
                a = a+1;
                if a>10
                    break
                end
            end
%             disp(length(vr.randTarget))
            vr.worlds{vr.currentWorld}.surface.colors(4,vr.randTarget) = 1;
            vr.vrSystem.numRewardsGiven = vr.vrSystem.numRewardsGiven + 1;
            %pond stuff
            vr.inTarget.SE = false;
            vr.vrSystem.distanceFromTarget.SE = vr.target.initialDistance;
       end
    %      notify(vr.vrSystem, 'FrameAcquired',vrMsg(vr))
catch me
     disp(me.message)
     disp (me.stack(1))
    
end 

%% TRIAL RESET
try %when all targets have been hit
    while (isempty (vr.allTargets{1}))&&(isempty (vr.allTargets{2}))...
                &&(isempty (vr.allTargets{3}))&&...
                (isempty (vr.allTargets{4}))
            disp(vr.allTargets)
            vr.allTargets = {vr.NEtargetIndx, vr.NWtargetIndx, vr.SEtargetIndx, vr.SWtargetIndx};
            disp('reset')
        while isempty(vr.randTarget)
            vr.randTarget = vr.allTargets{ceil(rand*4)};
            a = a+1;
            if a>20
                break
            end
        end
        vr.worlds{vr.currentWorld}.surface.colors(4,vr.randTarget) = 1;
        ask Mark how to reset trial
        disp ([ 'Trail Time (unsaved for right now) ' num2string(trailTime)])
        trialTime = 0;
    end
catch me
    disp(me.message)
    disp (me.stack(1))
end

%% IF RANDOMIZATION DOESN'T WORK (1/10000000000 chance)
if  isempty(vr.randTarget)
	vr.randTarget = vr.NEtargetIndx;
	vr.worlds{vr.currentWorld}.surface.colors(4,vr.randTarget) = 1;
end

%% NOTIFY VRSYSTEM TO SAVE DATA
try
	notify(vr.vrSystem,'FrameAcquired',vrMsg(vr))
catch me	
end






% --- TERMINATION code: executes after the ViRMEn engine stops.
function vr = terminationCodeFun(vr)
disp(vr.vrSystem.numRewardsGiven)



















