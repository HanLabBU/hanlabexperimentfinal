classdef HBoxFlex < uiextras.HBox
    %HBoxFlex  a dynamically resizable horizontal layout
    %
    %   obj = uiextras.HBoxFlex() creates a new dynamically resizable
    %   horizontal box layout with all parameters set to defaults. The
    %   output is a new layout object that can be used as the parent for
    %   other user-interface components.
    %
    %   obj = uiextras.HBoxFlex(param,value,...) also sets one or more
    %   parameter values.
    %
    %   See the <a href="matlab:doc uiextras.HBoxFlex">documentation</a> for more detail and the list of properties.
    %
    %   Examples:
    %   >> f = figure( 'Name', 'uiextras.HBoxFlex example' );
    %   >> b = uiextras.HBoxFlex( 'Parent', f );
    %   >> uicontrol( 'Parent', b, 'Background', 'r' )
    %   >> uicontrol( 'Parent', b, 'Background', 'b' )
    %   >> uicontrol( 'Parent', b, 'Background', 'g' )
    %   >> uicontrol( 'Parent', b, 'Background', 'y' )
    %   >> set( b, 'Sizes', [-1 100 -2 -1], 'Spacing', 5 );
    %
    %   See also: uiextras.VBoxFlex
    %             uiextras.HBox
    %             uiextras.Grid
    
    
    %  Copyright 2009 The MathWorks, Inc.
    %  $Revision: 199 $ $Date: 2010-06-18 15:55:16 +0100 (Fri, 18 Jun 2010) $
    
    %% Private properties
    properties (SetAccess='private',GetAccess='private')
        SelectedDivider = -1
    end % Private properties
    
    %% Public methods
    methods
        
        function obj = HBoxFlex( varargin )
            % Pass inputs to superclass
            obj@uiextras.HBox( varargin{:} );

            % Set properties
            if nargin > 0
                set( obj, varargin{:} );
            end
        end % constructor
        
    end % Public methods
    
    %% Protected methods
    methods( Access = 'protected' )
        
        function redraw( obj )
            %REDRAW  Redraw container contents.

            % Remove dividers before computing sizes so that the dividers
            % don't appear as children
            delete( findall( obj.UIContainer, 'Tag', 'HBoxFlex:Divider' ) );

            % Now simply call the grid redraw
            [widths,heights] = redraw@uiextras.HBox(obj);
            sizes = obj.Sizes;
            nChildren = numel( obj.Children );
            padding = obj.Padding;
            spacing = obj.Spacing;

            % Now also add some dividers
            mph = uiextras.MousePointerHandler( obj.Parent );
            for ii = 1:nChildren-1
                if any(sizes(1:ii)<0) && any(sizes(ii+1:end)<0)
                    % Both dynamic, so add a divider
                    position = [sum( widths(1:ii) ) + padding + spacing * (ii-1) + 1, ...
                        padding + 1, ...
                        max(1,spacing), ...
                        heights(ii)];
                    uic = uicontrol( 'Parent', obj.UIContainer, ...
                        'Style', 'frame', ...
                        'BackgroundColor', get( obj.UIContainer, 'BackgroundColor' ), ...
                        'ForegroundColor', get( obj.UIContainer, 'BackgroundColor' ), ...
                        'HitTest', 'on', ...
                        'Enable', 'off', ...
                        'ButtonDownFcn', @obj.onButtonDown, ...
                        'Position', position, ...
                        'HandleVisibility', 'off', ...
                        'Tag', 'HBoxFlex:Divider' );
                    setappdata( uic, 'WhichDivider', ii );
                    setappdata( uic, 'OriginalPosition', position );
                    mph.register( uic, 'left' );
                end
            end
        end % redraw
        
        function onButtonDown( obj, source, eventData ) %#ok<INUSD>
            figh = ancestor( source, 'figure' );
            % We need to store any existing motion callbacks so that we can
            % restore them later.
            oldProps = struct();
            oldProps.WindowButtonMotionFcn = get( figh, 'WindowButtonMotionFcn' );
            oldProps.WindowButtonUpFcn = get( figh, 'WindowButtonUpFcn' );
            oldProps.Pointer = get( figh, 'Pointer' );
            
            % Make sure all interaction modes are off to prevent our
            % callbacks being clobbered
            zoomh = zoom( figh );
            r3dh = rotate3d( figh );
            panh = pan( figh );
            oldState = '';
            if isequal( zoomh.Enable, 'on' )
                zoomh.Enable = 'off';
                oldState = 'zoom';
            end
            if isequal( r3dh.Enable, 'on' )
                r3dh.Enable = 'off';
                oldState = 'rotate3d';
            end
            if isequal( panh.Enable, 'on' )
                panh.Enable = 'off';
                oldState = 'pan';
            end
            
            % Now set the new callbacks
            set( figh, ...
                'WindowButtonMotionFcn', @obj.onButtonMotion, ...
                'WindowButtonUpFcn', {@obj.onButtonUp, oldProps, oldState}, ...
                'Pointer', 'left' );
            % Make the divider visible
            set( source, ...
                'BackgroundColor', 0.5*get( obj.UIContainer, 'BackgroundColor' ), ...
                'ForegroundColor', 0.3*get( obj.UIContainer, 'BackgroundColor' ) );
            obj.SelectedDivider = source;
        end % onButtonDown
        
        function onButtonMotion( obj, source, eventData ) %#ok<INUSD>
            figh = ancestor( source, 'figure' );
            cursorpos = get( figh, 'CurrentPoint' );
            pos0 = getpixelposition( obj.UIContainer, true );
            dividerpos = get( obj.SelectedDivider, 'Position' );
            dividerpos(1) = cursorpos(1) - pos0(1) - round(obj.Spacing/2) + 1;
            set( obj.SelectedDivider, 'Position', dividerpos );
        end % onButtonMotion
        
        function onButtonUp( obj, source, eventData, oldFigProps, oldState )
            % Restore figure properties
            figh = ancestor( source, 'figure' );
            flds = fieldnames( oldFigProps );
            for ii=1:numel(flds)
                set( figh, flds{ii}, oldFigProps.(flds{ii}) );
            end
            % Deliberately call the motion function to ensure any last
            % movement is captured
            obj.onButtonMotion( source, eventData );
            
            % If the figure has an interaction mode set, re-set it now
            if ~isempty( oldState )
                switch upper( oldState )
                    case 'ZOOM'
                        zoom( figh, 'on' );
                    case 'PAN'
                        zoom( figh, 'on' );
                    case 'ROTATE3D'
                        rotate3d( figh, 'on' );
                    otherwise
                        error( 'UIExtras:FlexLayout:BadInteractionMode', 'Interaction mode ''%s'' not recognised', oldState );
                end
            end
            
            % Work out which divider was moved and which are the resizable
            % elements either side of it
            newPos = get( obj.SelectedDivider, 'Position' );
            origPos = getappdata( obj.SelectedDivider, 'OriginalPosition' );
            whichDivider = getappdata( obj.SelectedDivider, 'WhichDivider' );
            obj.SelectedDivider = -1;
            delta = newPos(1) - origPos(1) - round(obj.Spacing/2) + 1;
            sizes = obj.Sizes;
            
            % Convert all flexible sizes into pixel units
            totalPosition = ceil( getpixelposition( obj.UIContainer ) );
            totalWidth = totalPosition(3);
            widths = obj.calculatePixelSizes( totalWidth );
            
            leftelement = find( sizes(1:whichDivider)<0, 1, 'last' );
            rightelement = find( sizes(whichDivider+1:end)<0, 1, 'first' )+whichDivider;
            
            % Now work out the new sizes. Note that we must ensure the size
            % stays negative otherwise it'll stop being resizable
            change = sum(sizes(sizes<0)) * delta / sum( widths(sizes<0) );
            sizes(leftelement) = min( -0.000001, sizes(leftelement) + change );
            sizes(rightelement) = min( -0.000001, sizes(rightelement) - change );
            
            % Setting the sizes will cause a redraw
            obj.Sizes = sizes;
        end % onButtonUp
        
        function onBackgroundColorChanged( obj, source, eventData ) %#ok<INUSD>
            %onBackgroundColorChanged  Callback that fires when the container background color is changed
            %
            % We need to make the dividers match the background, so redarw
            % them
            obj.redraw();
        end % onChildRemoved
        
    end % Protected methods
    
end % classdef