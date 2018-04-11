function code = jumptest
% jumptest   Code for the ViRMEn experiment jumptest.
%   code = jumptest   Returns handles to the functions that ViRMEn
%   executes during engine initialization, runtime and termination.


% Begin header code - DO NOT EDIT
code.initialization = @initializationCodeFun;
code.runtime = @runtimeCodeFun;
code.termination = @terminationCodeFun;
% End header code - DO NOT EDIT



% --- INITIALIZATION code: executes before the ViRMEn engine starts.
function vr = initializationCodeFun(vr)



% --- RUNTIME code: executes on every iteration of the ViRMEn engine.
function vr = runtimeCodeFun(vr)

if (vr.position(2) > 47)&&(vr.position(2) < 55)&&(vr.position(1) > 3)&&(vr.position(1) < 10)
%     newWorldIndx = ceil(rand*3);
    if vr.currentWorld < 3
        vr.currentWorld = vr.currentWorld + 1;
    else
        vr.currentWorld = 1;
    end
    
    vr.position(2) = 0; 
    vr.position(1) = 0;
end


% --- TERMINATION code: executes after the ViRMEn engine stops.
function vr = terminationCodeFun(vr)
