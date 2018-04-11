function code = cakesprinkles
% cakesprinkles   Code for the ViRMEn experiment cakesprinkles.
%   code = cakesprinkles   Returns handles to the functions that ViRMEn
%   executes during engine initialization, runtime and termination.


% Begin header code - DO NOT EDIT
code.initialization = @initializationCodeFun;
code.runtime = @runtimeCodeFun;
code.termination = @terminationCodeFun;
% End header code - DO NOT EDIT



% --- INITIALIZATION code: executes before the ViRMEn engine starts.
function vr = initializationCodeFun(vr)
vr.numRewards = 0;
vr.window.TopMost = false;

w = vr.worlds{vr.currentWorld};

NWindx = w.objects.indices.NWtarget;
NWvertexFirstLast = vr.worlds{vr.currentWorld}.objects.vertices(NWindx,:);
vr.NWtargetIndx = NWvertexFirstLast(1):NWvertexFirstLast(2);

Windx = w.objects.indices.Wtarget;
WvertexFirstLast = vr.worlds{vr.currentWorld}.objects.vertices(Windx,:);
vr.WtargetIndx = WvertexFirstLast(1):WvertexFirstLast(2);

SWindx = w.objects.indices.SWtarget;
SWvertexFirstLast = vr.worlds{vr.currentWorld}.objects.vertices(SWindx,:);
vr.SWtargetIndx = SWvertexFirstLast(1):SWvertexFirstLast(2);

NEindx = w.objects.indices.NEtarget;
NEvertexFirstLast = vr.worlds{vr.currentWorld}.objects.vertices(NEindx,:);
vr.NEtargetIndx = NEvertexFirstLast(1):NEvertexFirstLast(2);

Eindx = w.objects.indices.Etarget;
EvertexFirstLast = vr.worlds{vr.currentWorld}.objects.vertices(Eindx,:);
vr.EtargetIndx = EvertexFirstLast(1):EvertexFirstLast(2);

SEindx = w.objects.indices.SEtarget;
SEvertexFirstLast = vr.worlds{vr.currentWorld}.objects.vertices(SEindx,:);
vr.SEtargetIndx = SEvertexFirstLast(1):SEvertexFirstLast(2);

vr.worlds{vr.currentWorld}.surface.colors(1,vr.NEtargetIndx) = 1;
vr.worlds{vr.currentWorld}.surface.colors(1,vr.EtargetIndx) = 1;
vr.worlds{vr.currentWorld}.surface.colors(1,vr.SEtargetIndx) = 1;
vr.worlds{vr.currentWorld}.surface.colors(1,vr.NWtargetIndx) = 1;
vr.worlds{vr.currentWorld}.surface.colors(1,vr.WtargetIndx) = 1;
vr.worlds{vr.currentWorld}.surface.colors(1,vr.SWtargetIndx) =1;

% --- RUNTIME code: executes on every iteration of the ViRMEn engine.
function vr = runtimeCodeFun(vr)

% if (vr.position(1) == -vr.locationOutsideX:-vr.locationInsideX))&&(vr.position(2)==vr.locationMiddleY:vr.locationMiddleY)
%     vr.numRewards = vr.numRewards + 1;
%     vr.position(1) = 0; 
%     vr.position(2)=0;
% end
% if (vr.position(1) ==-vr.locationOutsideX:-vr.locationInsideX)&&(vr.position(2)==-vr.locationTopOutsideY:-vr.locationTopInsideY)
%     vr.numRewards = vr.numRewards + 1;
%     vr.position(1) = 0; 
%     vr.position(2)=0;
% end
% if (vr.position(1) ==-vr.locationOutsideX:-vr.locationInsideX)&&(vr.position(2)==vr.locationTopOutsideY:vr.locationTopInsideY)
%     vr.numRewards = vr.numRewards + 1;
%     vr.position(1) = 0; 
%     vr.position(2)=0;
% end
% if (vr.position(1) ==vr.locationOutsideX:vr.locationInsideX)&&(vr.position(2)==-vr.locationMiddleY:vr.locationMiddleY)
%     vr.numRewards = vr.numRewards + 1;
%     vr.position(1) = 0; 
%     vr.position(2)=0;
% end
%if (vr.position(1) <vr.locationOutsideX)&&(vr.position(1)>vr.locationInsideX)&&(vr.position(2)>-vr.locationTopOutsideY)&&(vr.position(2)<-vr.locationTopInsideY)
 %vr.numRewards = vr.numRewards + 1;
 %   vr.position(1) = 0; 
 %   vr.position(2)=0;
%end
%if (vr.position(1) <vr.locationOutsideX)&&(vr.position(1)>vr.locationInsideX)&&(vr.position(2)>vr.locationTopOutsideY)&&(vr.position(2)<vr.locationTopInsideY)
   % vr.numRewards = vr.numRewards + 1;
  %  vr.position(1) = 0; 
 %   vr.position(2)=0;
%end
if (vr.position(1)>-37)&&(vr.position(1)<-11)&&(vr.position(2)<45)&&(vr.position(2)>19)
    if vr.worlds{vr.currentWorld}.surface.colors(1,vr.NWtargetIndx) == 1
        vr.numRewards = vr.numRewards + 1;
    end
    vr.worlds{vr.currentWorld}.surface.colors(1,vr.NWtargetIndx) = 0;
end

if (vr.position(1)>-37)&&(vr.position(1)<-11)&&(vr.position(2)<13)&&(vr.position(2)>-13)
    if vr.worlds{vr.currentWorld}.surface.colors(1,vr.WtargetIndx) == 1
        vr.numRewards = vr.numRewards + 1;
    end
    vr.worlds{vr.currentWorld}.surface.colors(1,vr.WtargetIndx) = 0;
end

if (vr.position(1)>-37)&&(vr.position(1)<-11)&&(vr.position(2)>-45)&&(vr.position(2)<-19)
    if vr.worlds{vr.currentWorld}.surface.colors(1,vr.SWtargetIndx) == 1
        vr.numRewards = vr.numRewards + 1;
    end
    vr.worlds{vr.currentWorld}.surface.colors(1,vr.SWtargetIndx) = 0;
end

if (vr.position(1)<37)&&(vr.position(1)>11)&&(vr.position(2)<45)&&(vr.position(2)>19)
    if vr.worlds{vr.currentWorld}.surface.colors(1,vr.NEtargetIndx) == 1
        vr.numRewards = vr.numRewards + 1;
    end
    vr.worlds{vr.currentWorld}.surface.colors(1,vr.NEtargetIndx) = 0;
end

if (vr.position(1)<37)&&(vr.position(1)>11)&&(vr.position(2)<13)&&(vr.position(2)>-13)
    if vr.worlds{vr.currentWorld}.surface.colors(1,vr.EtargetIndx) == 1
        vr.numRewards = vr.numRewards + 1;
    end
    vr.worlds{vr.currentWorld}.surface.colors(1,vr.EtargetIndx) = 0;
end

if (vr.position(1)<37)&&(vr.position(1)>11)&&(vr.position(2)<-19)&&(vr.position(2)>-47)
    if vr.worlds{vr.currentWorld}.surface.colors(1,vr.SEtargetIndx) == 1
        vr.numRewards = vr.numRewards + 1;
    end
    vr.worlds{vr.currentWorld}.surface.colors(1,vr.SEtargetIndx) = 0;
end
if (vr.worlds{vr.currentWorld}.surface.colors(1,vr.NEtargetIndx) == 0)...
        &(vr.worlds{vr.currentWorld}.surface.colors(1,vr.SEtargetIndx) == 0)...
        &(vr.worlds{vr.currentWorld}.surface.colors(1,vr.NWtargetIndx) == 0)...
        &(vr.worlds{vr.currentWorld}.surface.colors(1,vr.WtargetIndx) == 0)...
        &(vr.worlds{vr.currentWorld}.surface.colors(1,vr.SWtargetIndx) == 0)...
        &(vr.worlds{vr.currentWorld}.surface.colors(1,vr.EtargetIndx) == 0)
    vr.worlds{vr.currentWorld}.surface.colors(1,vr.NEtargetIndx) = 1;
    vr.worlds{vr.currentWorld}.surface.colors(1,vr.EtargetIndx) = 1;
    vr.worlds{vr.currentWorld}.surface.colors(1,vr.SEtargetIndx) = 1;
    vr.worlds{vr.currentWorld}.surface.colors(1,vr.NWtargetIndx) = 1;
    vr.worlds{vr.currentWorld}.surface.colors(1,vr.WtargetIndx) = 1;
    vr.worlds{vr.currentWorld}.surface.colors(1,vr.SWtargetIndx) =1;
    vr.numRewards = vr.numRewards - 1;
end

    %if vr.numRewards == 5

    %vr.worlds{vr.currentWorld}.surface.colors(1,vr.NWtargetIndx) = 0;
%     vr.exper.variables.radius = vr.exper.variables.radius - 1;
%     keyboard 
%end




% --- TERMINATION code: executes after the ViRMEn engine stops.
function vr = terminationCodeFun(vr)
disp (['The animal recieved ' num2str(vr.numRewards) ' rewards.'])