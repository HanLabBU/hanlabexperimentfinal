classdef HBox < uiextras.Box
    %HBox  arrange elements in a single horizontal row
    %
    %   obj = uiextras.HBox() creates a new horizontal box layout with
    %   all parameters set to defaults. The output is a new layout object
    %   that can be used as the parent for other user-interface components.
    %
    %   obj = uiextras.HBox(param,value,...) also sets one or more
    %   parameter values.
    %
    %   See the <a href="matlab:doc uiextras.HBox">documentation</a> for more detail and the list of properties.
    %
    %   Examples:
    %   >> f = figure();
    %   >> b = uiextras.HBox( 'Parent', f );
    %   >> uicontrol( 'Parent', b, 'Background', 'r' )
    %   >> uicontrol( 'Parent', b, 'Background', 'b' )
    %   >> uicontrol( 'Parent', b, 'Background', 'g' )
    %   >> set( b, 'Sizes', [-1 100 -2], 'Spacing', 5 );
    %
    %   >> f = figure();
    %   >> b1 = uiextras.VBox( 'Parent', f );
    %   >> b2 = uiextras.HBox( 'Parent', b1, 'Padding', 5, 'Spacing', 5 );
    %   >> uicontrol( 'Style', 'frame', 'Parent', b1, 'Background', 'r' )
    %   >> uicontrol( 'Parent', b2, 'String', 'Button1' )
    %   >> uicontrol( 'Parent', b2, 'String', 'Button2' )
    %   >> set( b1, 'Sizes', [30 -1] );
    %
    %   See also: uiextras.VBox
    %             uiextras.HBoxFlex
    %             uiextras.Grid
    
    %  Copyright 2009 The MathWorks, Inc.
    %  $Revision: 199 $ $Date: 2010-06-18 15:55:16 +0100 (Fri, 18 Jun 2010) $
    
    %% Public methods
    methods
        
        function obj = HBox( varargin )
            %HBOX  Container with contents in a single horizontal row
            %
            %  O = HBOX creates a new HBOX.
            %
            %  O = HBOX(P1,V1,P2,V2,...) sets property P1 to value V1, etc.
            
            % Pass inputs to superclass
            obj@uiextras.Box( varargin{:} );
            
            % Set properties
            if nargin > 0
                set( obj, varargin{:} );
            end  
        end % constructor
        
    end % Public methods
    
    %% Protected methods
    methods( Access = 'protected' )
        
        function [widths,heights] = redraw( obj )
            %REDRAW  Redraw container contents.
            
            % Get container width and height
            totalPosition = ceil( getpixelposition( obj.UIContainer ) );
            totalWidth = totalPosition(3);
            totalHeight = totalPosition(4);
            
            % Get children
            children = obj.Children;
            nChildren = numel( children );
            
            % Get padding, spacing and sizes
            padding = obj.Padding;
            spacing = obj.Spacing;
            
            % Compute widths
            widths = obj.calculatePixelSizes( totalWidth );
            
            % Compute heights
            heights = repmat( totalHeight - padding * 2, size( children ) );
            heights = max( heights, 1 ); % minimum is 1 pixel
            
            % Compute and set new positions in pixels
            for ii = 1:nChildren
                child = children(ii);
                newPosition = [sum( widths(1:ii-1) ) + padding + spacing * (ii-1) + 1, ...
                    padding + 1, ...
                    widths(ii), ...
                    heights(ii)];
                obj.repositionChild( child, newPosition )
            end   
        end % redraw
        
    end % Protected methods
    
end % classdef