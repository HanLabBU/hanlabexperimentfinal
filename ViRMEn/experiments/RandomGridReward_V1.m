function code = RandomGridReward_V1
% RandomGridReward_V1   Code for the ViRMEn experiment RandomGridReward_V1.
%   code = RandomGridReward_V1   Returns handles to the functions that ViRMEn
%   executes during engine initialization, runtime and termination.


% Begin header code - DO NOT EDIT
code.initialization = @initializationCodeFun;
code.runtime = @runtimeCodeFun;
code.termination = @terminationCodeFun;
% End header code - DO NOT EDIT



% --- INITIALIZATION code: executes before the ViRMEn engine starts.
function vr = initializationCodeFun(vr)
vr = initializeDAQ(vr);
vr.rewardDur=0.50; %11/13/12 cd this is now triggering a master 8 
vr.reward_is_on=0; % this equals 1 when solenoid for water is on
vr.tRewardStart=tic;
vr.numRewards = 0;

vr.gridsize = eval(vr.exper.variables.gridsize);
vr.xreward=ceil(rand(1)*sqrt(vr.gridsize));
vr.yreward=ceil(rand(1)*sqrt(vr.gridsize));
vr.floorWidth = eval(vr.exper.variables.floorWidth);
vr.zonewidth = (vr.floorWidth)/sqrt(vr.gridsize);


 vr.pathname = 'C:\Users\tankadmin\Desktop\virmenLogs_cd';
    vr.filename = datestr(now,'yyyymmddTHHMMSS');
    exper = copyVirmenObject(vr.exper); %#ok<NASGU>
    save([vr.pathname '\' vr.filename '.mat'],'exper');
    vr.fid = fopen([vr.pathname '\' vr.filename '.dat'],'w');
    vr.isStarting = true;


% --- RUNTIME code: executes on every iteration of the ViRMEn engine.
function vr = runtimeCodeFun(vr)
x=vr.position(1);
y=vr.position(2);

if toc(vr.tRewardStart)>=vr.rewardDur
    turnOffReward(vr);
    vr.reward_is_on=0;
end

 
    


if (vr.zonewidth*(vr.xreward-1) < x && x <= vr.zonewidth*vr.xreward) && (vr.zonewidth*(vr.yreward-1) < y && y<= vr.zonewidth*vr.yreward)
   beep
   


    vr.tRewardStart=tic;
    turnOnReward(vr);
    vr.reward_is_on=1;
    vr.numRewards = vr.numRewards + 1;

    
    xrewardnew = ceil(rand(1)*sqrt(vr.gridsize));
    yrewardnew = ceil(rand(1)*sqrt(vr.gridsize));

    
   if xrewardnew == vr.xreward && yrewardnew == vr.yreward
        xrewardnew = ceil(rand(1)*sqrt(vr.gridsize));
        yrewardnew = ceil(rand(1)*sqrt(vr.gridsize));
    else vr.xreward = xrewardnew;
             vr.yreward = yrewardnew;
   end
   

   
end

measurementsToSave = [now vr.position([1 2 4]) vr.velocity([1 2 4]) vr.xreward  vr.yreward vr.reward_is_on];
if vr.isStarting
   vr.isStarting = false;
   fwrite(vr.fid,length(measurementsToSave),'double');
end
fwrite(vr.fid,measurementsToSave,'double');
updateDAQ(vr);
 
%end


% --- TERMINATION code: executes after the ViRMEn engine stops.
function vr = terminationCodeFun(vr)
disp(['The animal received ' num2str(vr.numRewards) ' rewards']);
terminateDAQ(vr);
fclose all;
