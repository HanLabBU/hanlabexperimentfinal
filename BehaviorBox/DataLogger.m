classdef DataLogger < hgsetget
    % ---------------------------------------------------------------------
    % DataLogger
    % Han Lab
    % 7/11/2011
    % Mark Bucklin
    % ---------------------------------------------------------------------
    %
    %
    %
    % See Also TOUCHDISPLAY BEHAVIORBOX NIDAQINTERFACE
    
    
    
    
    
    properties
        savePath
        experimentName
        showLog
        logBox
        logFig
        experimentNumber
    end
    properties (SetAccess='protected')
        eventListeners
        logFile
        objects2Log
        logDisplayTimer
        isrunning
        default
    end
    
    
    
    
    
    events
    end
    
    
    
    
    methods % Initialization
        function obj = DataLogger(varargin)
            % Assign input arguments to object properties
            if nargin > 1
                for k = 1:2:length(varargin)
                    obj.(varargin{k}) = varargin{k+1};
                end
            end
            % Define Defaults
            obj.default = struct(...
                'savePath',['C:',filesep,...
                'BehaviorBoxData',filesep,...
                ['NoName',datestr(date,'_yyyy_mm_dd')]],...
                'showLog','yes');
            obj.eventListeners = event.listener.empty(1,0);
            obj.isrunning = false;
        end
        function setup(obj)
            % Fill in Defaults
            props = fields(obj.default);
            for n=1:length(props)
                thisprop = sprintf('%s',props{n});
                if isempty(obj.(thisprop))
                    obj.(thisprop) = obj.default.(thisprop);
                end
            end
            if ~isempty(obj.objects2Log)...
                && isempty(obj.eventListeners)
                obj.logObjectEvents(obj.objects2Log);
            end
            % Number experiments if not taken care of externally
            if isempty(obj.experimentNumber)
                obj.experimentNumber = 1;
            end
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
            if obj.isrunning
                stop(obj)
            end
            if isempty(obj.experimentName)
                obj.experimentName = sprintf('expt%0.3d',obj.experimentNumber);
            end
            obj.createLogFile()
            if strcmpi(obj.showLog,'yes')
            obj.createLogBox()
            obj.logDisplayTimer = timer(...
                'TimerFcn',@(src,evnt)logDisplayTimerFcn(obj,src,evnt),...                
                'TasksToExecute',inf,...
                'period',5,...
                'ExecutionMode','FixedDelay');
            end
            [obj.eventListeners.Enabled] = deal(true);
            if ~isempty(obj.logDisplayTimer)
                start(obj.logDisplayTimer)
            end
            obj.isrunning = true;
        end
        function stop(obj)
             [obj.eventListeners.Enabled] = deal(false);
             if ~isempty(obj.logDisplayTimer)
                stop(obj.logDisplayTimer)
             end
             fclose(obj.logFile);
             copyfile(fullfile(obj.savePath,'templog.txt'),...
                    fullfile(obj.savePath,obj.experimentName))
            obj.isrunning = false;
            obj.experimentNumber = obj.experimentNumber+1;
        end
    end
    methods % Event Response
        function eventReceiverFcn(obj,src,evnt)
            if isempty(obj.logFile)              
                return
            end
            if any(strcmp('name',properties(src)))
                srcname = src.name;
            else
                srcname = class(src);
            end
            % Print to LogFile
            fprintf(obj.logFile,'%s:\t%s\t%d\r\n',...
                srcname, evnt.EventName, time);%'time' is a cogent function, time in msec since start_cogent
            % Print to Log Display
            if strcmpi(obj.showLog,'yes') && ishandle(obj.logBox.txtBox)
                logmsg = sprintf('%s: %s\t%d',...
                    srcname, evnt.EventName, time);
                obj.logBox.text = [logmsg ; obj.logBox.text];
                set(obj.logBox.txtBox,'string',obj.logBox.text);
            end
        end
        function logDisplayTimerFcn(obj,src,evnt)
            % Print Blank Space Log Display
            if strcmpi(obj.showLog,'yes') && ishandle(obj.logBox.txtBox)
                logmsg = ' ';
                obj.logBox.text = [logmsg ; obj.logBox.text];
                set(obj.logBox.txtBox,'string',obj.logBox.text);
            end
        end
    end
    methods
        function createLogFile(obj)
            logfileexist = exist(fullfile(obj.savePath,obj.experimentName),'file');
            if  logfileexist == 2 % File Exists
                copyfile(fullfile(obj.savePath,obj.experimentName),...
                    fullfile(obj.savePath,'templog.txt'))
            elseif ~isdir(obj.savePath) % Directory Does Not Exist
                [~,~,~] = mkdir(obj.savePath);
            end
            obj.logFile = fopen(fullfile(obj.savePath, 'templog.txt'),'A');
            openmsg = [obj.experimentName,' ',datestr(now)];
            fprintf(obj.logFile,[openmsg,'\r\n']);
        end
        function createLogBox(obj)
            scz = get(0,'screensize');
            if isempty(obj.logFig)...
                    || ~ishandle(obj.logFig)
                obj.logFig = figure('position',[25 100 350 scz(4)-250],...
				   'handlevisibility','callback');
            end
            obj.logBox.txtBox = uicontrol( ...
                'parent',obj.logFig,...
                'units','normalized',...
                'position',[0 0 1 1],...
                'Style','edit',... %changed from text
                'HorizontalAlignment','left',...
                'DeleteFcn',@(src,evnt)logDisplayClosed(obj,src,evnt),...
                'tag','behavlog',...
                'max',100,...
                'enable','inactive');
            obj.logBox.text = {datestr(now)};
            set(obj.logBox.txtBox,'string',obj.logBox.text);
            obj.logBox.n = 1;
        end
        function logDisplayClosed(obj,src,evnt)
            if ishandle(obj)
                obj.showLog = 'no';
            end
        end
    end
    methods % Cleanup
        function delete(obj)
            try                
                if isvalid(obj)
                    closemsg = ['STOP: ',datestr(now),'\r\n'];
                    if ~isempty(obj.logFile)
                        fprintf(obj.logFile,closemsg);
                        [templogfilestring,~,~,~] = fopen(obj.logFile);
                        fclose(obj.logFile);
                        movefile(templogfilestring,...
                            fullfile(obj.savePath,obj.experimentName));
                    end
                    openfiles = fopen('all');
                    if ~isempty(openfiles)
                        for n = 1:length(openfiles)
                            fclose(openfiles(n));
                        end
                    end
                    if exist(templogfilestring,'file')
                        delete(templogfilestring);
                    end
                    if ~isempty(obj.logBox)
                        close(obj.logFig)
                    end
                    [obj.eventListeners.Enabled] = deal(false);
                    if isvalid(obj.logDisplayTimer)
                        delete(obj.logDisplayTimer)
                    end
                    fclose(obj.logFile);
                    delete(fullfile(obj.savePath, 'templog.txt'))                    
                end
            catch me
                disp(me.stack(1))
                warning(me.message)
                beep
            end
        end
    end
    
end
















