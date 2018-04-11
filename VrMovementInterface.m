classdef VrMovementInterface < hgsetget
    
    properties
        sensors = {'1','2'}
        mouse1
        mouse2
    end
    properties
        serialObj
        serialTag
        serialPort = 'COM1' %CHANGE BY KD FROM COM1
        serialBaudRate = 9600
		
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
                    obj.(varargin(i))= obj.(varargin(i+1));
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
                        obj.createLogBox
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
                    msg = fscanf(obj.serialObj,'%s\n');
%                     msg = fscanf(obj.serialObj,'%s');
                else
                    flushinput(obj.serialObj);
                    return
                end
                msg = msg(:)';  % make character array horizontal
                msg = obj.parsedeltas(msg);%',d);
				if ~isempty(msg)
					notify(obj,'DataReceived',arduinoSerialMsg(msg))%TODO
				end
            catch me
                warning(me.message)
                disp(me.stack(1))
                disp(me.stack(2))
            end
        end        
        function start(obj)
            try  
				if ~isvalid(obj.serialObj)
					delete(obj.serialObj)
					obj.serialObj = serial(obj.serialPort);
					set(obj.serialObj,...
						'BytesAvailableFcn',@(src,evnt)readSerialFcn(obj,src,evnt),...
						'BaudRate',obj.serialBaudRate,...
						'FlowControl','hardware');
				end
				fopen(obj.serialObj);
                disp('STARTING VrMovementInterface')
            catch err
                disp(err.message);
                disp(err.stack(1))
                disp(err.stack(2))
				instrhwinfo('serial') %KD
				delete(instrfindall); %KD
				obj.serialObj = serial(obj.serialPort);
                set(obj.serialObj,...
                    'BytesAvailableFcn',@(src,evnt)readSerialFcn(obj,src,evnt),...
                    'BaudRate',obj.serialBaudRate,...
                    'FlowControl','hardware');
				fopen(obj.serialObj);
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
			try
				if isempty(msg)
					msg = NaN;
					return
				end				
				sensornum = msg(1);
				if ~any(strcmp(sensornum,obj.sensors))
					msg = [];
					return
                end
%                 disp(msg)
%                 fprintf(msg);
				x_index = regexp(msg,'[x]*');
				y_index = regexp(msg,'[y]*');
% 				            fprintf('\t %s\n',msg)
				dx = str2double(msg(x_index+1:y_index-1));
				dy = str2double(msg(y_index+1:end));
				if isa(dx,'double') && isa(dy,'double')
                    obj.(sprintf('mouse%s',sensornum)).dx = dx;
                    obj.(sprintf('mouse%s',sensornum)).dy = dy;
                end
%                 disp(obj.(sprintf('mouse%s',sensornum)).dy)
%                 disp(obj.(sprintf('mouse%s',sensornum)).dx);
   				obj.writeLogMsg(msg)
			catch me
				warning(me.message)
			end
        end
        function createLogBox(obj,varargin)
            if isempty(varargin)
                msg = datestr(now);
            else
                msg = varargin{1};
            end
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
				fclose('all')
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
if ishandle(obj)
		obj.showLog = 'no';
end
end
