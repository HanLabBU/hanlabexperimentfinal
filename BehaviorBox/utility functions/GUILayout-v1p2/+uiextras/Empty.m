classdef Empty < hgsetget
    %Empty  create an empty space
    %
    %   obj = uiextras.Empty() creates an empty space object that can be
    %   used in layouts to add gaps between other elements.
    %
    %   obj = uiextras.Empty(param,value,...) also sets one or more
    %   property values.
    %
    %   See the <a href="matlab:doc uiextras.Empty">documentation</a> for more detail and the list of properties.
    %
    %   Examples:
    %   >> f = figure();
    %   >> box = uiextras.HBox( 'Parent', f );
    %   >> uicontrol( 'Parent', box, 'Background', 'r' )
    %   >> uiextras.Empty( 'Parent', box )
    %   >> uicontrol( 'Parent', box, 'Background', 'b' )
    %
    %   See also: uiextras.HBox
    
    %   Copyright 2009-2010 The MathWorks, Inc.
    %   $Revision: 199 $ 
    %   $Date: 2010-06-18 15:55:16 +0100 (Fri, 18 Jun 2010) $
    
    
    
    %% Private properties
    properties (SetAccess='private',GetAccess='private')
        UIControl = -1
    end % Private properties
    
    %% Dependent properties
    properties( Dependent = true, Transient = true )
        Children % list of the children of the layout [handle array]
        Parent   % parent [handle]
        Position % position [left bottom width height]
        Tag      % tag [string]
        Type     % type [string]
        Units    % units [inches|centimeters|normalized|points|pixels|characters]
        Visible  % visible [on|off]
    end % Dependent properties
    
    
    %% Public methods
    methods
        
        function obj = Empty( varargin )
            color = get(0,'DefaultUIControlBackgroundColor');
            obj.UIControl = uicontrol( ...
                'Style', 'frame', ...
                'ForegroundColor', color, ...
                'BackgroundColor', color, ...
                'Tag', class( obj ), ...
                'HitTest', 'off' );
            
            if nargin
                set( obj, varargin{:} );
            end
        end % constructor
        
        function set.Position( obj, value )
            set( obj.UIControl, 'Position', value );          
        end % set.Position
        
        function value = get.Position( obj )
            value = get( obj.UIControl, 'Position' );       
        end % get.Position
        
        function set.Children( obj, value )
            set( obj.UIControl, 'Children', value );
            obj.redraw();
        end % set.Children
        
        function value = get.Children( obj )
            value = get( obj.UIControl, 'Children' );
        end % get.Children
        
        function set.Units( obj, value )
            set( obj.UIControl, 'Units', value );
        end % set.Units
        
        function value = get.Units( obj )
            value = get( obj.UIControl, 'Units' );
        end % get.Units
        
        function set.Parent( obj, value )
            set( obj.UIControl, 'Parent', double( value ) );
        end % set.Parent
        
        function value = get.Parent( obj )
            value = get( obj.UIControl, 'Parent' );
        end % get.Parent
        
        function set.Visible( obj, value )
            set( obj.UIControl, 'Visible', value );
        end % set.Visible
        
        function value = get.Visible( obj )
            value = get( obj.UIControl, 'Visible' );
        end % get.Visible
        
        function set.Tag( obj, value )
            set( obj.UIControl, 'Tag', value );
        end % set.Tag
        
        function value = get.Tag( obj )
            value = get( obj.UIControl, 'Tag' );
        end % get.Tag
        
        function value = get.Type( obj )
            value = class( obj );
        end % get.Type
        
        function control = double( obj )
            %DOUBLE: Convert to an HG double handle.
            %
            %  D = DOUBLE(E) converts empty widget E to an HG handle D.
            control = obj.UIControl;
        end % double
        
        function delete( obj )
            %DELETE: Destroy this object (and associated graphics)
            if ishandle( obj.UIControl )
                delete( obj.UIControl );
            end
        end % double

    end % Public methods
    
end % classdef