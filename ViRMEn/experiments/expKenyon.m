function code = expKenyon

% Begin header code - DO NOT EDIT
code.initialization = @initializationCodeFun;
code.runtime = @runtimeCodeFun;
code.termination = @terminationCodeFun;
% End header code - DO NOT EDIT



% --- INITIALIZATION code: executes before the ViRMEn engine starts.
function vr = initializationCodeFun(vr)
disp('Initializing...')
%     global CURRENT_EXPERIMENT_NAME

% Data recording interfaces
%     name = inputdlg('Name this experiment, please','Experiment Name',1,{'PIPE'});

vr.vrSystem = VrSystem();
vr.vrSystem.start();        % enables experiment and trial state listeners
%     vr.vrSystem.savePath = 'C:\DATA';
fprintf('VrSystem initialized\n');

% Movement interface
vr.movementInterface = VrMovementInterface;
%     vr.movementFunction = @moveBucklin;
vr.movementInterface.start();

% Initialize RAW VELOCITY for recording direct optical sensor input
vr.vrSystem.rawVelocity = zeros(5,4);
% rawVelocity
% directSensor: left-x, left-y, right-x. right-y
% axialRotation: x, y, z, 0
% mouseRelativeCartesian: x, y, z, omega
% worldRelativeCartesian: x, y, z, omega
% lowPassed: x, y, z, omega
vr.vrSystem.forwardVelocity = 0;

% Begin data-recording systems
fprintf('Sending ExperimentStart notification...\n');
notify(vr.vrSystem,'ExperimentStart');
assignin('base','vr',vr)




% --- RUNTIME code: executes on every iteration of the ViRMEn engine.
function vr = runtimeCodeFun(vr)
% Check conditions and do whatever you want
notify(vr.vrSystem,'FrameAcquired',vrMsg(vr))
try
    if abs(vr.position(1)) > vr.exper.variables.floorWidth/2
        vr.position(1) = -vr.position(1)*.9;
    end
    if abs(vr.position(2)) > vr.exper.variables.floorHeight/2
        vr.position(2) = -vr.position(2)*.9;
    end
catch me
    disp(me.message)
    disp(me.stack(1))
end



% --- TERMINATION code: executes after the ViRMEn engine stops.
function vr = terminationCodeFun(vr)
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