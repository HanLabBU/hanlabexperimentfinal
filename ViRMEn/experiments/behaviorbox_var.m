function code = behaviorbox_var
% behaviorbox_var   Code for the ViRMEn experiment behaviorbox_var.
%   code = behaviorbox_var   Returns handles to the functions that ViRMEn
%   executes during engine initialization, runtime and termination.


% Begin header code - DO NOT EDIT
code.initialization = @initializationCodeFun;
code.runtime = @runtimeCodeFun;
code.termination = @terminationCodeFun;
% End header code - DO NOT EDIT



% --- INITIALIZATION code: executes before the ViRMEn engine starts.
function vr = initializationCodeFun(vr)
vr.numCorrect = 0;
vr.numIncorrect = 0;
vr.window.TopMost = false; %make it not go to full screen
vr.currentSide = 'e'; %set default to right side

%set variables
vr.floor_width = eval(vr.exper.variables.floor_width);
vr.location_distance = eval(vr.exper.variables.location_distance);
    %location distances is the distance from the outside wall
vr.radius = eval(vr.exper.variables.radius);


% --- RUNTIME code: executes on every iteration of the ViRMEn engine.
function vr = runtimeCodeFun(vr)

%check current side
if ~isnan(vr.keyPressed) && ~isempty(str2double(vr.keyPressed))
    vr.currentSide = vr.keyPressed;
    disp(vr.currentSide)
end

%E target is correct target
while strcmp(vr.currentSide,'e')
    if (vr.position(1)<(vr.floor_width/2 - vr.location_distance +5))...
        &&(vr.position(1) > (vr.floor_width/2 - vr.location_distance - 5))...
        &&(vr.position(2)< (vr.floor_width*8/20 + vr.radius))...
        &&(vr.position(2)> (vr.floor_width*8/20 - vr.radius))...
       
    vr.position(1) = 0;
    vr.position(2) = -vr.floor_width/4;
    vr.position(4) = 0;
    vr.numCorrect = vr.numCorrect + 1;
    disp('correct')
    elseif strcmp(vr.currentSide,'w')
        vr.numIncorrect = vr.numIncorrect + 1;
        beep;
        disp('wrong')
        vr.position(1) = 0;
        vr.position(2) = -vr.floor_width/4;
        vr.position(4) = 0;
    end
end

%W target is correct
while strcmp(vr.currentSide,'w')
    if (vr.position(1)<(-vr.floor_width/2 - vr.location_distance +5))...
        &&(vr.position(1) > (-vr.floor_width/2 - vr.location_distance - 5))...
        &&(vr.position(2)< (vr.floor_width*8/20 + vr.radius))...
        &&(vr.position(2)> (vr.floor_width*8/20 - vr.radius))...
       
    vr.position(1) = 0;
    vr.position(2) = -vr.floor_width/4;
    vr.position(4) = 0;
    vr.numRewards = vr.numrewards + 1;
    disp('correct')
    elseif strcmp(vr.currentSide,'e')
        vr.numIncorrect = vr.numIncorrect + 1;
        beep;
        disp('wrong')
        vr.position(1) = 0;
        vr.position(2) = -vr.floor_width/4;
        vr.position(4) = 0;
    end
end


% --- TERMINATION code: executes after the ViRMEn engine stops.
function vr = terminationCodeFun(vr)
disp(['The animal recieved ' num2str(vr.numCorrect) ' rewards.'])
disp(['The animal went to the incorrect side ' num2str(vr.numIncorrect) ' times.'])