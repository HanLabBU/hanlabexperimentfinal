classdef VrMovementInterface < hgsetget
    
    properties
        sensors = {'1','2'}
        mouse1
        mouse2
    end
    properties
        serialObj
        serialTag
        serialPort = 'COM1' % 'COM1' ?% comment added by Mike
        serialBaudRate = 115200
    end
    properties
        logBox
        showLog = 'no'
    end
    properties (SetObservable)
        state = 'ready'
    end
    
    
    
    
    events
        DataReceived
    end
    
    
    
    
    methods
        function obj = VrMovementInterface(varargin)
            if nargin > 1
                for i = 1:2:length(varargin)
                    obj.(varargin{i})= varargin{i+1};
                end
            else
                obj.serialObj = serial(obj.serialPort);
                set(obj.serialObj,...
                    'BytesAvailableFcn',@(src,evnt)readSerialFcn(obj,src,evnt),...
                    'BaudRate',obj.serialBaudRate,...
                    'FlowControl','hardware');
                obj.mouse1 = Sensor('1');
                obj.mouse2 = Sensor('2');
                
                if isempty(obj.showLog)
                    choice = questdlg('Display VrMovementInterface Log?');
                    if strcmpi(choice,'yes')
                        obj.showLog = 'yes';
                        
                    else
                        obj.showLog = 'no';
                    end
                    
                end
                %obj.start;
            end
        end
        function msg = readSerialFcn(obj,~,~)
            try
                if strcmp(obj.state,'running')
                    msg = fscanf(obj.serialObj,'%s');
                else
                    flushinput(obj.serialObj);
                    msg = fscanf(obj.serialObj,'%s');
                    return
                end
                msg = msg(:)';  % make character array horizontal
                msg = obj.parsedeltas(msg);%',d);
                notify(obj,'DataReceived',arduinoSerialMsg(msg))%TODO
            catch me
                warning(me.message)
                disp(me.stack(1))
                disp(me.stack(2))
            end
        end
        function start(obj)
            try
                if strcmpi(obj.showLog,'yes')
                    obj.createLogBox;
                end
                disp('starting listener')
                fopen(obj.serialObj);
                disp('started!')
            catch err
                disp(err.message);
                disp(err.stack(1))
                disp(err.stack(2))
            end
            obj.state = 'running';
        end
        function stop(obj)
            try
                disp('stopping...')
                fclose(obj.serialObj);%todo: cleanup with instrument control toolbox tools
                disp('stopped!')
            catch err
                disp(err);
            end
        end
        function msg = parsedeltas(obj,msg)
            if isempty(msg)
                msg = NaN;
                return
            end
            sensornum = msg(1);
            sensorName = sprintf('mouse%s',sensornum);
            if ~isprop(obj, sensorName)
                return;
            end
            x_index = regexp(msg,'[x]*');
            y_index = regexp(msg,'[y]*');
            %             fprintf('\t %s\n',msg)
            dx = str2double(msg(x_index+1:y_index-1));
            dy = str2double(msg(y_index+1:end));
            if isa(dx,'double') && isa(dy,'double')
                obj.(sensorName).dx = dx;
                obj.(sensorName).dy = dy;
            end
            %fprintf('%s %d %d \n',obj.(sprintf('mouse%s',sensornum)).side,obj.(sprintf('mouse%s',sensornum)).dx,obj.(sprintf('mouse%s',sensornum)).dy)
            %             fprintf('%s dx=%d dy=%d\n',sensornum,dx,dy);
            obj.writeLogMsg(msg)
        end
        function createLogBox(obj,varargin)
            if isempty(varargin)
                msg = datestr(now);
            else
                msg = varargin{1};
            end
            if isempty(obj.logBox)
                obj.logBox = struct('fig',[],'txtBox',[],'text',[],'n',[]);
                scz = get(0,'screensize');
                obj.logBox.fig = figure('position',[25 100 350 scz(4)-150]);
                obj.logBox.txtBox = uicontrol( ...
                    'parent',obj.logBox.fig,...
                    'units','normalized',...
                    'position',[0 0 1 1],...
                    'Style','text',... %changed from list
                    'HorizontalAlignment','left',...
                    'DeleteFcn',{@logDisplayClosed,obj},...
                    'tag','behavlog',...
                    'BusyAction','cancel',...
                    'max',100,...
                    'enable','on');                
            end
            obj.logBox.text = {msg};
            set(obj.logBox.txtBox,'string',obj.logBox.text);
            obj.logBox.n = 1;
        end
        function writeLogMsg(obj,logmsg)
            persistent nomovement
            % adapted from BehavControlInterface in FrameSynx package
            try
                if strcmpi(obj.showLog,'yes') && ishandle(obj.logBox.txtBox)
                    if strfind(logmsg,'x0y0')
                        if ~isempty(nomovement)
                            obj.logBox.text{1} = sprintf('no movement: %1.2f',toc);
                        else
                            nomovement = true;
                            obj.logBox.text = ['no movement:       ';obj.logBox.text];
                        end
                    else
                        tic
                        nomovement = [];
                        obj.logBox.text = [logmsg ; obj.logBox.text];
                    end
                    set(obj.logBox.txtBox,'string',obj.logBox.text);
                end
            catch me
                warning(me.message)
                me.stack(1)
                me.stack(2)
            end
        end
        function delete(obj)
            try
                if ~isempty(obj.serialObj) && isvalid(obj.serialObj)
                    fclose(obj.serialObj);
                    delete(obj.serialObj);
                end
            catch me
                disp(me.message)
                disp(me.stack(1))
                delete(obj.serialObj);
            end
            instrreset
        end
    end
end













% Utility Functions
function logDisplayClosed(~,~,obj)
persistent closing
if isempty(closing)
    closing = true;
    if ishandle(obj)
        obj.showLog = 'no';
    end
    obj.logBox = struct('fig',[],'txtBox',[],'text',[],'n',[]);
    closing = [];
end
end
