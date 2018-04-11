function code = behaviorbox
% behaviorbox   Code for the ViRMEn experiment behaviorbox.
%   code = behaviorbox   Returns handles to the functions that ViRMEn
%   executes during engine initialization, runtime and termination.


% Begin header code - DO NOT EDIT
code.initialization = @initializationCodeFun;
code.runtime = @runtimeCodeFun;
code.termination = @terminationCodeFun;
% End header code - DO NOT EDIT


%press 'e' for the EAST choice to be correct
%press 'w' for the WEST choice to be correct
%press '1' to go to the next world which reduces the distance between
%   the cylinders by 10
%press '2' to go to the previous world which increases the distance between
%   the cylinders by 10



% --- INITIALIZATION code: executes before the ViRMEn engine starts.
function vr = initializationCodeFun(vr)
vr.numReward = 0;
vr.currentSide = 'e';

vr.currentWorld = 1;
vr.window.TopMost = false;


% --- RUNTIME code: executes on every iteration of the ViRMEn engine.
function vr = runtimeCodeFun(vr)
% if (vr.position(2)< -40)
%     vr.currentWorld = vr.currentWorld + 1;
%     vr.position(1) = 0;
%     vr.position(2) = 0;
% end
if ~isnan(vr.keyPressed) && ~isempty(str2double(vr.keyPressed))
    vr.currentSide = vr.keyPressed;
    %disp(vr.currentSide)
end


%correct loops
if  strcmp(vr.currentSide, 'e')
    %east is the correct side
    if (vr.currentWorld==1)&&(vr.position(1)>35)&&(vr.position(2)>35)&&(vr.position(1)<45)...
            &&(vr.position(2)<45)
     vr.numReward = vr.numReward + 1;
     disp ('correct')
     vr.position(1)=0;
     vr.position(2)=0;
    vr.position(4) = 0;
    end
    if (vr.currentWorld == 2)&&(vr.position(1)>30)&&(vr.position(1)<40)&&(vr.position(2)>35)...
        &&(vr.position(2)<45)
    vr.numReward = vr.numReward + 1;
     disp ('correct')
    vr.position(1)=0;
    vr.position(2)=0;
    vr.position(4) = 0;
    end
    if (vr.currentWorld == 3)&&(vr.position(1)>25)&&(vr.position(1)<35)&&(vr.position(2)>35)...
        &&(vr.position(2)<45)
    vr.numReward = vr.numReward + 1;
     disp ('correct')
    vr.position(1)=0;
    vr.position(2)=0;
    vr.position(4) = 0;
    end
    if (vr.currentWorld == 4)&&(vr.position(1)>20)&&(vr.position(1)<30)&&(vr.position(2)>35)...
        &&(vr.position(2)<45)
    vr.numReward = vr.numReward + 1;
     disp ('correct')
    vr.position(1)=0;
    vr.position(2)=0;
    vr.position(4) = 0;
    end
    if (vr.currentWorld == 5)&&(vr.position(1)>15)&&(vr.position(1)<25)&&(vr.position(2)>35)...
        &&(vr.position(2)<45)
    vr.numReward = vr.numReward + 1;
     disp ('correct')
    vr.position(1)=0;
    vr.position(2)=0;
    vr.position(4) = 0;
    end
    if (vr.currentWorld == 6)&&(vr.position(1)>10)&&(vr.position(1)<20)&&(vr.position(2)>35)...
        &&(vr.position(2)<45)
    vr.numReward = vr.numReward + 1;
     disp ('correct')
    vr.position(1)=0;
    vr.position(2)=0;
    vr.position(4) = 0;
    end
    if (vr.currentWorld == 7)&&(vr.position(1)>5)&&(vr.position(1)<15)&&(vr.position(2)>35)...
        &&(vr.position(2)<45)
    vr.numReward = vr.numReward + 1;
     disp ('correct')
    vr.position(1)=0;
    vr.position(2)=0;
    vr.position(4) = 0;
    end
    if (vr.currentWorld == 8)&&(vr.position(1)>0.5)&&(vr.position(1)<10.5)&&(vr.position(2)>35)...
        &&(vr.position(2)<45)
    vr.numReward = vr.numReward + 1;
     disp ('correct')
    vr.position(1)=0;
    vr.position(2)=0;
    vr.position(4) = 0;
    end
    
elseif strcmp(vr.currentSide,'w')
    %west is the correct side
    %disp(vr.c)
    
    if (vr.currentWorld==1)&&(vr.position(1)<-35)&&(vr.position(2)>35)&&(vr.position(1)>-45)...
            &&(vr.position(2)<45)
     vr.numReward = vr.numReward + 1;
     disp ('correct')
     vr.position(1)=0;
     vr.position(2)=0;
    vr.position(4) = 0;
    end
    if (vr.currentWorld == 2)&&(vr.position(1)<-30)&&(vr.position(1)>-40)&&(vr.position(2)>35)...
        &&(vr.position(2)<45)
    vr.numReward = vr.numReward + 1;
     disp ('correct')
    vr.position(1)=0;
    vr.position(2)=0;
    vr.position(4) = 0;
    end
    if (vr.currentWorld == 3)&&(vr.position(1)<-25)&&(vr.position(1)>-35)&&(vr.position(2)>35)...
        &&(vr.position(2)<45)
    vr.numReward = vr.numReward + 1;
     disp ('correct')
    vr.position(1)=0;
    vr.position(2)=0;
    vr.position(4) = 0;
    end
    if (vr.currentWorld == 4)&&(vr.position(1)<-20)&&(vr.position(1)>-30)&&(vr.position(2)>35)...
        &&(vr.position(2)<45)
    vr.numReward = vr.numReward + 1;
     disp ('correct')
    vr.position(1)=0;
    vr.position(2)=0;
    vr.position(4) = 0;
    end
    if (vr.currentWorld == 5)&&(vr.position(1)<-15)&&(vr.position(1)>-25)&&(vr.position(2)>35)...
        &&(vr.position(2)<45)
    vr.numReward = vr.numReward + 1;
     disp ('correct')
    vr.position(1)=0;
    vr.position(2)=0;
    vr.position(4) = 0;
    end
    if (vr.currentWorld == 6)&&(vr.position(1)<-10)&&(vr.position(1)>-20)&&(vr.position(2)>35)...
        &&(vr.position(2)<45)
    vr.numReward = vr.numReward + 1;
     disp ('correct')
    vr.position(1)=0;
    vr.position(2)=0;
    vr.position(4) = 0;
    end
    if (vr.currentWorld == 7)&&(vr.position(1)<-5)&&(vr.position(1)>-15)&&(vr.position(2)>35)...
        &&(vr.position(2)<45)
    vr.numReward = vr.numReward + 1;
     disp ('correct')
    vr.position(1)=0;
    vr.position(2)=0;
    vr.position(4) = 0;
    end
    if (vr.currentWorld == 8)&&(vr.position(1)<-0.5)&&(vr.position(1)>-10.5)&&(vr.position(2)>35)...
        &&(vr.position(2)<45)
    vr.numReward = vr.numReward + 1;
     disp ('correct')
    vr.position(1)=0;
    vr.position(2)=0;
    vr.position(4) = 0;
    end
end



%incorrect loops
if strcmp(vr.currentSide,'w')
    %west is correct choice
 if (vr.currentWorld==1)&&(vr.position(1)>35)&&(vr.position(2)>35)&&(vr.position(1)<45)...
            &&(vr.position(2)<45)
     vr.numReward = vr.numReward + 1;
     disp ('incorrect')
     disp(vr.currentSide)
     vr.position(1)=0;
     vr.position(2)=0;
    vr.position(4) = 0;
    end
    if (vr.currentWorld == 2)&&(vr.position(1)>30)&&(vr.position(1)<40)&&(vr.position(2)>35)...
        &&(vr.position(2)<45)
    vr.numReward = vr.numReward + 1;
     disp ('incorrect')
     disp(vr.currentSide)
    vr.position(1)=0;
    vr.position(2)=0;
    vr.position(4) = 0;
    end
    if (vr.currentWorld == 3)&&(vr.position(1)>25)&&(vr.position(1)<35)&&(vr.position(2)>35)...
        &&(vr.position(2)<45)
    vr.numReward = vr.numReward + 1;
     disp ('incorrect')
     disp(vr.currentSide)
    vr.position(1)=0;
    vr.position(2)=0;
    vr.position(4) = 0;
    end
    if (vr.currentWorld == 4)&&(vr.position(1)>20)&&(vr.position(1)<30)&&(vr.position(2)>35)...
        &&(vr.position(2)<45)
    vr.numReward = vr.numReward + 1;
     disp ('incorrect')
     disp(vr.currentSide)
    vr.position(1)=0;
    vr.position(2)=0;
    vr.position(4) = 0;
    end
    if (vr.currentWorld == 5)&&(vr.position(1)>15)&&(vr.position(1)<25)&&(vr.position(2)>35)...
        &&(vr.position(2)<45)
    vr.numReward = vr.numReward + 1;
     disp ('incorrect')
     disp(vr.currentSide)
    vr.position(1)=0;
    vr.position(2)=0;
    vr.position(4) = 0;
    end
    if (vr.currentWorld == 6)&&(vr.position(1)>10)&&(vr.position(1)<20)&&(vr.position(2)>35)...
        &&(vr.position(2)<45)
    vr.numReward = vr.numReward + 1;
     disp ('incorrect')
     disp(vr.currentSide)
    vr.position(1)=0;
    vr.position(2)=0;
    vr.position(4) = 0;
    end
    if (vr.currentWorld == 7)&&(vr.position(1)>5)&&(vr.position(1)<15)&&(vr.position(2)>35)...
        &&(vr.position(2)<45)
    vr.numReward = vr.numReward + 1;
     disp ('incorrect')
     disp(vr.currentSide)
    vr.position(1)=0;
    vr.position(2)=0;
    vr.position(4) = 0;
    end
    if (vr.currentWorld == 8)&&(vr.position(1)>0.5)&&(vr.position(1)<10.5)&&(vr.position(2)>35)...
        &&(vr.position(2)<45)
    vr.numReward = vr.numReward + 1;
     disp ('incorrect')
     disp(vr.currentSide)
    vr.position(1)=0;
    vr.position(2)=0;
    vr.position(4) = 0;
    end
    
elseif strcmp(vr.currentSide,'e')
    %east is the correct side
   % disp(vr.keyPressed)
    
    if (vr.currentWorld==1)&&(vr.position(1)<-35)&&(vr.position(2)>35)&&(vr.position(1)>-45)...
            &&(vr.position(2)<45)
     vr.numReward = vr.numReward + 1;
     disp ('incorrect')
     disp(vr.currentSide)
     vr.position(1)=0;
     vr.position(2)=0;
    vr.position(4) = 0;
    end
    if (vr.currentWorld == 2)&&(vr.position(1)<-30)&&(vr.position(1)>-40)&&(vr.position(2)>35)...
        &&(vr.position(2)<45)
    vr.numReward = vr.numReward + 1;
     disp ('incorrect')
     disp(vr.currentSide)
    vr.position(1)=0;
    vr.position(2)=0;
    vr.position(4) = 0;
    end
    if (vr.currentWorld == 3)&&(vr.position(1)<-25)&&(vr.position(1)>-35)&&(vr.position(2)>35)...
        &&(vr.position(2)<45)
    vr.numReward = vr.numReward + 1;
     disp ('incorrect')
     disp(vr.currentSide)
    vr.position(1)=0;
    vr.position(2)=0;
    vr.position(4) = 0;
    end
    if (vr.currentWorld == 4)&&(vr.position(1)<-20)&&(vr.position(1)>-30)&&(vr.position(2)>35)...
        &&(vr.position(2)<45)
    vr.numReward = vr.numReward + 1;
     disp ('incorrect')
     disp(vr.currentSide)
    vr.position(1)=0;
    vr.position(2)=0;
    vr.position(4) = 0;
    end
    if (vr.currentWorld == 5)&&(vr.position(1)<-15)&&(vr.position(1)>-25)&&(vr.position(2)>35)...
        &&(vr.position(2)<45)
    vr.numReward = vr.numReward + 1;
     disp ('incorrect')
     disp(vr.currentSide)
    vr.position(1)=0;
    vr.position(2)=0;
    vr.position(4) = 0;
    end
    if (vr.currentWorld == 6)&&(vr.position(1)<-10)&&(vr.position(1)>-20)&&(vr.position(2)>35)...
        &&(vr.position(2)<45)
    vr.numReward = vr.numReward + 1;
     disp ('incorrect')
     disp(vr.currentSide)
    vr.position(1)=0;
    vr.position(2)=0;
    vr.position(4) = 0;
    end
    if (vr.currentWorld == 7)&&(vr.position(1)<-5)&&(vr.position(1)>-15)&&(vr.position(2)>35)...
        &&(vr.position(2)<45)
    vr.numReward = vr.numReward + 1;
     disp ('incorrect')
     disp(vr.currentSide)
    vr.position(1)=0;
    vr.position(2)=0;
    vr.position(4) = 0;
    end
    if (vr.currentWorld == 8)&&(vr.position(1)<-0.5)&&(vr.position(1)>-10.5)&&(vr.position(2)>35)...
        &&(vr.position(2)<45)
    vr.numReward = vr.numReward + 1;
     disp ('incorrect')
     disp(vr.currentSide)
    vr.position(1)=0;
    vr.position(2)=0;
    vr.position(4) = 0;
    end
end

%world settings
if strcmp(vr.keyPressed, '1')
    vr.currentWorld = vr.currentWorld + 1;
     
    vr.position(1)=0;
    vr.position(2)=0;
    vr.position(4) = 0;
    disp ([' the current world is ' num2str(vr.currentWorld)])
end
if strcmp(vr.keyPressed,'2')
    vr.currentWorld = vr.currentWorld-1;
 
    vr.position(1)=0;
    vr.position(2)=0;
    vr.position(4) = 0;
    disp ([' the current world is ' num2str(vr.currentWorld)])
end

%safety world increase/decrease
if vr.currentWorld == 0
    vr.currentWorld = vr.currentWorld + 1; 
    vr.position(1)=0;
    vr.position(2)=0;
    vr.position(4) = 0;
    disp ([' the current world is ' num2str(vr.currentWorld)])
end
if vr.currentWorld == 9
    vr.currentWorld = vr.currentWorld-1;
    disp ([' the current world is ' num2str(vr.currentWorld)])
     vr.position(1)=0;
    vr.position(2)=0;
    vr.position(4) = 0;
end

    


% --- TERMINATION code: executes after the ViRMEn engine stops.
function vr = terminationCodeFun(vr)
disp(['The animal recieved ' num2str(vr.numReward) ' rewards.'])
