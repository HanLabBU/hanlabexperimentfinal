classdef HButtonBox < uiextras.ButtonBox
    %HButtonBox  Arrange buttons horizontally in a single row
    %
    %   obj = uiextras.HButtonBox() is a type of HBox specialised for
    %   arranging a row of buttons, check-boxes or similar graphical
    %   elements. All buttons are given equal size and by default are
    %   centered in the drawing area. The justification can be changed as
    %   required.
    %
    %   obj = uiextras.HButtonBox(param,value,...) also sets one or more
    %   parameter values.
    %
    %   See the <a href="matlab:doc uiextras.HButtonBox">documentation</a> for more detail and the list of properties.
    %
    %   Examples:
    %   >> f = figure();
    %   >> b = uiextras.HButtonBox( 'Parent', f );
    %   >> uicontrol( 'Parent', b, 'String', 'One' );
    %   >> uicontrol( 'Parent', b, 'String', 'Two' );
    %   >> uicontrol( 'Parent', b, 'String', 'Three' );
    %   >> set( b, 'ButtonSize', [130 35], 'Spacing', 5 );
    %
    %   See also: uiextras.VButtonBox
    %             uiextras.HBox
    
    %  Copyright 2009 The MathWorks, Inc.
    %  $Revision: 199 $ $Date: 2010-06-18 15:55:16 +0100 (Fri, 18 Jun 2010) $
    
    %% Public methods
    methods
        
        function obj = HButtonBox( varargin )
            %HButtonBox: Create a new horizontal button box
            
            % Set properties
            if nargin > 0
                set( obj, varargin{:} );
            end
        end % constructor
    end % public methods
    
    %% Protected methods
    methods (Access='protected')
        function redraw( obj )
            % First we need to work out how much space is available - if
            % there's not enough for the desired size then the buttons may
            % have to shrink
            nC = numel( obj.Children );
            pos = ceil( getpixelposition( obj.UIContainer ) );
            availableWidth = pos(3) - 2*obj.Padding - (nC-1)*obj.Spacing;
            availableHeight = pos(4) - 2*obj.Padding;
            
            buttonWidth = min( obj.ButtonSize(1), availableWidth/nC );
            buttonHeight = min( obj.ButtonSize(2), availableHeight );
            
            % The positioning depends on the alignment
            switch upper( obj.VerticalAlignment )
                case 'TOP'
                    y0 = pos(4) - obj.Padding - buttonHeight;
                    
                case 'MIDDLE'
                    y0 = 1 + round( ( pos(4) - buttonHeight ) / 2 );
                    
                case 'BOTTOM'
                    y0 = 1 + obj.Padding;
                    
                otherwise
                    error( 'Should never get here' )
            end
            
            buttonsWidth = buttonWidth*nC + (nC-1)*obj.Spacing;
            switch upper( obj.HorizontalAlignment )
                case 'LEFT'
                    x0 = 1+ obj.Padding;
                    
                case 'CENTER'
                    x0 = 1 + round( (pos(3) - buttonsWidth ) / 2 );
                    
                case 'RIGHT'
                    x0 = pos(3) - obj.Padding - buttonsWidth;
                    
                otherwise
                    error( 'Should never get here' )
            end
            
            % OK, we now know the start coords, so position each child
            children = obj.Children;
            for ii=1:nC
                contentPos = [x0 + (ii-1)*(obj.Spacing+buttonWidth), y0, buttonWidth, buttonHeight];
                obj.repositionChild( children(ii), contentPos )
            end
            
        end % redraw
     
    end % Protected methods
end % classdef