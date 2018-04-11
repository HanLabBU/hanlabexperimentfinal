function code = bidirectional
% unidirectional   Code for the ViRMEn experiment unidirectional.
%   code = unidirectional   Returns handles to the functions that ViRMEn
%   executes during engine initialization, runtime and termination.


% Begin header code - DO NOT EDIT
code.initialization = @initializationCodeFun;
code.runtime = @runtimeCodeFun;
code.termination = @terminationCodeFun;
% End header code - DO NOT EDIT



% --- INITIALIZATION code: executes before the ViRMEn engine starts.
function vr = initializationCodeFun(vr)

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

%% VRSYTEM FOR DATA SAVING AND MOVEMENT INTERFACE
% try
vr.vrSystem = VrSystem(...
	'rewardCondition','true', 'currentExperimentName',name);
% 	'autoSyncTrialTime',autoSyncTrialTime,..

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

% catch me
%     disp(me.message)
%     disp(me.stack(1))
% end

%% MOVE WINDOW ONTO PROJECTOR SCREEN (will need to be changed for different set up)
vr.window.TopMost = false;
	vr.window.WindowState = System.Windows.Forms.FormWindowState.Normal;
	% screen sizes and setups)


vr.vrSystem.rawVelocity = zeros(5,4);
vr.vrSystem.forwardVelocity = 0;
% fprintf('Sending ExperimentStart notification...\n');
% notify(vr.vrSystem,'ExperimentStart');
assignin('base','vr',vr)

%% SET UP VARIABLES
try %target color change setup
    w = vr.worlds{vr.currentWorld};
    
    %N target triangles
vr.Nindx = w.objects.indices.Ntarget;
NvertexFirstLast = vr.worlds{vr.currentWorld}.objects.vertices(vr.Nindx,:);
%walls
vr.NWwallIndx = w.objects.indices.NWtargetWall;
NWvertexFirstLast = vr.worlds{vr.currentWorld}.objects.vertices(vr.NWwallIndx,:);
vr.NEwallIndx = w.objects.indices.NEtargetWall;
NEvertexFirstLast = vr.worlds{vr.currentWorld}.objects.vertices(vr.NEwallIndx,:);

 vr.target.N.indx = [NvertexFirstLast(1):NvertexFirstLast(2) NWvertexFirstLast(1):NWvertexFirstLast(2) NEvertexFirstLast(1):NEvertexFirstLast(2)];
 
     %S target triangles
vr.Sindx = w.objects.indices.Starget;
SvertexFirstLast = vr.worlds{vr.currentWorld}.objects.vertices(vr.Sindx,:);
%walls
vr.SWwallIndx = w.objects.indices.SWtargetWall;
SWvertexFirstLast = vr.worlds{vr.currentWorld}.objects.vertices(vr.SWwallIndx,:);
vr.SEwallIndx = w.objects.indices.SEtargetWall;
SEvertexFirstLast = vr.worlds{vr.currentWorld}.objects.vertices(vr.SEwallIndx,:);

 vr.target.S.indx = [ SvertexFirstLast(1):SvertexFirstLast(2) SWvertexFirstLast(1):SWvertexFirstLast(2) SEvertexFirstLast(1):SEvertexFirstLast(2)];
 
catch me 
    disp(me.message)
    disp(me.stack(1))
end
 
 vr.originalColor.N = w.surface.colors(3,vr.target.N.indx);
 vr.originalColor.S = vr.worlds{vr.currentWorld}.surface.colors(2,vr.target.S.indx);
 
%% REWARD CONDITIONS
vr.eligible = false;
vr.vrSystem.numRewardsGiven = 0;
vr.target.N.on = true;
vr.target.S.on = false;
vr.colorChange.N = false;
vr.colorChange.S = false;
vr.vrSystem.rewardCondition = 'obj.distanceFromTarget < 0';
vr.delay = false;







% --- RUNTIME code: executes on every iteration of the ViRMEn engine.
function vr = runtimeCodeFun(vr)
%% Restrict rotation
if vr.position(4) > pi/8
	vr.position(4) = pi/8;
elseif vr.position(4)< -pi/8
	vr.position(4) = -pi/8;
end

%% DELAY PERIOD WHERE SCREEN IS BACKGROUND COLOR (off) needs to be debugged
% persistent blackOut
% 
% if (vr.delay == true)&(vr.worlds{1}.surface.visible == 1)
% 	blackOut = hat;
% end
% if (vr.delay == true)&&(blackOut> 0)
% 	vr.dp = 0;
% 	vr.worlds{1}.surface.visible = 0; 
% else
% 	blackOut = 0;
% end
% if blackOut > .05
% 	blackOut = 0;
% 	vr.worlds{1}.surface.visible = 1;
% 	vr.delay = false;
% end

%% SET UP VARIABLES FOR "BIDIRECTIONAL"

%detecting if inside target area
Nminimum = -(eval(vr.exper.variables.target_height)/2)...
    + (eval(vr.exper.variables.floor_height)/6);
Nmaximum = eval(vr.exper.variables.floor_height)/6 ... 
    + eval(vr.exper.variables.target_height)/2;

Sminimum = -Nmaximum;
Smaximum = -Nminimum;

%% REWARD FOR FORWARD PROGRESS (off)
% if vr.vrSystem.forwardVelocity>100 && rand<.01
% 	vr.vrSystem.rewardPulseObj.sendPulse(.025);
% 	vr.vrSystem.numRewardsGiven = vr.vrSystem.numRewardsGiven + .0249999;
% end

%% DISPLAY POSITION AND TARGET LOCATION EVERY 100 FRAMES (off)
% persistent downCounter
% if isempty(downCounter)
%     downCounter = 100;
% end
% if downCounter <= 0
%     fprintf('NE:%f\nSE:%f\nNW:%f\nSW:\n\n',...
% disp ('position')
% fprintf('%f %f \n',...
%         vr.position(1), vr.position(2));
%     vr.position
%     disp(['N minimum: Maximum    S minimum : Maximum'])
%     fprintf('%f %f %f %f \n',...
%         Nminimum,  Nmaximum, Sminimum, Smaximum);
%     disp(['is south true ' (num2str(vr.target.S.on))])
%     disp (['is north true ' (num2str(vr.target.N.on))])
%     
%         
%     downCounter = 100;
% else
%     downCounter = downCounter -1;
% end

% %% REWARD ELIGIBLE
% if vr.eligible == true
%     vr.vrSystem.numRewardsGiven = vr.vrSystem.numRewardsGiven + 1;
%     vr.vrSystem.rewardCondition = 'obj.distanceFromeTarget<0';
%     disp('rewards')
%     disp(vr.vrSystem.numRewardsGiven)
%     vr.eligible = false;
% %     notify(vr.vrSystem, 'FrameAcquired',vrMsg(vr))
% % 	vr.vrSystem.rewardPulseObj.sendPulse(0.05);
% else
%     vr.vrSystem.rewardCondition = false;
% end
%     
%% MOUSE INSIDE TARGET AREA AND COLOR RESET NORTH
try %N target
    if vr.target.N.on == true
%         disp (['North target true? ' (num2str(vr.target.N.on))])
        %color change when he steps on
        if (vr.position(2) < Nmaximum)&&(vr.position(2)>Nminimum)&&...
                isequaln(vr.worlds{vr.currentWorld}.surface.colors(3,vr.target.N.indx), vr.originalColor.N);
			%use isequaln because they have NaN won't be equal with regualr isequal
            vr.worlds{vr.currentWorld}.surface.colors(3,vr.target.N.indx) = 0;
            vr.eligible = true;
            vr.colorChange.N = true;
        end
        %color restore when steps off
        if (vr.colorChange.N == true)&&((vr.position(2)> Nmaximum)|(vr.position(2)<Nminimum))
            vr.worlds{vr.currentWorld}.surface.colors(3,vr.target.N.indx) = vr.originalColor.N;
            vr.colorChange.N = false;
			vr.delay = true;
			vr.target.N.on = false;
			vr.target.S.on = true;
        end
        
    else
     vr.worlds{vr.currentWorld}.surface.colors(3,vr.target.N.indx) = vr.originalColor.N;
    end
catch me
    disp(me.message)
    disp(me.stack(1))
end

%% MOUSE INSIDE TARGET AREA AND COLOR RESET SOUTH
try %S target
    if vr.target.S.on == true
%         disp('SOUTH LOOP')
        %color change when he steps on
        if vr.position(2) < Smaximum & vr.position(2)>Sminimum &...
                isequaln(vr.worlds{vr.currentWorld}.surface.colors(2,vr.target.S.indx), vr.originalColor.S)
%             disp('SOUTH LOOP 2')
            vr.worlds{vr.currentWorld}.surface.colors(2,vr.target.S.indx) = 0;
            vr.eligible = true;
            vr.colorChange.S = true;
        else
            vr.eligible = false;
        end
        %color restore when steps off
        if (vr.colorChange.S == true)&&((vr.position(2)> Smaximum)|(vr.position(2)<Sminimum))
            vr.worlds{vr.currentWorld}.surface.colors(2,vr.target.S.indx) = vr.originalColor.S; 
			vr.target.S.on = false;
			vr.target.N.on = true;
            vr.colorChange.S = false;
			vr.delay = true;
        end
    else
        vr.worlds{vr.currentWorld}.surface.colors(2,vr.target.S.indx) = vr.originalColor.S;
    end
catch me
    disp(me.message)
    disp(me.stack(1))
end
%% NOTIFY VRSTEM TO SAVE DATA
try
	notify(vr.vrSystem,'FrameAcquired',vrMsg(vr))
catch me	
end
%% Trouble shooting
assignin('base','vr',vr)
%% velocity training within biidirectional (off)
persistent downCounter
 if isempty(downCounter)
     downCounter = 100;
 end
 if downCounter<= 0 
     fprintf('%f\n', vr.vrSystem.forwardVelocity)
     downCounter = 100;
 else
     downCounter = downCounter - 1;
 end
%  vr.velocity(4) = 0;
%  
%  %give reward for 100 continous frames of runing forward
%  persistent frameCounter
%  if isempty(frameCounter)
%      frameCounter = 0;
%  end
%  if abs(vr.vrSystem.forwardVelocity) > 50
% 	 
%      frameCounter = frameCounter + 1;
%  else 
%      frameCounter =  max(0,frameCounter - 1);
%  end
%  
%  if frameCounter >= 150
%      vr.eligible = true;
%      frameCounter = 0;
%  end
%  
%  
%% Reward Eligible 
if vr.eligible == true
     vr.vrSystem.rewardCondition = 'obj.distanceFromTarget<0';
    vr.vrSystem.numRewardsGiven = vr.vrSystem.numRewardsGiven + 1;
    vr.eligible = false;
    fprintf('The animal recieved a reward!!   \n')
	disp(['Number of Rewards ' num2str(vr.vrSystem.numRewardsGiven)])
   assignin('base','vr',vr)
   notify(vr.vrSystem, 'NewTrial')
   vr.vrSystem.rewardPulseObj.sendPulse(.05);
%    fprintf('Reward Given
else 
%             vr.vrSystem.rewardCondition = false; %prevent multiple rewards
end
notify(vr.vrSystem, 'FrameAcquired',vrMsg(vr))

%%






% --- TERMINATION code: executes after the ViRMEn engine stops.
function vr = terminationCodeFun(vr)
disp(['Number of rewards given = ' num2str(vr.vrSystem.numRewardsGiven)])
try
	vr.vrSystem.saveDataFile;
	vr.vrSystem.saveDataSet;
	disp(vr.vrSystem.numRewardsGiven)
	delete(vr.vrSystem);
	delete(vr.movementInterface);
	fclose('all')
	instrreset
catch me
	instrreset
end


