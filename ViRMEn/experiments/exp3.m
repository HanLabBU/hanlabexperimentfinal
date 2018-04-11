function code = exp3
 
    % Begin header code - DO NOT EDIT
    code.initialization = @initializationCodeFun;
    code.runtime = @runtimeCodeFun;
    code.termination = @terminationCodeFun;
    % End header code - DO NOT EDIT



    % --- INITIALIZATION code: executes before the ViRMEn engine starts.
function vr = initializationCodeFun(vr)

    disp('Initializing...')
     vr.m = udpInterface;
     vr.l = vr.m.l;
     vr.r = vr.m.r;
     vr.velocitybuffer = zeros(10,4);
    


% --- RUNTIME code: executes on every iteration of the ViRMEn engine.
function vr = runtimeCodeFun(vr)
    
     if vr.collision
         vr.dp = vr.dp/1;
     end

    
    % --- TERMINATION code: executes after the ViRMEn engine stops.
function vr = terminationCodeFun(vr)

    close(vr.m)

   