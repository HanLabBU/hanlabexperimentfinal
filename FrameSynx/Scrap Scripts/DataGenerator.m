classdef DataGenerator < hgsetget
    
    
    properties
        operatingMode
        imagingMode % (triggered, continuous)
    end
    
    properties (Transient)
        % DataGenerator Controlled Objects
        experimentObj
        currentTrialObj
        previousTrialObj
        bhvListener
        camListener
        
        % Experiment Settings
        firstTrialNumber
        stimulusNumbers%note: need to link to bhvcontrol and user
        currentTrialNumber
        currentImageData
        
        % Working Variables
        dumpedData
        activationHatTime
        frameAcquiredHatTime
        newExperimentHatTime
        camTriggerHatTime
        newTrialHatTime
        stimOnHatTime
        stimShiftHatTime
        stimOffHatTime
    end
    
    properties (Dependent, Transient, Abstract)
        % GUI Controlled Objects
        stimulusPresentationObj
        cameraObj
        illuminationControlObj
        
        % Graphics Handles
        mainAx
        
        % Camera & illumination Settings
        cameraName
        resolution
        frameRate
        channelSequence
        channels
        channelLabels
        
        % Experiment Settings
        stimulusNames%todo: take input from user
        computeTrigAvgOnline
        trigger
        nFramesPreTrigger%numFramesPreStim
        nFramesPostTrigger%numFramesPostStim
        stimOnMinimum%stimOnUseThreshold
        trialLengthMinimum
        animalName
        experimentFileName
        experimentFilePath
        savePath
    end
    
    properties (SetAccess = protected, Hidden)
        
    end
    
    
    
    
    events
        FrameInfoAcquired
        NewExperiment
        NewTrial
        NewStimulus
        NewData
    end
    
    
    
    
    
    
    methods (Abstract)
        
    end
    
    methods
        function obj = DataGenerator(opMode)
            obj.operatingMode = opMode;
            % Set system priority high
            !pv -ph matlab.exe
            % Preallocate any dataset that is updated every frame
            obj.frameAcquiredHatTime = zeros(11000,1);
            
        end
        function delete(obj)
            if ~isempty(obj.stimulusPresentationObj) && ...
                    isvalid(obj.stimulusPresentationObj)
                delete(obj.stimulusPresentationObj)
            end
            if ~isempty(obj.cameraObj) && ...
                    isa(obj.cameraObj,'Camera')
                delete(obj.cameraObj)
            end
            if ~isempty(obj.illuminationControlObj) && ...
                    isvalid(obj.illuminationControlObj)
                delete(obj.illuminationControlObj)
            end
            if ~isempty(obj.experimentObj) && ...
                    isvalid(obj.experimentObj)
                delete(obj.experimentObj)
            end
            if ~isempty(obj.currentTrialObj) && ...
                    isvalid(obj.currentTrialObj)
                delete(obj.currentTrialObj)
            end
            if ~isempty(obj.previousTrialObj) && ...
                    isvalid(obj.previousTrialObj)
                delete(obj.previousTrialObj)
            end
            if ~isempty(imaqfind)
                flushdata(imaqfind)
                delete(imaqfind)
            end
            if ~isempty(instrfind)
                delete(instrfind)
            end
            % 						instrreset
            % 						imaqreset
        end
        function activate(obj)
            setup(obj.cameraObj);
            % 						set(obj.cameraObj,'FramesAcquiredFcn',...
            % 								@(vidObject,event)newFrameFcn(obj,vidObject,event));
            start(obj.cameraObj);
            if isempty(obj.camListener)
                obj.camListener{1} = addlistener(obj.cameraObj,...
                    'FrameAcquired', @(vidObject,event)newFrameFcn(obj,vidObject,event));
            else
                obj.camListener{1}.Enabled = true;
            end
            if ~isempty(obj.illuminationControlObj)
                set(obj.illuminationControlObj,...
                    'dataGeneratorObj',obj,...
                    'cameraObj',obj.cameraObj)
                setup(obj.illuminationControlObj)
            else
                warning('DataGenerator:activate','no illumination')
            end
            if isempty(obj.bhvListener)
                obj.bhvListener{1} = addlistener(obj.stimulusPresentationObj,...
                    'experimentState','PostSet',@(src,evnt)experimentStateChange(obj,src,evnt));
                obj.bhvListener{2} = addlistener(...
                    obj.stimulusPresentationObj,'stimState','PostSet',@(src,evnt)stimStateChange(obj,src,evnt));
                obj.bhvListener{3} = addlistener(...
                    obj.stimulusPresentationObj,'fileName','PostSet',@(src,evnt)makeNewFile(obj,src,evnt));
                obj.bhvListener{4} = addlistener(...
                    obj.stimulusPresentationObj,'currentTrialNumber','PostSet',@(src,evnt)newTrial(obj,src,evnt));
            else
                for n=1:length(obj.bhvListener)
                    obj.bhvListener{n}.Enabled = true;
                end
            end
            obj.activationHatTime = hat;
        end
        function deactivate(obj)
            try
                if ~isempty(obj.cameraObj)
                    obj.camListener{1}.Enabled = false;
                end
                if ~isempty(obj.stimulusPresentationObj)
                    for n=1:length(obj.bhvListener)
                        obj.bhvListener{n}.Enabled = false;
                    end
                else
                    delete(obj.bhvListener);
                    obj.bhvListener = [];
                end
                if islogging(obj.cameraObj)
                    stop(obj.cameraObj);
                end
                if ~isrunning(obj.cameraObj)
                    start(obj.cameraObj)
                end
            catch me
                warning(me.message)
            end
        end
        function makeNewFile(obj,~,~) % New Experiment
            if ~isempty(obj.experimentObj)
                delete(obj.experimentObj)
            end
            obj.experimentObj = [];
            obj.currentTrialObj = [];
            obj.previousTrialObj = [];
            obj.firstTrialNumber = [];
            mkdir(obj.experimentFilePath);
            mkdir(fullfile(obj.experimentFilePath,'TrialFiles'))
            obj.experimentObj = Experiment('dataGeneratorObj',obj);
%             expName = obj.experimentFileName(1:4);
%             assignin('base',lower(expName),obj.experimentObj);
            notify(obj,'NewExperiment');
        end
        function experimentStateChange(obj,~,~)
            try
                experimentState = obj.stimulusPresentationObj.experimentState;
                switch experimentState%TODO: Add in support for triggered imagingMode
                    case 'start exp'
                        obj.newExperimentHatTime = obj.stimulusPresentationObj.lastMsgHatTime - obj.activationHatTime;
                        if ~islogging(obj.cameraObj)
                            trigger(obj.cameraObj);
                            obj.camTriggerHatTime = hat - obj.activationHatTime;
                        end
                        % 												stoppreview(obj.cameraObj)
                    case 'unpause' % Note: BhvControl doesn't send pause signals correctly
                        if ~islogging(obj.cameraObj)
                            trigger(obj.cameraObj);
                        end
                        % 												stoppreview(obj.cameraObj)
                    case 'pause exp'
                        if islogging(obj.cameraObj)
                            stop(obj.cameraObj)
                        end
                        start(obj.cameraObj)
                    case 'finished'
                        stop(obj.cameraObj)
                        endCurrentExperiment(obj);
                        start(obj.cameraObj)
                end
            catch me
                warning(me.message)
            end
        end
        function newTrial(obj,~,~)
            try
                % Perform only if Experiment has been initialized
                if ~isempty(obj.stimulusPresentationObj.fileName) && ~isempty(obj.experimentObj)
                    updateTrialNumber()
                    if ~isempty(obj.currentTrialObj) % Need to wrap up previous Trial
                        completePreviousTrial()
                    end
                    initializeNextTrial()
                end
            catch me
                warning(me.message)
            end
            
            function updateTrialNumber()
                if ~isempty(obj.stimulusPresentationObj.currentTrialNumber)
                    if isempty(obj.firstTrialNumber) % First Trial in Experiment
                        obj.firstTrialNumber = obj.stimulusPresentationObj.currentTrialNumber;
                        obj.experimentObj.firstTrialNumber = obj.firstTrialNumber;
                    end
                    obj.currentTrialNumber = obj.stimulusPresentationObj.currentTrialNumber;
                else
                    obj.currentTrialNumber = obj.currentTrialNumber+1;
                end
                obj.newTrialHatTime(obj.experimentObj.relativeTrialNumber) = ...
                    obj.stimulusPresentationObj.lastMsgHatTime - obj.activationHatTime;
            end
            function completePreviousTrial()
                obj.previousTrialObj = obj.currentTrialObj;
                nFrames = sum(obj.experimentObj.frameSyncData.TrialNumber ...
                    == obj.previousTrialObj.number);
                obj.currentImageData = getSomeData(obj.cameraObj,nFrames);%<<<<<<<<<<<<<TODO: change
%                 obj.currentImageData = getSavedData(obj.cameraObj,nFrames);
                notify(obj,'NewData'); % Experiment adds previous Trial
                if ~isempty(obj.previousTrialObj.stimulus) ...
                        && ~isnan(obj.previousTrialObj.stimulus) ... % Check if this stimulus has been shown before
                        && ~any(obj.experimentObj.stimRecord(1:end-1) == obj.previousTrialObj.stimulus)
                    notify(obj,'NewStimulus',stimMsg(obj.previousTrialObj.stimulus))% imaqGUI fills in stim info
                end
            end
            function initializeNextTrial()
                obj.currentTrialObj = Trial(obj.currentTrialNumber);
                if ~isempty(obj.previousTrialObj)
                    notify(obj,'NewTrial',... % imaqGUI updates stim info,vidVisual updates available data
                        trialMsg(obj.currentTrialObj,obj.previousTrialObj))
                else
                    notify(obj,'NewTrial',trialMsg(obj.currentTrialNumber));
                end
            end
        end
        function stimStateChange(obj,~,~)
            try
                if ~isempty(obj.experimentObj)
                    if ~isempty(obj.currentTrialObj)
                        stimState = obj.stimulusPresentationObj.stimState;
                        switch stimState
                            case 'stim on'
                                obj.stimOnHatTime(obj.experimentObj.relativeTrialNumber) = ...
                                    obj.stimulusPresentationObj.lastMsgHatTime - obj.activationHatTime;
                            case 'stim shift'
                                obj.stimShiftHatTime(obj.experimentObj.relativeTrialNumber) = ...
                                    obj.stimulusPresentationObj.lastMsgHatTime - obj.activationHatTime;
                            case 'stim off'
                                obj.stimOffHatTime(obj.experimentObj.relativeTrialNumber) = ...
                                    obj.stimulusPresentationObj.lastMsgHatTime - obj.activationHatTime;
                            otherwise % stim number
                                obj.stimOnHatTime(obj.experimentObj.relativeTrialNumber) = ...
                                    obj.stimulusPresentationObj.lastMsgHatTime - obj.activationHatTime;
                                obj.currentTrialObj.stimulus = obj.stimulusPresentationObj.stimNumber;
                        end
                    end
                end
            catch me
                warning(me.message)
            end
        end
        function newFrameFcn(obj,~,event)
            try
                if ~isempty(obj.experimentObj)
                    acqtime = hat - obj.activationHatTime;
                    frameNum = event.Data.FrameNumber;
                    obj.frameAcquiredHatTime(frameNum) = acqtime;
                    if length(obj.frameAcquiredHatTime) == frameNum %preallocating
                        obj.frameAcquiredHatTime = ...
                            cat(1,obj.frameAcquiredHatTime,zeros(10000,1));
                    end
                    obj.experimentObj.frameSyncData.FrameNumber(frameNum,1) =...
                        frameNum;
                    obj.experimentObj.frameSyncData.AbsTime(frameNum,1) = ...
                        datenum(event.Data.AbsTime);
                    obj.experimentObj.frameSyncData.HatTime(frameNum,1) = ...
                        acqtime;
                    obj.experimentObj.frameSyncData.Channel(frameNum,:) = ...
                        getData(obj.illuminationControlObj,1);
                    obj.experimentObj.frameSyncData.StimStatus(frameNum,1) = ...
                        obj.stimulusPresentationObj.stimStatus;
                    obj.experimentObj.frameSyncData.StimNum(frameNum,1) = ...
                        obj.stimulusPresentationObj.stimNumber;
                    obj.experimentObj.frameSyncData.TrialNumber(frameNum,1) = ...
                        obj.stimulusPresentationObj.currentTrialNumber;
                    obj.experimentObj.frameSyncData.ValidData(frameNum,1) = true;
                    notify(obj,'FrameInfoAcquired');
                end
            catch me
                warning(me.message)%doesn't matter
                disp(me.stack(1))
            end
        end
        function endCurrentExperiment(obj)
            try
                if ~isempty(obj.experimentObj)
                    trimSyncData(obj.experimentObj)
                    experimentFileObjSavePath = fullfile(...
                        obj.experimentObj.exptFilePath,[obj.experimentFileName , '_experiment']);
                    copyfile(which('Experiment.m'),obj.experimentObj.exptFilePath);
                    copyfile(which('Trial.m'),obj.experimentObj.exptFilePath)
                    experimentObject = obj.experimentObj;
                    save(experimentFileObjSavePath, 'experimentObject');
                    clear experimentObject
                    deactivate(obj.experimentObj);
                    obj.currentTrialObj = [];
                    obj.previousTrialObj = [];
                    obj.firstTrialNumber = [];
                    obj.currentImageData = [];
                    obj.experimentObj = [];
                    clear obj.currentTrialObj obj.previousTrialObj  obj.firstTrialNumber
                end
            catch me
                warning(me.message)
                save(experimentFileObjSavePath, 'experimentObject');
                clear experimentObject
                deactivate(obj.experimentObj);
                obj.currentTrialObj = [];
                obj.previousTrialObj = [];
                obj.firstTrialNumber = [];
                obj.currentImageData = [];
                obj.experimentObj = [];
            end
        end
        function saveDumpedData(obj,src,evnt)
            n = length(obj.dumpedData) + 1;
            if n > 1
                obj.dumpedData(n) = evnt.savedData;
            else
                obj.dumpedData = evnt.savedData;
            end
            % TODO deal with the dumped data -> assign it to a trial
        end
    end
    
    
end

























