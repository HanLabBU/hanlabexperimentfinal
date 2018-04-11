function varargout = startnonvrvr(vr)


timerObj = timer(...
    'BusyMode','queue',...
    'ExecutionMode','fixedRate',...
    'Period',.050,...
    'StartFcn',@expStartFcn,...
    'TimerFcn',@forEachFrame);

start(timerObj)

if nargout < 1
    assignin('base','timerObj',timerObj)
else
    varargout{1} = timerObj;
end

    function expStartFcn(~,~)
        
        notify(vr.vrSystem,'ExperimentStart');
    end

    function forEachFrame(~,~)
        notify(vr.vrSystem,'FrameAcquired',vrMsg(vr))       
    end

    function expStopFcn(~,~)
        notify(vr.vrSystem,'ExperimentStop')
        saveDataFile(vr.vrSystem)
        saveDataSet(vr.vrSystem)
        delete(vr.movementInterface)
    end




end