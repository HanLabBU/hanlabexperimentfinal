classdef DecoratedPanel < handle
    %DecoratedPanel  Abstract panel class that manages fonts and colors
    %
    %   See also: uiextras.Panel
    %             uiextras.BoxPanel
    %             uiextras.TabPanel
    
    %  Copyright 2009 The MathWorks, Inc.
    %  $Revision: 199 $ $Date: 2010-06-18 15:55:16 +0100 (Fri, 18 Jun 2010) $
    
    %% Public properties
    properties( AbortSet, SetObservable )
        FontAngle       % Title font angle [normal|italic|oblique]
        FontName        % Title font name
        FontSize        % Title font size
        FontUnits       % Title font units [inches|centimeters|normalized|points|pixels]
        FontWeight      % Title font weight [light|normal|demi|bold]
        ForegroundColor % Title font color and/or color of 2-D border line
        HighlightColor  % 3-D frame highlight color [r g b]
        ShadowColor     % 3-D frame shadow color [r g b]
    end % Public properties
    
    %% Private constant properties
    properties( Constant, GetAccess=private )
        AllowedFontAngle = set( 0, 'DefaultUIPanelFontAngle' )
        AllowedFontName = listfonts(0)
        AllowedFontUnits = set( 0, 'DefaultUIPanelFontUnits' )
        AllowedFontWeight = set( 0, 'DefaultUIPanelFontWeight' )
    end % Private constant properties
    
    %% Public methods
    methods
        
        function obj = DecoratedPanel()
            obj.FontAngle  = get( 0, 'DefaultUIPanelFontAngle' );
            obj.FontName   = get( 0, 'DefaultUIPanelFontName' );
            obj.FontSize   = get( 0, 'DefaultUIPanelFontSize' );
            obj.FontUnits  = get( 0, 'DefaultUIPanelFontUnits' );
            obj.FontWeight = get( 0, 'DefaultUIPanelFontWeight' );
            obj.ForegroundColor = get( 0, 'DefaultUIPanelForegroundColor' );
            obj.HighlightColor  = get( 0, 'DefaultUIPanelHighlightColor' );
            obj.ShadowColor     = get( 0, 'DefaultUIPanelShadowColor' );
        end % DecoratedPanel
        
        function set.FontAngle( obj, value )
            idx = find( strcmpi( value, obj.AllowedFontAngle ) ); %#ok<MCSUP>
            if isempty( idx )
                msg = sprintf( '%s ', obj.AllowedFontAngle{:} ); %#ok<MCSUP>
                error( 'UIExtras:Panel:BadFontAngle', 'FontAngle must be one of: %s', msg );
            else
                obj.FontAngle = obj.AllowedFontAngle{idx}; %#ok<MCSUP>
                eventData = struct( ...
                    'Property', 'FontAngle', ...
                    'Value', obj.FontAngle );
                obj.onPanelFontChanged( obj, eventData );
            end
        end % set.FontAngle
        
        function set.FontName( obj, value )
            idx = find( strcmpi( value, obj.AllowedFontName ) ); %#ok<MCSUP>
            if isempty( idx )
                error( 'UIExtras:Panel:BadFontName', 'FontName %s not found. Use "listfonts" to find available fonts', value );
            else
                obj.FontName = obj.AllowedFontName{idx}; %#ok<MCSUP>
                eventData = struct( ...
                    'Property', 'FontName', ...
                    'Value', obj.FontName );
                obj.onPanelFontChanged( obj, eventData );
            end
        end % set.FontName
        
        function set.FontSize( obj, value )
            obj.FontSize = value;
            eventData = struct( ...
                'Property', 'FontSize', ...
                'Value', value );
            obj.onPanelFontChanged( obj, eventData );
        end % set.FontSize
        
        function set.FontUnits( obj, value )
            idx = find( strcmpi( value, obj.AllowedFontUnits ) ); %#ok<MCSUP>
            if isempty( idx )
                msg = sprintf( '%s ', obj.AllowedFontUnits{:} ); %#ok<MCSUP>
                error( 'UIExtras:Panel:BadFontUnits', 'FontUnits must be one of: %s', msg );
            else
                obj.FontUnits = obj.AllowedFontUnits{idx}; %#ok<MCSUP>
                eventData = struct( ...
                    'Property', 'FontUnits', ...
                    'Value', obj.FontUnits );
                obj.onPanelFontChanged( obj, eventData );
            end
        end % set.FontUnits
        
        function set.FontWeight( obj, value )
            idx = find( strcmpi( value, obj.AllowedFontWeight ) ); %#ok<MCSUP>
            if isempty( idx )
                msg = sprintf( '%s ', obj.AllowedFontWeight{:} ); %#ok<MCSUP>
                error( 'UIExtras:Panel:BadFontWeight', 'FontWeight must be one of: %s', msg );
            else
                obj.FontWeight = obj.AllowedFontWeight{idx}; %#ok<MCSUP>
                eventData = struct( ...
                    'Property', 'FontWeight', ...
                    'Value', obj.FontWeight );
                obj.onPanelFontChanged( obj, eventData );
            end
        end % set.FontWeight
        
        function set.ForegroundColor( obj, value )
            obj.ForegroundColor = uiextras.interpretColor( value );
            eventData = struct( ...
                'Property', 'ForegroundColor', ...
                'Value', obj.ForegroundColor );
            obj.onPanelColorChanged( obj, eventData );
        end % set.ForegroundColor
        
        function set.HighlightColor( obj, value )
            obj.HighlightColor = uiextras.interpretColor( value );
            eventData = struct( ...
                'Property', 'HighlightColor', ...
                'Value', obj.HighlightColor );
            obj.onPanelColorChanged( obj, eventData );
        end % set.HighlightColor
        
        function set.ShadowColor( obj, value )
            obj.ShadowColor = uiextras.interpretColor( value );
            eventData = struct( ...
                'Property', 'ShadowColor', ...
                'Value', obj.ShadowColor );
            obj.onPanelColorChanged( obj, eventData );
        end % set.ShadowColor
        
    end % public methods
    
    %% Abstract methods
    methods ( Abstract = true, Access='protected' )
        onPanelColorChanged( obj, source, eventData );
        onPanelFontChanged( obj, source, eventData );
    end % Protected methods
end % classdef