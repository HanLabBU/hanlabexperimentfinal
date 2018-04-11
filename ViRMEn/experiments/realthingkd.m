function code = realthingkd
% realthingkd   Code for the ViRMEn experiment realthingkd.
%   code = realthingkd   Returns handles to the functions that ViRMEn
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

     

if (vr.position(2) > 83)&&(vr.position(2) < 89.5)&&(vr.position(1) > -9)&&(vr.position(1) < 15)&&(vr.currentWorld ==1)
%     newWorldIndx = ceil(rand*3);
    if vr.currentWorld == 1
        vr.currentWorld = vr.currentWorld + 1;
    else
        vr.currentWorld = 1;
    end
    
    vr.position(2) = 0; 
    vr.position(1) = 0;
    assignin('base','vr',vr);
end
if (vr.position(2) > 59)&&(vr.position(2) < 63)&&(vr.position(1) > 41)&&(vr.position(1) < 66)&&(vr.currentWorld == 2)
%     newWorldIndx = ceil(rand*3);
    if vr.currentWorld == 2
        vr.currentWorld = vr.currentWorld + 1;
    else
        vr.currentWorld = 2;
    end    
    vr.position(2) = 0; 
    vr.position(1) = 0;
    assignin('base','vr',vr);
    
end
if (vr.position(2) > 40)&&(vr.position(2) < 45)&&(vr.position(1) > 25)&&(vr.position(1) < 47)&&(vr.currentWorld == 3)
%     newWorldIndx = ceil(rand*3);
    if vr.currentWorld == 3
        vr.currentWorld = vr.currentWorld + 1;
    else
        vr.currentWorld = 3;
    end
    
    vr.position(2) = 0; 
    vr.position(1) = 0;
    assignin('base','vr',vr);
end
if (vr.position(2) > 69)&&(vr.position(2) < 95)&&(vr.position(1) > 5)&&(vr.position(1) < 10)&&(vr.currentWorld == 4)
%     newWorldIndx = ceil(rand*3);
    if vr.currentWorld == 4
        vr.currentWorld = vr.currentWorld + 1;
    else
        vr.currentWorld = 4;
    end
    
    vr.position(2) = 0; 
    vr.position(1) = 0;8
end
if (vr.position(2) > 79)&&(vr.position(2) < 83.5)&&(vr.position(1) > 45)&&(vr.position(1) < 69)&&(vr.currentWorld == 5)
    
%     newWorldIndx = ceil(rand*3);
    if vr.currentWorld == 5
        vr.currentWorld = vr.currentWorld + 1;
    else
        vr.currentWorld = 5;
    end
    
    vr.position(2) = 0; 
    vr.position(1) = 0;
end
if (vr.position(2) > 66)&&(vr.position(2) < 90)&&(vr.position(1) > 56)&&(vr.position(1) < 62)&& (vr.currentWorld == 6)
%     newWorldIndx = ceil(rand*3);
    if vr.currentWorld == 6
        vr.currentWorld = vr.currentWorld + 1;
    else
        vr.currentWorld = 6;
    end
    
    vr.position(2) = 0; 
    vr.position(1) = 0;
end
if (vr.position(2) > 75)&&(vr.position(2) < 98)&&(vr.position(1) > 10.5)&&(vr.position(1) < 15.5) && (vr.currentWorld == 7)
%     newWorldIndx = ceil(rand*3);
    if vr.currentWorld == 7
        vr.currentWorld = vr.currentWorld + 1;
    else
        vr.currentWorld = 7;
    end
    
    vr.position(2) = 0; 
    vr.position(1) = 0;
end
if (vr.position(2) > 46)&&(vr.position(2) < 51)&&(vr.position(1) > -47)&&(vr.position(1) < -25)&&(vr.currentWorld==8)
%     newWorldIndx = ceil(rand*3);
    if vr.currentWorld == 8
        vr.currentWorld = vr.currentWorld + 1;
    else
        vr.currentWorld = 8;
    end
    
    vr.position(2) = 0; 
    vr.position(1) = 0;
end
if (vr.position(2) > 89)&&(vr.position(2) < 114)&&(vr.position(1) > 5.5)&&(vr.position(1) < 10.2)&&(vr.currentWorld==9)
%     newWorldIndx = ceil(rand*3);
    if vr.currentWorld == 9
        vr.currentWorld = vr.currentWorld + 1;
    else
        vr.currentWorld = 9;
    end
    
    vr.position(2) = 0; 
    vr.position(1) = 0;
end
if (vr.position(2) > 109)&&(vr.position(2) < 104)&&(vr.position(1) > -39)&&(vr.position(1) < -14)&&(vr.currentWorld==10)
%     newWorldIndx = ceil(rand*3);
    if vr.currentWorld == 10
        vr.currentWorld = vr.currentWorld + 1;
    else
        vr.currentWorld = 10;
    end
    
    vr.position(2) = 0; 
    vr.position(1) = 0;
end

% --- TERMINATION code: executes after the ViRMEn engine stops.
function vr = terminationCodeFun(vr)
