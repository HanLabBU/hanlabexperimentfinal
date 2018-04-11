classdef MousePointerHandler < handle
    %MousePointerHandler  a class to handle mouse-over events
    %
    %   MousePointerHandler(fig) attaches the handler to the figure FIG
    %   so that it will intercept all mouse-over events. The handler is
    %   stored in the MousePointerHandler app-data of the figure so that
    %   functions can listen in for scroll-events.
    %
    %   Examples:
    %   >> f = figure();
    %   >> u = uicontrol();
    %   >> mph = MousePointerHandler(f);
    %   >> mph.register( u, 'fleur' )
    %
    %   See also: tmwScrollWheelEvent
    
    %   Copyright 2008 The MathWorks Ltd.
    %   $Revision: 199 $   $Date: 2010-06-18 15:55:16 +0100 (Fri, 18 Jun 2010) $
    
    %% Read-only data
    properties (SetAccess='private', GetAccess='public')
        CurrentObject
    end % Read-only data
    
    %% Private data
    properties (SetAccess='private', GetAccess='private')
        CurrentObjectPosition
        OldPointer
        Parent
        List
    end % Private data
    
    %% Public methods
    methods
        function this = MousePointerHandler(fig)
            % Check that a mouse-pointer-handler is not already there
            if ~isa( fig, 'figure' )
                fig = ancestor( fig, 'figure' );
            end
            if isappdata(fig,'MousePointerHandler')
                this = getappdata(fig,'MousePointerHandler');
            else
                set(fig,'WindowButtonMotionFcn', @this.onMouseMoved);
                setappdata(fig,'MousePointerHandler',this);
                this.Parent = fig;
            end
        end % tmwScrollWheelHandler
        
        function register( this, widget, pointer )
            % We need to be sure to remove the entry if it dies
            l = handle.listener( widget, 'ObjectBeingDestroyed', @this.onWidgetBeingDestroyedEvent );
            entry = struct( ...
                'Widget', widget, ...
                'Pointer', pointer, ...
                'Listener', l );
            if isempty(this.List)
                this.List = entry;
            else
                this.List(end+1,1) = entry;
            end
        end % register
    end % Public methods
    
    %% Private methods
    methods (Access='private')
        function onMouseMoved(this,src,evt) %#ok<INUSD>
            if isempty( this.List )
                return;
            end
            currpos = get( this.Parent, 'CurrentPoint' );
%             val = zeros( numel(this.List),4 );
%             for ii=1:numel(this.List)
%               val(ii,:) = getpixelposition( this.List(ii).Widget, true );
%             end
%             disp(val)
            if ~isempty( this.CurrentObjectPosition )
                cop = this.CurrentObjectPosition;
                if currpos(1) >= cop(1) ...
                        && currpos(1) < cop(1)+cop(3) ...
                        && currpos(2) >= cop(2) ...
                        && currpos(2) < cop(2)+cop(4)
                    % Still inside, so do nothing
                    return;
                else
                    % Left the object
                    this.leaveWidget()
                end
            end
            % OK, now scan the objects to see if we're inside
            for ii=1:numel(this.List)
                % We need to be careful of widgets that aren't capable of
                % returning a PixelPosition
                try
                    widgetpos = getpixelposition( this.List(ii).Widget, true );
                    if currpos(1) >= widgetpos(1) ...
                            && currpos(1) < widgetpos(1)+widgetpos(3) ...
                            && currpos(2) >= widgetpos(2) ...
                            && currpos(2) < widgetpos(2)+widgetpos(4)
                        % Inside
                        this.enterWidget( this.List(ii).Widget, this.List(ii).Pointer )
                        break; % we don't need to carry on looking
                    end
                catch err
                    warning( 'MousePointerHandler:BadWidget', 'GETPIXELPOSITION failed for widget %d', ii )
                end
            end
            
        end % onMouseMoved
        
        function onWidgetBeingDestroyedEvent(this,src,evt)
            idx = cellfun( @isequal, {this.List.Widget}, repmat( {double(src)}, 1,numel(this.List) ) );
            this.List(idx) = [];
            % Also take care if it's the active object
            if isequal( src, this.CurrentObject )
                this.leaveWidget()
            end
        end % onWidgetBeingDestroyedEvent
        
        function enterWidget( this, widget, pointer )
            % Mouse has moved onto a widget
%             disp('enter')
            this.CurrentObjectPosition = getpixelposition( widget );
            this.CurrentObject = widget;
            this.OldPointer = get( this.Parent, 'Pointer' );
            set( this.Parent, 'Pointer', pointer );
        end % enterWidget
        
        function leaveWidget( this )
            % Mouse has moved off a widget
%             disp('leave')
            this.CurrentObjectPosition = [];
            this.CurrentObject = [];
            set( this.Parent, 'Pointer', this.OldPointer );
        end % leaveWidget
        
    end % Private methods
    
end % Classdef