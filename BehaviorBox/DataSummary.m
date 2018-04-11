classdef DataSummary < hgsetget
    % ---------------------------------------------------------------------
    % DataSummary
    % Han Lab
    % 7/11/2011
    % Mark Bucklin
    % ---------------------------------------------------------------------
    %
    %
    %
    % See Also TOUCHDISPLAY BEHAVIORBOX NIDAQINTERFACE
    
    
    
    
    
    properties
        behaviorBoxObj
        savePath
        relevantEvents
    end
    properties (SetAccess='protected', Hidden)
        eventListeners
        objects2Log
        isrunning
        default
    end
    properties (SetAccess='protected') % Experiment Summary
        experimentNumber
        propSummary
        numTrialStart
        numReward
        numPunish
        numNoResponse
    end
    properties (Dependent)
        percentCorrect
        percentCorrectAttempt
        percentAttempted
        numAttempted       
        numTrials
    end
    
    
    
    
    
    events
    end
    
    
    
    
    methods % Initialization
        function obj = DataSummary(BehaviorBox)
            obj.behaviorBoxObj = BehaviorBox;
            obj.eventListeners = event.listener.empty(1,0);
            obj.isrunning = false;
            obj.savePath = 'C:\BehaviorBoxData\';%================change
            obj.relevantEvents = {...
                'TrialStart',...
                'Reward',...
                'Punish',...
                'NoResponse'};
            obj.logObjectEvents(obj.behaviorBoxObj);
            newExperiment(obj)
        end
        function newExperiment(obj)
            % Number experiments and Save Previous Experiment
            if isempty(obj.experimentNumber)
                obj.experimentNumber = 1;
            else
                stop(obj); %saves summary object
                obj.experimentNumber = obj.experimentNumber+1;
            end
            % Reset Summary Variables
            for n = 1:numel(obj.relevantEvents)
                summary_prop = sprintf('num%s',obj.relevantEvents{n});
                obj.(summary_prop) = 0;
            end
            start(obj);
        end
    end
    methods % User Functions
        function logObjectEvents(obj,o2log)
            if iscell(o2log)
                for p = 1:numel(o2log)
                    obj.logObjectEvents(o2log{p})
                end
            end
            for n = 1:numel(o2log)
                o2f = o2log(n);
                evn = events(o2f);
                for m = 1:numel(evn)
                    ln = numel(obj.eventListeners);
                    obj.eventListeners(ln+1) = addlistener(...
                        o2f,evn{m},...
                        @(src,evnt)eventReceiverFcn(obj,src,evnt));
                end
            end
            [obj.eventListeners.Enabled] = deal(false);
        end
        function start(obj)
            obj.isrunning = true;
            [obj.eventListeners.Enabled] = deal(true);
            % Record Properties of BehaviorBox
            bb_props = properties(obj.behaviorBoxObj);
            for n = 1:numel(bb_props)
                propname = bb_props{n};
                propval = obj.behaviorBoxObj.(propname);
                % Only record character or numeric data
               if isa(propval,'handle') || isa(propval,'timer')
                   break
               else
                   obj.propSummary.(propname) = propval;
               end
            end
        end
        function stop(obj)
            obj.isrunning = false;
            [obj.eventListeners.Enabled] = deal(false);
            % Save Object
            filename = sprintf('DataSummary_Expt%d.mat',...
                obj.experimentNumber);
            filepath = fullfile(obj.savePath,filename);
            datasummary = obj.generateStructure();
            save(filepath,'datasummary');
        end
        function objstruct = generateStructure(obj)
            objstruct = struct();
            propnames = properties(obj);            
            for n = 1:numel(propnames)
                propname = propnames{n};
                propval = obj.(propname);
                % Only record character or numeric data
               if isa(propval,'handle') || isa(propval,'timer')
                   continue
               else
                   objstruct.(propname) = propval;
               end
            end
        end
    end
    methods % Event Response
        function eventReceiverFcn(obj,src,evnt)
            % This function counts/accumulates the number of each relevant
            % event coming from the BehaviorBox            
            if any(strcmp(evnt.EventName,obj.relevantEvents))
               summary_prop = sprintf('num%s',evnt.EventName);
               if isempty(obj.(summary_prop))
                   obj.(summary_prop) = 1;
               else
                   obj.(summary_prop) = obj.(summary_prop) +1;
               end
            end
        end
    end
        
    methods % Get Functions for Dependent Variables
        function val = get.percentCorrect(obj)
            val = 100*(obj.numReward/obj.numTrials);
        end
        function val = get.percentCorrectAttempt(obj)
            val = 100*(obj.numReward/obj.numAttempted);
        end
        function val = get.percentAttempted(obj)
            val = 100*(obj.numAttempted/obj.numTrials);
        end
        function val = get.numAttempted(obj)
            val = obj.numReward + obj.numPunish;
        end
        function val = get.numTrials(obj)
            val = obj.numReward + obj.numPunish + obj.numNoResponse;
        end
    end
    
    methods % Cleanup
        function delete(obj)
         stop(obj)
        end
    end
    
end
















