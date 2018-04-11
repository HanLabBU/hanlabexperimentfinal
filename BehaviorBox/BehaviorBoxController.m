classdef BehaviorBoxController < hgsetget
    % ---------------------------------------------------------------------
    % BehaviorBoxController
    % Han Lab
    % 7/11/2011
    % Mark Bucklin
    % ---------------------------------------------------------------------
    %
    %
    %
    % See Also TOUCHDISPLAY BEHAVIORBOX NIDAQINTERFACE
    
    
    
    
    
    properties
        
        % Figure and UIControl Handles
        mainFig % graphics handles structure        
        panelHandle
        uiHandle
        mainAx
        mainMenu
                
        % GUI Working Variable Set
        default
        pos % structure of position info       
        
        % Shared Variables to Update
        saveRoot
        savePath
    end
    properties (SetAccess='protected')
    end
    properties (Dependent)
        animalName
    end
    
    
    
    
    events
    end
    
    
    
    
    methods % Initialization
        function obj = BehaviorBoxController(varargin)
            % Assign input arguments to object properties
            if nargin > 1
                for k = 1:2:length(varargin)
                    obj.(varargin{k}) = varargin{k+1};
                end
            end
            % Define Defaults
            obj.default = struct(...
                'saveRoot',['C:',filesep,'BehaviorBoxData']);
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
            % Define Positions
            obj.pos = struct(...
                'mainfig',[200 150 450 600]);
            obj.buildFigure();
        end
        function buildFigure(obj)
            mouselist = makenames('mouse',[1 4 6 21]);
            obj.mainFig = figure('units','pixels',...
                'position',obj.pos.mainfig,...
                'menubar','none',...
                'name','Han Lab BehaviorBox Control',...
                'numbertitle','off',...
                'tag','mainfig',...
                'closerequestfcn',@(src,evnt)closeFigFcn(obj,src,evnt),...
                'units','pixels',...
                'numbertitle','off');
            mainLayout = uiextras.HBoxFlex('Parent',obj.mainFig);
            leftpanel = uiextras.VBox('Parent',mainLayout,...
                'Spacing',40,...
                'Padding',10);
            rightpanel = uipanel('Parent',mainLayout);
            set(mainLayout,'Sizes',[390 -1]);
            % Save Path Panel
            obj.panelHandle.savePathPan = uipanel(...
                'Parent',leftpanel,...
                'Title','Save to Directory');
            obj.uiHandle.saveRootChgDirButt = uicontrol(obj.panelHandle.savePathPan,...
                'style','pushbutton',...
                'tag','savefilechangebutt',...
                'units','pixels',...
                'position',[10 10 90 20],...
                'string','Change Root');
            obj.uiHandle.mousePop = uicontrol(obj.panelHandle.savePathPan,...
                'style','popup',...
                'tag','mousepop',...
                'units','pixels',...
                'position',[110 10 100 20],...
                'string',mouselist);
            obj.uiHandle.savePathAutoName = uicontrol(obj.panelHandle.savePathPan,...
                'style','checkbox',...
                'tag','saveautocheck',...
                'units','pixels',...
                'position',[220 10 140 20],...
                'value',1,...
                'string','Use Default Naming');
            if get(obj.uiHandle.savePathAutoName,'value')%is checked
                obj.savePath = fullfile(obj.saveRoot,...
                    [obj.animalName,datestr(date,'_yyyy_mm_dd')]);
            else
                obj.savePath = obj.saveRoot;
            end
            obj.uiHandle.savePathTxt = uicontrol(obj.panelHandle.savePathPan,...
                'style','edit',...
                'tag','savefileedit',...
                'horizontalalignment','left',...
                'units','pixels',...
                'position',[10 40 350 20],...
                'string',obj.savePath);
            set([obj.uiHandle.savePathTxt,...
                obj.uiHandle.saveRootChgDirButt,...
                obj.uiHandle.mousePop,...
                obj.uiHandle.savePathAutoName],...
                'callback',@(src,evnt)savePathControlFcn(obj,src,evnt));
            % Experiment Control panel
            obj.panelHandle.controlPan = uipanel(...
                'Parent',leftpanel,...
                'Title','Experiment Control');
            obj.uiHandle.startStopButton = uicontrol(obj.panelHandle.controlPan,...
                'style','togglebutton',...
                'tag','startstopbutt',...
                'units','pixels',...
                'position',[10 10 150 40],...
                'string','start',...
                'callback',@(src,evnt)startStopControlFcn(obj,src,evnt));
            obj.uiHandle.exptNameTxt = uicontrol(obj.panelHandle.controlPan,...
                'style','edit',...
                'tag','savefileedit',...
                'horizontalalignment','left',...
                'units','pixels',...
                'position',[10 60 150 20],...
                'string','expt001');
            % Experiment Status Panel
            obj.panelHandle.statusPan = uipanel(...
                'Parent',leftpanel,...
                'Title','Experiment Status');
        end
        function savePathControlFcn(obj,src,evnt)
            if src == obj.uiHandle.saveRootChgDirButt
                obj.saveRoot = uigetdir(obj.default.saveRoot);
                if char(obj.saveRoot(end)) ~= char('\')
                    obj.saveRoot = [obj.saveRoot,'\'];
                end
                set(obj.uiHandle.savePathTxt,'string',obj.saveRoot);
                % if savePath is defined by user, savePath and saveRoot
                % are the same.
            end
            if get(obj.uiHandle.savePathAutoName,'value')%is checked
                if char(obj.saveRoot(end)) ~= char('\')
                    obj.saveRoot = [obj.saveRoot,'\'];
                end
                obj.savePath =  fullfile(obj.saveRoot,...
                    [obj.animalName,datestr(date,'_yyyy_mm_dd')]);
                set(obj.uiHandle.savePathTxt,'string',obj.savePath);
            else
                obj.savePath = get(obj.uiHandle.savePathTxt,'string');
            end
        end
        function startStopControlFcn(obj,src,evnt)
            dbstop if error
            configPanelHandleSet = allchild(obj.panelHandle.savePathPan);
            uihandles = [];
            for n = 1:length(configPanelHandleSet)
                uihandles = [uihandles; findobj(configPanelHandleSet(n),'type','uicontrol')];
            end
            switch get(src,'value')
                case 1 % Button pressed -> Run
                    set(uihandles,'enable','off')
                    %start object====================                   
                        set(src,'enable','on',...
                            'string','Stop')
%                         set(obj.panelHandle.exptStatusTxt,'string','Waiting')                   
                        set(uihandles,'enable','off')
                    
                case 0 % Button pressed -> Stop                  
                    set(src,'string','Start')
%                     set(obj.panelHandle.exptStatusTxt,'string','Stopped')
                    set(uihandles,'enable','on');
            end
            %             catch me
            %                 warning(me.message)
            %                 disp(me.stack(1))
            %                 set(src,'value',~get(src,'value'),'enable','on')
            %             end
            dbclear if error
        end
    end
    methods % Dependent Variables
        function name = get.animalName(obj)
            alist = get(obj.uiHandle.mousePop,'string');
            name = alist{get(obj.uiHandle.mousePop,'value')};
        end
    end
    methods % Cleanup
        function delete(obj)
            if isvalid(obj.mainFig)
                delete(obj.mainFig)
            end
        end
        function closeFigFcn(obj,src,evnt)
            try
                selection = questdlg('Close BehaviorBox Figure?',...
                    'Close Request',...
                    'Yes','No','Yes');%TODO: change to uigetpref preference
                switch selection,
                    case 'Yes'                        
                        delete(gcf)
                        if ishandle(obj.illumControlFig)
                            delete(obj.illumControlFig)
                        end
                        delete(obj)
                        if ~isempty(instrfind)
                            delete(instrfind)
                        end
                        clear obj
                    case 'No'
                        return
                end
            catch me
                warning(me.message)
                delete(gcf)
            end
        end
    end
    
end















