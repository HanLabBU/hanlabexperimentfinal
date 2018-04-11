function code = Cakesprinkles_var
% Cakesprinkles_var   Code for the ViRMEn experiment Cakesprinkles_var.
%   code = Cakesprinkles_var   Returns handles to the functions that ViRMEn
%   executes during engine initialization, runtime and termination.


% Begin header code - DO NOT EDIT
code.initialization = @initializationCodeFun;
code.runtime = @runtimeCodeFun;
code.termination = @terminationCodeFun;
% End header code - DO NOT EDIT
end





% --- INITIALIZATION code: executes before the ViRMEn engine starts.
function vr = initializationCodeFun(vr)
    %set variables
    floor_width = eval(vr.exper.variables.floor_width);
    vr.exper.variables.th = 1;
    vr.th =(vr.exper.variables.th);
    disp(vr.th)
   
    
    disp (vr.worlds{vr.currentWorld}.objects.vertices)
    
    disp (vr.worlds{vr.currentWorld}.objects.indices)
    % vr.target_size = eval(vr.exper.variables.target_size);
    % target_size = (eval(vr.exper.variables.floor_width))/3 ...
    %      - (eval(vr.exper.variables.floor_width))*(eval(vr.exper.variabls.th))-3;


    vr.change_size = 'r';% set currentside value

    vr.numRewards = 0;%track rewards

    vr.window.TopMost = false;%full screen off

    w = vr.worlds{vr.currentWorld};

    %set NW target triangles
    vr.NWindx = w.objects.indices.NWtarget;
    NWvertexFirstLast = vr.worlds{vr.currentWorld}.objects.vertices(vr.NWindx,:);
    vr.NWtargetIndx = NWvertexFirstLast(1):NWvertexFirstLast(2);

    %set W target triangles
    vr.Windx = w.objects.indices.Wtarget;
    WvertexFirstLast = vr.worlds{vr.currentWorld}.objects.vertices(vr.Windx,:);
    vr.WtargetIndx = WvertexFirstLast(1):WvertexFirstLast(2);

    %set SW target triangles
    vr.SWindx = w.objects.indices.SWtarget;
    SWvertexFirstLast = vr.worlds{vr.currentWorld}.objects.vertices(vr.SWindx,:);
    vr.SWtargetIndx = SWvertexFirstLast(1):SWvertexFirstLast(2);

    %set NE target triangles
    vr.NEindx = w.objects.indices.NEtarget;
    NEvertexFirstLast = vr.worlds{vr.currentWorld}.objects.vertices(vr.NEindx,:);
    vr.NEtargetIndx = NEvertexFirstLast(1):NEvertexFirstLast(2);

    %set E target triangles
    vr.Eindx = w.objects.indices.Etarget;
    EvertexFirstLast = vr.worlds{vr.currentWorld}.objects.vertices(vr.Eindx,:);
    vr.EtargetIndx = EvertexFirstLast(1):EvertexFirstLast(2);

    %set SE target triangles
    vr.SEindx = w.objects.indices.SEtarget;
    SEvertexFirstLast = vr.worlds{vr.currentWorld}.objects.vertices(vr.SEindx,:);
    vr.SEtargetIndx = SEvertexFirstLast(1):SEvertexFirstLast(2);

    %set target color
    vr.worlds{vr.currentWorld}.surface.colors(4,vr.NEtargetIndx) = 0;
    vr.worlds{vr.currentWorld}.surface.colors(4,vr.EtargetIndx) = 0;
    vr.worlds{vr.currentWorld}.surface.colors(4,vr.SEtargetIndx) = 0;
    vr.worlds{vr.currentWorld}.surface.colors(4,vr.NWtargetIndx) = 0;
    vr.worlds{vr.currentWorld}.surface.colors(4,vr.WtargetIndx) = 0;
    vr.worlds{vr.currentWorld}.surface.colors(4,vr.SWtargetIndx) =1;
    vr.currentSquare = vr.SWtargetIndx;
end

% --- RUNTIME code: executes on every iteration of the ViRMEn engine.
function vr = runtimeCodeFun(vr)
%generate variable vr.target_size
vr.floor_width = eval(vr.exper.variables.floor_width);
%disp(['Floor Width ' (vr.floor_width)])
vr.th =(vr.exper.variables.th);
%disp(['percetentage ' (vr.th)])

vr.target_size = ((vr.floor_width/3 - 3)*vr.th);
%disp(['Target size ' (vr.target_size)])




%check which side is right, with keyboard input
% if ~isnan(vr.keyPressed) && ~isempty(str2double(vr.keyPressed))
%     vr.change_size = vr.keyPressed;
%     disp(vr.change_size)
% end



%change NW target to black
if (vr.position(1)>(-vr.floor_width/4 - vr.target_size/2)...
        &(vr.position(1)<(-vr.floor_width/4 + vr.target_size/2))...
        &(vr.position(2)<(vr.floor_width/3 + vr.target_size/2))... 
        &(vr.position(2)>(vr.floor_width/3 - vr.target_size/2)))
    if vr.worlds{vr.currentWorld}.surface.colors(4,vr.NWtargetIndx) == 1
        vr.numRewards = vr.numRewards + 1; %check condition for reward
    end
   vr.currentSquare = vr.NWtargetIndx;
    vr.worlds{vr.currentWorld}.surface.colors(4,vr.NWtargetIndx) = 0;
end

%change W target to black
if (vr.position(1)>(-vr.floor_width/4 - vr.target_size/2))...
        &(vr.position(1)<(-vr.floor_width/4 + vr.target_size/2))...
        &(vr.position(2)<vr.target_size/2)...
        &(vr.position(2)>-vr.target_size/2)
    if vr.worlds{vr.currentWorld}.surface.colors(4,vr.WtargetIndx) == 1
        vr.numRewards = vr.numRewards + 1;
    end
    vr.currentSquare = vr.WtargetIndx;
    vr.worlds{vr.currentWorld}.surface.colors(4,vr.WtargetIndx) = 0;
end

%change SW target to black
if (vr.position(1)>(-vr.floor_width/4 - vr.target_size/2))...
        &(vr.position(1)<(-vr.floor_width/4 + vr.target_size/2))...
        &(vr.position(2)>(-vr.floor_width/3 - vr.target_size/2))...
        &(vr.position(2)<(-vr.floor_width/3 + vr.target_size/2))
    if vr.worlds{vr.currentWorld}.surface.colors(4,vr.SWtargetIndx) == 1
        vr.numRewards = vr.numRewards + 1;
    end
    vr.currentSquare = vr.SWtargetIndx;
    vr.worlds{vr.currentWorld}.surface.colors(4,vr.SWtargetIndx) = 0;
end

%change NE target to black
if (vr.position(1)<(vr.floor_width/4 + vr.target_size/2))...
        &(vr.position(1)>(vr.floor_width/4 - vr.target_size/2))...
        &(vr.position(2)<(vr.floor_width/3 + vr.target_size/2))...
        &(vr.position(2)>(vr.floor_width/3 - vr.target_size/2))
    if vr.worlds{vr.currentWorld}.surface.colors(4,vr.NEtargetIndx) == 1
        vr.numRewards = vr.numRewards + 1;
    end
   vr.currentSquare = vr.NEtargetIndx;
    vr.worlds{vr.currentWorld}.surface.colors(4,vr.NEtargetIndx) = 0;
end

%change E to black
if (vr.position(1)<(vr.floor_width/4 + vr.target_size/2))...
        &(vr.position(1)>(vr.floor_width/4 - vr.target_size/2))...
        &(vr.position(2)<vr.target_size/2)...
        &(vr.position(2)>-vr.target_size/2)
    if vr.worlds{vr.currentWorld}.surface.colors(4,vr.EtargetIndx) == 1
        vr.numRewards = vr.numRewards + 1;
    end
    vr.currentSquare = vr.EtargetIndx;
    vr.worlds{vr.currentWorld}.surface.colors(4,vr.EtargetIndx) = 0;
end

%change SE to black
if (vr.position(1)<(vr.floor_width/4 + vr.target_size/2))...
        &(vr.position(1)>(vr.floor_width/4 - vr.target_size/2))...
        &(vr.position(2)<(-vr.floor_width/3 + vr.target_size/2))...
        &(vr.position(2)>(-vr.floor_width/3 - vr.target_size/2))
    if vr.worlds{vr.currentWorld}.surface.colors(4,vr.SEtargetIndx) == 1
        vr.numRewards = vr.numRewards + 1;
    end
     vr.currentSquare = vr.SEtargetIndx;
    vr.worlds{vr.currentWorld}.surface.colors(4,vr.SEtargetIndx) = 0;
end

%color reset
if (vr.worlds{vr.currentWorld}.surface.colors(4,vr.NEtargetIndx) == 0)...
        &(vr.worlds{vr.currentWorld}.surface.colors(4,vr.SEtargetIndx) == 0)...
        &(vr.worlds{vr.currentWorld}.surface.colors(4,vr.NWtargetIndx) == 0)...
        &(vr.worlds{vr.currentWorld}.surface.colors(4,vr.WtargetIndx) == 0)...
        &(vr.worlds{vr.currentWorld}.surface.colors(4,vr.SWtargetIndx) == 0)...
        &(vr.worlds{vr.currentWorld}.surface.colors(4,vr.EtargetIndx) == 0);
    
    allSquares = {vr.NEtargetIndx,...
        vr.EtargetIndx,...
        vr.SEtargetIndx,...
        vr.NWtargetIndx,...
        vr.WtargetIndx,...
        vr.SWtargetIndx};
    randSquare = allSquares{ceil(rand*6)};
    if vr.currentSquare == randSquare
        randSquare = allSquares{ceil(rand*6)};
    end
%     if ~isempty(currentSquare)
%         while randSquare == currentSquare
%             randSquare = allSquares(ceil(rand*6));
%         end
%     end
    vr.worlds{vr.currentWorld}.surface.colors(4,randSquare) = 1;
    %              vr.numRewards = vr.numRewards - 1;
end
%     
    %reduction loops
%     if (strcmp(vr.change_size,'c'))
%      pause (5)
%      vr.th = input('enter percentage here in form of a decimal ','s');
%         if isempty (vr.th)
%          vr.th = '1';
%         end
%      disp (eval(vr.th))
%      vr.change_size = 'r';
%      vr.new_target_size = eval(vr.th);
%      disp (vr.new_target_size)
%      
%      y = abs(vr.target_size - vr.new_target_size);
%      disp (y)
%      
%     
%      
%      vr.worlds{vr.currentWorld}.surface.vertices(2, vr.NEtargetIndx) ...
%          =  vr.worlds{vr.currentWorld}.surface.vertices(2, vr.NEtargetIndx) - y;
%      
%       disp (vr.worlds{vr.currentWorld}.objects.vertices)
%     
%      disp (vr.worlds{vr.currentWorld}.objects.indices)
    %end
end


% --- TERMINATION code: executes after the ViRMEn engine stops.
function vr = terminationCodeFun(vr)
    disp (['The animal recieved ' num2str(vr.numRewards) ' rewards.'])
    disp (['the target size were ' (num2str(vr.target_size)) ' units.'])
end

