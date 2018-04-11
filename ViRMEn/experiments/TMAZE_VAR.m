function code = TMAZE_VAR
% TMAZE_VAR   Code for the ViRMEn experiment TMAZE_VAR.
%   code = TMAZE_VAR   Returns handles to the functions that ViRMEn
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
vr.currentSide = 'r'; %set default to right side


vr.floor_width = eval(vr.exper.variables.floor_width);%check value of floor_width
vr.percentage = eval(vr.exper.variables.percentage);
vr.decision_length = eval(vr.exper.variables.floor_width)*3.5...
    + eval(vr.exper.variables.floor_width)*3.5*eval(vr.exper.variables.percentage);
%vr.decision_length = eval(vr.exper.variables.decision_length);%check value of decision_length
    %when changing decision length, change the percentage in the GUI, and
    %then change the value of decision length (e.g. floor_width*3.5...+1)
    %and then hit undo. If you only change the percentage, nothing will happen. Decision length
    %only evaulates itself when it is changed. 

vr.soundNumber = 0; % beep condition


%attempt at making sound
    %load ('soundtest.m')    
    %vr.soundtest = audioplayer(y,Fs);
    %load ('soundtest2.m')
%vr.soundtest2 = audioplayer(y,Fs);
    % VRSYSTEM for data recording and rewarding
    %vr.vrSystem = VrSystem();
    %vr.vrSystem.start();
    %fprintf('VrSystem initialized\n');

% --- RUNTIME code: executes on every iteration of the ViRMEn engine.
function vr = runtimeCodeFun(vr)

%check which side is right, with keyboard input
if ~isnan(vr.keyPressed) && ~isempty(str2double(vr.keyPressed))
    vr.currentSide = vr.keyPressed;
    disp(vr.currentSide)
end


%check which sound to play
if (vr.position(2)<(vr.floor_width*3.5/7)&&(strcmp(vr.currentSide,'l'))...
        &&(vr.soundNumber == 0))
    sound(8*sin(linspace(100,500,1000)),9000);
    disp ('beep')
    vr.soundNumber = vr.soundNumber + 1;
end
if (vr.position(2)<(vr.floor_width*3.5/7)&&(strcmp(vr.currentSide,'r'))...
        &&(vr.soundNumber == 0))
   sound(8*sin(linspace(100,500,1000)),5000);
    disp ('beep')
    vr.soundNumber = vr.soundNumber + 1;
end

%check if in correct target, give reward, and teleport back to begining
if(vr.position(1)>(-vr.floor_width*3.5))&&(vr.position(1)<(-vr.floor_width*3.5 + vr.floor_width*3.5/7))...
        %&&(vr.position(2)>(vr.decision_length))&&(vr.position(2)<(vr.decision_length + vr.floor_width))
    %left side
    vr.position(1)=0;
    vr.position(2)=(vr.floor_width*3.5/21);
    vr.position(4)=0;
    vr.dp(:)=0;
    vr.soundNumber = vr.soundNumber - 1;
    if strcmp(vr.currentSide,'l')
        disp('correct')
        vr.numCorrect = vr.numCorrect + 1;
        %vr.vrSystem.rewardPulseObj.sendPulse();
    else
        vr.numIncorrect = vr.numIncorrect + 1;
        disp('wrong')
    end 
end
    



%check if in correct target, give reward, and teleport back to begining
if(vr.position(1)>(vr.floor_width*3.5 - vr.floor_width*3.5/7))&&(vr.position(1)<(vr.floor_width*3.5))...
        %&&(vr.position(2)>(vr.decision_length))&&(vr.position(2)<(vr.decision_length + vr.floor_width))
    %right side
    vr.position(1)=0;
    vr.position(2)=(vr.floor_width*3.5/21);
    vr.position(4)=0;
    vr.dp(:)=0;
    vr.soundNumber = vr.soundNumber - 1;
    if strcmp(vr.currentSide,'r')
        disp('correct')
       vr.numCorrect = vr.numCorrect + 1;
       %vr.vrSystem.rewardPulseObj.sendPulse();
    else
        vr.numIncorrect = vr.numIncorrect + 1;
        disp('wrong')
    end
end


% --- TERMINATION code: executes after the ViRMEn engine stops.
function vr = terminationCodeFun(vr)
disp(['The animal recieved ' num2str(vr.numCorrect) ' rewards.'])
disp(['The animal went to the incorrect side ' num2str(vr.numIncorrect) ' times.'])
disp(['The choice was changed ' num2str(vr.keyPressed(1)) ' times.'])