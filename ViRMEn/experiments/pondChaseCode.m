function code = pondChaseCode

% Begin header code - DO NOT EDIT
code.initialization = @initializationCodeFun;
code.runtime = @runtimeCodeFun;
code.termination = @terminationCodeFun;
% End header code - DO NOT EDIT









% --- INITIALIZATION code: executes before the ViRMEn engine starts.
function vr = initializationCodeFun(vr)

vr.window.TopMost = false;

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
sessionPath =  fullfile(['C:\DATA\',...
    'VR_',datestr(date,'yyyy_mm_dd')]);
currentDataSetPath = fullfile(sessionPath,name); %(add filesep?)
autoSyncTrialTime = 60;
savePath = sessionPath;
vr.vrSystem = VrSystem(...
    'rewardCondition','true',...
    'sessionPath',sessionPath,...
    'currentDataSetPath',currentDataSetPath,...
    'autoSyncTrialTime',autoSyncTrialTime,...
    'savePath',savePath,...
    'currentExperimentName',name);

% Set Reward Condition using Distance from Target
vr.target.xLocations = eval(vr.exper.variables.xPond);
vr.target.yLocations = eval(vr.exper.variables.yPond);
indx = vr.currentWorld;
vr.target.currentLocation = [vr.target.xLocations(indx) ; vr.target.yLocations(indx)];
vr.target.cartesianDistFromTarget = vr.target.currentLocation(:)' - vr.position(1:2);
vr.target.distFromTargetCenter = hypot(vr.target.cartesianDistFromTarget(1), vr.target.cartesianDistFromTarget(2));
vr.target.threshold = eval(vr.exper.variables.pondRadius);
vr.target.initialDistance = 1000;
vr.vrSystem.distanceFromTarget = vr.target.initialDistance;
vr.vrSystem.numRewardsGiven = 0;
vr.vrSystem.rewardCondition = 'obj.distanceFromTarget < 0';
vr.swimming = false;
vr.swimTime = 2;



% Enable Experiment and Trial State Listeners
vr.vrSystem.start();        
%     vr.vrSystem.savePath = 'C:\DATA'; %TODO
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












% --- RUNTIME code: executes on every iteration of the ViRMEn engine.
function vr = runtimeCodeFun(vr)
persistent timeSwimStarted
% Check conditions and do whatever you want
try
    if (vr.vrSystem.distanceFromTarget > 0)
        % Update Distance from Target
        indx = vr.currentWorld;
        vr.target.currentLocation = ...
            [vr.target.xLocations(indx) ; vr.target.yLocations(indx)];
        vr.target.cartesianDistFromTarget = ...
            vr.target.currentLocation(:)' - vr.position(1:2);
        vr.target.distFromTargetCenter = ...
            hypot(vr.target.cartesianDistFromTarget(1),...
            vr.target.cartesianDistFromTarget(2));
        vr.target.threshold = eval(vr.exper.variables.pondRadius);
        vr.vrSystem.distanceFromTarget = ...
            vr.target.distFromTargetCenter - vr.target.threshold;
    else
       % Change to a New World (with a delay)
       if ~vr.swimming % indicates distanceFromTarget just fell below threshold
           % i.e. mouse just started swimming
           vr.swimming = true;
           timeSwimStarted = hat; % hat is an external mex function (High-Accuracy-Timer)           
       elseif (hat - timeSwimStarted) > vr.swimTime
           % delay has exceeded swimTime -> time to change the world
           worldIndex = vr.currentWorld;
           while (worldIndex == vr.currentWorld)
               worldIndex = ceil(rand*length(vr.worlds));
           end
           vr.currentWorld = worldIndex;
           vr.swimming = false;
           vr.vrSystem.distanceFromTarget = vr.target.initialDistance;
           vr.vrSystem.rewardCondition = 'obj.distanceFromTarget < 0'; % reset rewardCondition
           %notify(vr.vrSystem,'NewTrial');
       else % mouse is swimming and still in delay period
           vr.vrSystem.rewardCondition = false; % prevent multiple rewards           
       end
    end
    
    notify(vr.vrSystem,'FrameAcquired',vrMsg(vr))
catch me
    disp(me.message)
    disp(me.stack(1))
    assignin('base','vr',vr)
end



% --- TERMINATION code: executes after the ViRMEn engine stops.
function vr = terminationCodeFun(vr)
assignin('base','vr',vr)
notify(vr.vrSystem,'ExperimentStop')
saveDataFile(vr.vrSystem)
saveDataSet(vr.vrSystem)
delete(vr.movementInterface)



















% - vr.exper: a variable of the class virmenExperiment that contains all information about the experiment, worlds, etc. Changing this variable during the experiment does not do anything. However, I recommend saving this variable for future reference each time you run an experiment – that way you will have a record of all day-to-day changes you might have made to your experiment.
% - vr.code: a structure containing function handles of the initialization, runtime, and termination functions.
% - vr.antialiasing: a scalar indicating the level of antialiasing. Changing this value during an experiment will instantaneously changing the amount of image antialiasing.
% - vr.worlds: a cell array of structures containing all information about the worlds used by the current experiment. Changing these structures will cause instantaneous changes to worlds. See the section on manipulating worlds for details.
% - vr.experimentEnded: a Boolean indicating whether the experiment should be forced to end. Setting this to true will immediately stop the engine and run the termination function.
% - vr.currentWorld: the index of the current world. This must have an integer value from 1 to the length of vr.worlds. Changing this value will instantaneously switch worlds.
% - vr.position: an array of length 4 containing the current position in the form [x, y, z, viewAngle]. The units are ViRMEn space units for x, y, and z and radians for the viewAngle. Changing these values will instantaneously teleport or rotate the animal in the world.
% - vr.velocity: an array of length 4 containing the current velocity in the form (d/dt)[x, y, z, viewAngle]. The units are ViRMEn space units/sec for the first three values and radians/sec for the fourth value. Changing these values does not do anything; to effect the animal’s movement, change vr.dp instead.
% - vr.dt: the amount of time in seconds elapsed since the previous iteration. Changing this value does not do anything.
% - vr.dp: the change in position and view angle being implemented on the current iteration. Typically, vr.dp=vr.velocity*vr.dt. However, if the animal is currently in collision with an edge of an object, vr.dp is projected onto the edge, so that the animal “skids” along it. Changing the value of vr.dp will change the amount by which the animal moves and/or rotates on the current iteration.
% - vr.collision: Boolean indicating whether the animal is currently in collision with an edge of an object.
% - vr.text: a structure containing all textboxes displayed on the screen. Changing this structure can be used to introduce new textboxes or modify or delete existing ones.
% - vr.plot: a structure containing all line plots displayed this structure. Changing this structure can be used to introduce new line plots or modify or delete existing ones.
% - vr.textClicked: the index of the textbox that was clicked by the user during the previous iteration. If no textbox was clicked, the value is NaN.
% 25
% - vr.keyPressed: the character of a key that was pressed by the user during the last iteration. If no key was pressed, the value is NaN.
% - vr.iterations: the number of iterations performed by the engine during the current run.
% - vr.timeStarted: Matlab time stamp indicating the time point at which the engine started running.
% - vr.window: handle of the Windows Form containing the ViRMEn window. See help from Microsoft for programming this form.
% - vr.oglControl: handle of the OpenGL control containing the ViRMEn display. See help from OpenTK for programming this control.