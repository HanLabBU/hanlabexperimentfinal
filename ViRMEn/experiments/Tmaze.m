function code = Tmaze
% Tmaze   Code for the ViRMEn experiment Tmaze.
%   code = Tmaze   Returns handles to the functions that ViRMEn
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
vr.window.TopMost = false;
vr.currentSide = 'r';
% VRSYSTEM for data recording and rewarding
vr.vrSystem = VrSystem();
vr.vrSystem.start();
fprintf('VrSystem initialized\n');





% --- RUNTIME code: executes on every iteration of the ViRMEn engine.
function vr = runtimeCodeFun(vr)
if ~isnan(vr.keyPressed) && ~isempty(str2double(vr.keyPressed))
    vr.currentSide = vr.keyPressed;
    disp(vr.currentSide)
end

if(vr.position(1)>-58)&&(vr.position(1)<-44)&&(vr.position(2)>51)&&(vr.position(2)<78)
    vr.position(1)=0;
    vr.position(2)=0;
    vr.position(4)=0;
    vr.dp(:)=0;
    if strcmp(vr.currentSide,'l')
        disp('correct')
        vr.numCorrect = vr.numCorrect + 1;
        vr.vrSystem.rewardPulseObj.sendPulse();
    else
        vr.numIncorrect = vr.numIncorrect + 1;
        disp('wrong')
    end 
        
end
if(vr.position(1)<58)&&(vr.position(1)>44)&&(vr.position(2)>51)&&(vr.position(2)<78)
    vr.position(1)=0;
    vr.position(2)=0;
    vr.position(4)=0;
    vr.dp(:)=0;
    if strcmp(vr.currentSide,'r')
        disp('correct')
       vr.numCorrect = vr.numCorrect + 1;
       vr.vrSystem.rewardPulseObj.sendPulse();
    else
        vr.numIncorrect = vr.numIncorrect + 1;
        disp('wrong')
    end
end


% --- TERMINATION code: executes after the ViRMEn engine stops.
function vr = terminationCodeFun(vr)
disp(['The animal recieved ' num2str(vr.numCorrect) ' rewards.'])
disp(['The choice was changed ' num2str(vr.keyPressed(1)) ' times.'])