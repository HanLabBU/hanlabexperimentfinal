classdef ButtonBox < uiextras.Container
    %ButtonBox  Abstract parent for button box classes
    
    %  Copyright 2009 The MathWorks, Inc.
    %  $Revision: 199 $ $Date: 2010-06-18 15:55:16 +0100 (Fri, 18 Jun 2010) $
    
    %% Public properties
    properties( SetObservable = true )
        ButtonSize = [100 25]          % Desired size for all buttons [width height]
        HorizontalAlignment = 'Center' % Horizonral alignment of buttons [left|center|right]
        VerticalAlignment = 'Middle'   % Vertical alignment of buttons [top|middle|bottom]
        Spacing = 5                    % spacing between contents (pixels)
        Padding = 0                    % spacing around all contents
    end % Public properties
    
    %% Public methods
    methods
        
        function obj = ButtonBox( varargin )
            %ButtonBox  Container with contents in a single row or column
            
            % Pass inputs to superclass
            obj@uiextras.Container( varargin{:} );
        end % constructor
        
        function set.ButtonSize( obj, value )
            % Check
            if ~isnumeric( value ) || numel( value )~= 2 ...
                    || any( ~isreal( value ) ) || any( isnan( value ) ) ...
                    || any( ~isfinite( value ) ) || any( value <= 0 )
                error( 'Layout:ButtonBox:InvalidArgument', ...
                    'Property ''ButtonSize'' must consist of two positive integers.' )
            end
            
            % Set & redraw
            obj.ButtonSize = value;
            obj.redraw();
        end % set.Sizes
        
        function set.Padding( obj, value )
            % Check
            if ~isnumeric( value ) || ~isscalar( value ) || ...
                    ~isreal( value ) || isnan( value ) || ~isfinite( value ) || ...
                    value < 0 || rem( value, 1 ) ~= 0
                error( 'Layout:ButtonBox:InvalidArgument', ...
                    'Property ''Padding'' must be a nonnegative integer.' )
            end
            
            % Set and redraw
            obj.Padding = value;
            obj.redraw();
        end % set.Padding
        
        function set.Spacing( obj, value )
            % Check
            if ~isnumeric( value ) || ~isscalar( value ) || ...
                    ~isreal( value ) || isnan( value ) || ~isfinite( value ) || ...
                    value < 0 || rem( value, 1 ) ~= 0
                error( 'Layout:ButtonBox:InvalidArgument', ...
                    'Property ''Spacing'' must be a nonnegative integer.' )
            end
            
            % Set and redraw
            obj.Spacing = value;
            obj.redraw();
        end % set.Spacing
        
        function set.HorizontalAlignment( obj, value )
            obj.HorizontalAlignment = value;
            obj.redraw();
        end % set.HorizontalAlignment
        
        function set.VerticalAlignment( obj, value )
            obj.VerticalAlignment = value;
            obj.redraw();
        end % set.VerticalAlignment
        
    end % public methods
    
end % classdef