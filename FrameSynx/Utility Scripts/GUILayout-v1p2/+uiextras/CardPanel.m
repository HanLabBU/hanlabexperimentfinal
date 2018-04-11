classdef CardPanel < uiextras.Container
    %CardPanel  Show one element (card) from a list
    %
    %   obj = uiextras.CardPanel() creates a new card panel which allows
    %   selection between the different child objects contained, making the
    %   selected child fill the space available and all other children
    %   invisible. This is commonly used for creating wizards or quick
    %   switching between different views of a single data-set.
    %
    %   obj = uiextras.CardPanel(param,value,...) also sets one or more
    %   property values.
    %
    %   See the <a href="matlab:doc uiextras.CardPanel">documentation</a> for more detail and the list of properties.
    %
    %   Examples:
    %   >> f = figure();
    %   >> p = uiextras.CardPanel( 'Parent', f, 'Padding', 5 );
    %   >> uicontrol( 'Style', 'frame', 'Parent', p, 'Background', 'r' );
    %   >> uicontrol( 'Style', 'frame', 'Parent', p, 'Background', 'b' );
    %   >> uicontrol( 'Style', 'frame', 'Parent', p, 'Background', 'g' );
    %   >> p.SelectedChild = 2;
    %
    %   See also: uiextras.Panel
    %             uiextras.BoxPanel
    %             uiextras.TabPanel
    
    %   Copyright 2005-2009 The MathWorks Ltd.
    %   $Revision: 199 $    $Date: 2010-06-18 15:55:16 +0100 (Fri, 18 Jun 2010) $
    
    
    %% Public properties
    properties
        Callback = []
        Padding = 0 % padding around contents (pixels)
    end % Public properties
    
    %% Calculated properties
    properties ( Dependent = true )
        SelectedChild   % Which child is visible [+ve integer or empty]
    end % Calculated properties
    
    %% Private properties
    properties ( SetAccess = 'private', GetAccess = 'private', Hidden = true )
        SelectedChild_ = [] % the index of the child that is currently being shown
    end % Private properties
    
    
    %% Public methods
    methods
        function obj = CardPanel(varargin)
            % First step is to create the parent class. We pass the
            % arguments (if any) just incase the parent needs setting
            obj = obj@uiextras.Container( varargin{:} );
                        
            % Parse any input arguments (but only if this is the leaf
            % class)
            if nargin>0 && isequal( class( obj ), 'uiextras.CardPanel' )
                set( obj, varargin{:} );
            end
            obj.redraw();
        end % CardPanel
        
    end % Public methods
    
    %% Data access methods
    methods

        function value = get.SelectedChild( obj )
            value = obj.SelectedChild_;
        end % get.SelectedChild
        
        function set.SelectedChild( obj, value )
            % Check
            if isempty( obj.Children )
                obj.SelectedChild_ = [];
            else
                if ~isscalar( value ) || (round( value ) ~= value) || value < 0
                    error( 'Layout:Panel:InvalidArgument', ...
                        'SelectedChild must be a positive integer' )
                elseif value > numel( obj.Children )
                    error( 'Layout:Panel:InvalidArgument', ...
                        'Tried to select child %d, but it doesn''t exist', value )
                end
                
                % Set
                obj.SelectedChild_ = value;
            end
            
            % Redraw
            obj.redraw();
        end % set.SelectedChild
        
        function set.Padding( obj, value )
            % Check input
            if ~isnumeric( value ) || ~isscalar( value ) || ...
                    ~isreal( value ) || isnan( value ) || ~isfinite( value ) || ...
                    value < 0 || rem( value, 1 ) ~= 0
                error( 'Layout:TabPanel:InvalidArgument', ...
                    'Property ''Padding'' must be a nonnegative integer.' )
            end
            % All OK, so set it and redraw using the new value
            obj.Padding = value;
            obj.redraw();
        end % set.Padding
                
    end % Data access methods
    
    %% Protected methods
    methods ( Access = protected )
        function redraw(obj)
            %REDRAW redraw the contents
            %
            % Fort a card layout the only thing we really need to do is
            % show one of the children filling the view
            pos = getpixelposition( obj.UIContainer );
            contentPos = [1 1 pos(3) pos(4)] + obj.Padding*[1 1 -2 -2];
            obj.showSelectedChild( contentPos );
        end % redraw
        
        function showSelectedChild( obj, contentPos )
            % Generic function for showing just one child
            
            page_offset = 2500; % The amount by which widgets are moved when making invisible
            C = obj.Children;
            nC = numel(C);
            if ~isempty( obj.SelectedChild )
                % Set all to be invisible except current page
                % We also have to move them offscreen to avoid problems with invisible
                % panels and things blocking out visible ones (an HG bug?)
                otherPages = 1:nC;
                otherPages( otherPages==obj.SelectedChild ) = [];
                for page=otherPages
                    oldunits = get( C(page), 'Units' );
                    set( C(page), 'Units', 'pixels' );
                    p = get(C(page), 'Position');
                    if p(1)<page_offset || p(2)<page_offset
                        newPosition = p + [page_offset page_offset 0 0];
                        obj.repositionChild( C(page), newPosition )
                    end
                    set( C(page), 'Units', oldunits );
                end
                
                % And put the selected one on view
                obj.repositionChild( C(obj.SelectedChild), contentPos );
            end
        end % showSelectedChild
        
        function onChildAdded( obj, source, eventData ) %#ok<INUSD>
            %onChildAdded: Callback that fires when a child is added to a container.
            % Select the new addition
            C = obj.Children;
            N = numel( C );
            obj.SelectedChild = N;
        end % onChildAdded
        
        function onChildRemoved( obj, source, eventData ) %#ok<INUSL>
            %onChildAdded: Callback that fires when a container child is destroyed or reparented.
            % If the missing child is the selected one, select something else
            if obj.SelectedChild >= eventData.ChildIndex
                % Changing the selection will force a redraw
                if isempty( obj.Children )
                    obj.SelectedChild = [];
                else
                    obj.SelectedChild = max( 1, obj.SelectedChild - 1 );
                end
            else
                % We don't need to change the selection, so explicitly
                % redraw
                obj.redraw();
            end
        end % onChildRemoved
        
    end % Protected methods
    
end % classdef
