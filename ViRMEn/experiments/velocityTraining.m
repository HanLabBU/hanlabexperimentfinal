function code = velocityTraining
% velocityTraining   Code for the ViRMEn experiment velocityTraining.
%   code = velocityTraining   Returns handles to the functions that ViRMEn
%   executes during engine initialization, runtime and termination.


% Begin header code - DO NOT EDIT
code.initialization = @initializationCodeFun;
code.runtime = @runtimeCodeFun;
code.termination = @terminationCodeFun;
% End header code - DO NOT EDIT



% --- INITIALIZATION code: executes before the ViRMEn engine starts.
function vr = initializationCodeFun(vr)

% try %data collect/file saving
%     
%      disp('Initializing...')
% 	 persistent instancenum
% 
% 
% % Data recording interfaces (and File Naming)
% if isempty(instancenum)
%     instancenum = 1;
% else
%     instancenum = instancenum+1;
% end
% global CURRENT_EXPERIMENT_NAME
% if isempty(CURRENT_EXPERIMENT_NAME)
%     CURRENT_EXPERIMENT_NAME = sprintf('MOUSE99_%g',instancenum);
% else
%     expNameRoot = strtok(CURRENT_EXPERIMENT_NAME,'_');
%     CURRENT_EXPERIMENT_NAME = sprintf('%s_%g',expNameRoot,instancenum);
% end
% name = inputdlg('Name this experiment, please','Experiment Name',1,{CURRENT_EXPERIMENT_NAME});
% name = name{1};
% CURRENT_EXPERIMENT_NAME = name;
% % sessionPath =  fullfile(['C:\DATA\',...
% %     'VR_',datestr(date,'yyyy_mm_dd')]);
% % currentDataSetPath = fullfile(sessionPath,name); %(add filesep?)
% autoSyncTrialTime = 60;
% % savePath = sessionPath;
% vr.vrSystem = VrSystem(...
%     'rewardCondition','obj.forwardVelocity>100',...
%     'currentDataSetPath',currentDataSetPath,...
%     'autoSyncTrialTime',autoSyncTrialTime,...
%     'currentExperimentName',name);
% %     'sessionPath',sessionPath,...
% %     'savePath',savePath,...
try
daq.reset


% MOVE WINDOW ONTO PROJECTOR SCREEN (will need to be changed for different
% screen sizes and setups)
vr.window.TopMost = false;
vr.window.WindowState = System.Windows.Forms.FormWindowState.Normal;
vr.eligible = false;



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
    CURRENT_EXPERIMENT_NAME = sprintf('MOUSE_%g',instancenum);
else
    expNameRoot = strtok(CURRENT_EXPERIMENT_NAME,'_');
    CURRENT_EXPERIMENT_NAME = sprintf('%s_%g',expNameRoot,instancenum);
end
name = inputdlg('Name this experiment, please','Experiment Name',1,{CURRENT_EXPERIMENT_NAME});
name = name{1};
CURRENT_EXPERIMENT_NAME = name;
autoSyncTrialTime = 60;
vr.vrSystem = VrSystem(...
    'rewardCondition','true',...
    'autoSyncTrialTime',autoSyncTrialTime,...    
    'currentExperimentName',name);
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


catch me
    disp(me.message)
    disp(me.stack(1))
end


% --- RUNTIME code: executes on every iteration of the ViRMEn engine.
function vr = runtimeCodeFun(vr)

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
 
 %give reward for 100 continous frames of runing forward
 persistent frameCounter
 if isempty(frameCounter)
     frameCounter = 0;
 end
 if abs(vr.vrSystem.forwardVelocity) > 50
	 
     frameCounter = frameCounter + 1;
 else 
     frameCounter =  max(0,frameCounter - 1);
 end
 if frameCounter >= 210
     vr.eligible = true;
     frameCounter = 0;
 end
 
 
 %reward eligible 
if vr.eligible == true
%     vr.vrSystem.rewardCondition = 'obj.distanceFromTarget<0';
    vr.vrSystem.numRewardsGiven = vr.vrSystem.numRewardsGiven + 1;
    vr.eligible = false;
    fprintf('The animal recieved a reward!!   \n')
	disp(['Number of Rewards ' num2str(vr.vrSystem.numRewardsGiven)])
   assignin('base','vr',vr)
   vr.vrSystem.rewardPulseObj.sendPulse(.05);
%    fprintf('Reward Given
else 
%             vr.vrSystem.rewardCondition = false; %prevent multiple rewards
end
notify(vr.vrSystem, 'FrameAcquired',vrMsg(vr))
     

 


% --- TERMINATION code: executes after the ViRMEn engine stops.
function vr = terminationCodeFun(vr)
vr.vrSystem.saveDataFile;
vr.vrSystem.saveDataSet;
fclose('all')
instrreset
disp(vr.vrSystem.numRewardsGiven)



