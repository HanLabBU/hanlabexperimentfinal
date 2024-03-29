classdef Container < hgsetget
    %Container  Container base class
    %
    %   c = uiextras.Container() creates a new container object.
    %
    %   See also: uiextras.Box
    
    %   Copyright 2009-2010 The MathWorks, Inc.
    %   $Revision: 200 $ $Date: 2010-06-18 16:58:42 +0100 (Fri, 18 Jun 2010) $
    
    %% Dependent properties
    properties( Dependent = true, Transient = true )
        BackgroundColor % background color [r g b]
        BeingDeleted    % is the object in the process of being deleted [on|off]
        Children        % list of the children of the layout [handle array]
        Enable          % allow interaction with the contents of this layout [on|off]
        Parent          % parent [handle]
        Position        % position [left bottom width height]
        Tag             % tag [string]
        Type            % the object type (class) [string]
        Units           % units [inches|centimeters|normalized|points|pixels|characters]
        Visible         % visible [on|off]
    end % Dependent properties
    
    %% Protected properties
    properties( SetAccess = 'protected', GetAccess = 'protected', Hidden = true, Transient = true )
        Listeners = cell( 0, 1 ) % listeners
    end % Private properties
    
    %% Read-only protected properties
    properties( SetAccess = 'private', GetAccess = 'protected', Hidden = true, Transient = true )
        UIContainer % associated uicontainer
    end % Read-only protected properties
    
    %% Private properties
    properties( SetAccess = 'private', GetAccess = 'private', Hidden = true, Transient = true )
        Children_ = zeros( 0, 1 ) % children
        ChildListeners = cell( 0, 2 ) % listeners
        Enable_ = 'on'
    end % Private properties
    
    %% Public methods
    methods
        
        function obj = Container( varargin )
            %Container  Container base class constructor
            
            % Find if parent has been supplied
            parent = uiextras.findArg( 'Parent', varargin{:} );
            
            % Create container
            args = {'Title', '', 'BorderType', 'none'};
            if isempty( parent )
                obj.UIContainer = uipanel( args{:} );
            else
                obj.UIContainer = uipanel( 'Parent', parent, args{:} );
            end
            
            % Tag it!
            set( obj.UIContainer, 'Tag', strrep( class( obj ), '.', ':' ) );
            
            
            % Create listeners to resizing of container
            containerObj = handle( obj.UIContainer );
            obj.Listeners{end+1,1} = handle.listener( containerObj, findprop( containerObj, 'PixelBounds' ), 'PropertyPostSet', @obj.onResized );
            
            % Create listeners to addition of container children
            obj.Listeners{end+1,1} = handle.listener( containerObj, 'ObjectChildAdded', @obj.onChildAddedEvent );
            
            % Watch out for the graphics being destroyed
            obj.Listeners{end+1,1} = handle.listener( containerObj, 'ObjectBeingDestroyed', @obj.onContainerBeingDestroyed );
            
            % Store Container in container
            setappdata( obj.UIContainer, 'Container', obj );
        end % constructor
        
        function set.Position( obj, value )
            set( obj.UIContainer, 'Position', value );
        end % set.Position
        
        function value = get.Position( obj )
            value = get( obj.UIContainer, 'Position' );
        end % get.Position
        
        function set.Children( obj, value )
            % Check
            oldChildren = obj.Children_;
            newChildren = value;
            [tf, loc] = ismember( oldChildren, newChildren );
            if ~isequal( size( oldChildren ), size( newChildren ) ) || any( ~tf )
                error( 'Layout:Container:InvalidArgument', ...
                    'Property ''Children'' may only be set to a permutation of itself.' )
            end
            
            % Set
            obj.Children_ = newChildren;
            
            % Reorder ChildListeners
            obj.ChildListeners(loc,:) = obj.ChildListeners;
            
            % Redraw
            obj.redraw();
        end % set.Children
        
        function value = get.Children( obj )
            value = obj.Children_;
        end % get.Children
        
        function set.Enable( obj, value )
            % Check
            if ~ischar( value ) || ~ismember( lower( value ), {'on','off'} )
                error( 'Layout:Container:InvalidArgument', ...
                    'Property ''Enable'' may only be set to ''on'' or ''off''.' )
            end
            % Apply
            obj.Enable_ = [upper(value(1)),lower(value(2:end))];
            
            % Apply to children
            ch = obj.Children_;
            activating = strcmpi( obj.Enable_, 'On' );
            for ii=1:numel( ch )
                if strcmpi( get( ch(ii), 'Type' ), 'uipanel' )
                    % Might be another layout
                    if isappdata( ch(ii), 'Container' )
                        chobj = getappdata( ch(ii), 'Container' );
                        set( chobj, 'Enable', obj.Enable_ );
                    end
                elseif isprop( ch(ii), 'Enable' )
                    % It supports enabling. We will use a piece of app data
                    % to track the original state to ensure we don't
                    % re-enable something that shouldn't be.
                    if activating
                        if isappdata( ch(ii), 'OldEnableState' )
                            set( ch(ii), 'Enable', getappdata( ch(ii), 'OldEnableState' ) );
                            rmappdata( ch(ii), 'OldEnableState' );
                        else
                            set( ch(ii), 'Enable', 'on' );
                        end
                    else
                        if ~isappdata( ch(ii), 'OldEnableState' )
                            setappdata( ch(ii), 'OldEnableState', get( ch(ii), 'Enable' ) );
                        end
                        set( ch(ii), 'Enable', 'off' );
                        
                    end
                end
            end
            
            % Do the work
            obj.onEnable( obj, value );
        end % set.Enable
        
        function value = get.Enable( obj )
            value = obj.Enable_;
        end % get.Enable
        
        function set.Units( obj, value )
            set( obj.UIContainer, 'Units', value );
        end % set.Units
        
        function value = get.Units( obj )
            value = get( obj.UIContainer, 'Units' );
        end % get.Units
        
        function set.Parent( obj, value )
            set( obj.UIContainer, 'Parent', double( value ) );
        end % set.Parent
        
        function value = get.Parent( obj )
            value = get( obj.UIContainer, 'Parent' );
        end % get.Parent
        
        function set.Tag( obj, value )
            set( obj.UIContainer, 'Tag', value );
        end % set.Tag
        
        function value = get.Tag( obj )
            value = get( obj.UIContainer, 'Tag' );
        end % get.Tag
        
        function value = get.Type( obj )
            value = class( obj );
        end % get.Type
        
        function value = get.BeingDeleted( obj )
            value = get( obj.UIContainer, 'BeingDeleted' );
        end % get.BeingDeleted
        
        function set.Visible( obj, value )
            set( obj.UIContainer, 'Visible', value );
        end % set.Visible
        
        function value = get.Visible( obj )
            value = get( obj.UIContainer, 'Visible' );
        end % get.Visible
        
        function set.BackgroundColor( obj, value )
            set( obj.UIContainer, 'BackgroundColor', value );
            obj.onBackgroundColorChanged( obj, value );
        end % set.BackgroundColor
        
        function value = get.BackgroundColor( obj )
            value = get( obj.UIContainer, 'BackgroundColor' );
        end % get.BackgroundColor
        
        function container = double( obj )
            %double  Convert a container to an HG double handle.
            %
            %  D = double(C) converts a container C to an HG handle D.
            container = obj.UIContainer;
        end % double
        
        function pos = getpixelposition( obj )
            %getpixelposition  get the absolute pixel position
            %
            %   POS = GETPIXELPOSITION(C) gets the absolute position of the container C
            %   within its parent window. The returned position is in pixels.
            pos = getpixelposition( obj.UIContainer );
        end % getpixelposition
        
        function tf = isprop( obj, name )
            %isprop  does this object have the specified property
            %
            %   TF = ISPROP(C,NAME) checks whether the object C has a
            %   property named NAME. The result, TF, is true if the
            %   property exists, false otherwise.
            tf = ismember( name, properties( obj ) );
            
        end % isprop
        
        function p = ancestor(obj,varargin)
            %ancestor  Get object ancestor
            %
            %   P = ancestor(H,TYPE) returns the handle of the closest ancestor of h
            %   that matches one of the types in TYPE, or empty if there is no matching
            %   ancestor.  TYPE may be a single string (single type) or cell array of
            %   strings (types). If H is a vector of handles then P is a cell array the
            %   same length as H and P{n} is the ancestor of H(n). If H is one of the
            %   specified types then ancestor returns H.
            %
            %   P = ANCESTOR(H,TYPE,'TOPLEVEL') finds the highest level ancestor of one
            %   of the types in TYPE
            %
            %   If H is not an Handle Graphics object, ANCESTOR returns empty.
            p = ancestor( obj.UIContainer, varargin{:} );
        end %ancestor

        function delete( obj )
            %delete  destroy this layout
            %
            % If the user destroys the object, we *must* also remove any
            % graphics
            if ishandle( obj.UIContainer ) ...
                    && ~strcmpi( get( obj.UIContainer, 'BeingDeleted' ), 'on' )
                delete( obj.UIContainer );
            end
        end % delete
        
        
    end % public methods
    
    %% Protected methods
    methods( Access = 'protected' )
        
        function onResized( obj, source, eventData ) %#ok<INUSD>
            %onResized  Callback that fires when a container is resized.
            obj.redraw();
        end % onResized
        
        function onContainerBeingDestroyed( obj, source, eventData ) %#ok<INUSD>
            %onContainerBeingDestroyed  Callback that fires when the container dies
            delete( obj );
        end % onContainerBeingDestroyed
        
        function onChildAdded( obj, source, eventData ) %#ok<INUSD>
            %onChildAdded  Callback that fires when a child is added to a container.
            obj.redraw();
        end % onChildAdded
        
        function onChildRemoved( obj, source, eventData ) %#ok<INUSD>
            %onChildRemoved  Callback that fires when a container child is destroyed or reparented.
            obj.redraw();
        end % onChildRemoved
        
        function onBackgroundColorChanged( obj, source, eventData ) %#ok<INUSD,MANU>
            %onBackgroundColorChanged  Callback that fires when the container background color is changed
        end % onChildRemoved
        
        function onEnable( obj, source, eventData ) %#ok<INUSD,MANU>
            %onEnable  Callback that fires when the enable state is changed
        end % onChildRemoved
        
        function repositionChild( obj, child, position )
            %repositionChild  adjust the position and visibility of a child
            if position(3)<=0 || position(4)<=0
                % Not enough space, so move offscreen instead
                set( child, 'Position', [-100 -100 10 10] );
            else
                % There's space, so make sure visibility is on
                % First determine whether to use "Position" or "OuterPosition"
                if isprop( child, 'ActivePositionProperty' )
                    propname = get( child, 'ActivePositionProperty' );
                else
                    propname = 'Position';
                end
                
                % Now set the position in pixels, changing the units first if
                % necessary
                oldunits = get( child, 'Units' );
                if strcmpi( oldunits, 'Pixels' )
                    set( child, propname, position );
                elseif strcmpi( oldunits, 'Normalized' )
                    % Convert pixels to normalized before setting
                    myPos = getpixelposition( obj );
                    w = myPos(3);
                    h = myPos(4);
                    set( child, propname, position./[w h w h] );
                else
                    % Other units, so switch to pixels before setting
                    set( child, 'Units', 'pixels' );
                    set( child, propname, position );
                    set( child, 'Units', oldunits );
                end
            end
        end % repositionChild
        
    end % protected methods
    
    %% Abstract methods
    methods( Abstract = true, Access = 'protected' )
        
        redraw( obj )
        
    end % abstract methods
    
    %% Private methods
    methods( Access = 'private', Sealed = true )
        
        function onChildAddedEvent( obj, source, eventData ) %#ok<INUSL>
            %onChildAddedEvent  Callback that fires when a child is added to a container.
            
            % Find child in Children
            child = eventData.Child;
            tf = ismember( child, obj.Children_ );
            
            if tf
                return % not *really* being added
            end
            
            % Only hook up internally if not a "hidden" child
            if isprop( child, 'HandleVisibility' ) ...
                    && strcmpi( get( child, 'HandleVisibility' ), 'on' )
                
                % Add element to Children
                obj.Children_(end+1,:) = child;
                
                % Add elements to ChildListeners. A bug in R2009b and
                % earlier means we have to be careful about this
                v = ver( 'MATLAB' );
                if datenum( v.Date ) <= datenum( '15-Jan-2009' )
                    obj.ChildListeners(end+1,:) = ...
                        {handle.listener( child, 'ObjectBeingDestroyed', {@helpDeleteChild,obj} ), ...
                        handle.listener( child, 'ObjectParentChanged', {@helpReparentChild,obj} )};
                else
                    obj.ChildListeners(end+1,:) = ...
                        {handle.listener( child, 'ObjectBeingDestroyed', @obj.onChildBeingDestroyedEvent ), ...
                        handle.listener( child, 'ObjectParentChanged', @obj.onChildParentChangedEvent )};
                end
                
                % We are taking over management of position and will do it
                % in pixel units
                set( child, 'Units', 'Pixels' );
                
                % Call onChildAdded
                eventData = uiextras.ChildEvent( child, numel( obj.Children_ ) );
                
                obj.onChildAdded( obj, eventData );
            end
        end % onChildAddedEvent
        
        function onChildBeingDestroyedEvent( obj, source, eventData ) %#ok<INUSD>
            %onChildBeingDestroyedEvent  Callback that fires when a container child is destroyed.
            
            % Find child in Children
            [dummy, loc] = ismember( source, obj.Children_ ); %#ok<ASGLU>
            
            % Remove element from Children
            obj.Children_(loc,:) = [];
            
            % Remove elements from ChildListeners
            obj.ChildListeners(loc,:) = [];
            
            % If we are in our death throes, don't start calling callbacks
            if ishandle( obj.UIContainer ) && ~strcmpi( get( obj.UIContainer, 'BeingDeleted' ), 'ON' )
                % Call onChildRemoved
                eventData = uiextras.ChildEvent( source, loc );
                obj.onChildRemoved( obj, eventData );
            end
            
        end % onChildBeingDestroyedEvent
        
        function onChildParentChangedEvent( obj, source, eventData )
            %onChildParentChangedEvent  Callback that fires when a container child is reparented.
            
            if eventData.NewParent == obj.UIContainer
                return % not being reparented *away*
            end
            
            % Find child in Children
            [dummy, loc] = ismember( source, obj.Children_ ); %#ok<ASGLU>
            
            % Remove element from Children
            obj.Children_(loc,:) = [];
            
            % Remove elements from ChildListeners
            obj.ChildListeners(loc,:) = [];
            
            % Call onChildRemoved
            eventData = uiextras.ChildEvent( source, loc );
            obj.onChildRemoved( obj, eventData );
            
        end % onChildParentChangedEvent
        
    end % private sealed methods
    
end % classdef


% Helper functions to work around a bug in R2009a and earlier
function helpDeleteChild( src, evt, obj )
obj.onChildBeingDestroyedEvent( src, evt );
end
function helpReparentChild( src, evt, obj )
obj.onChildParentChangedEvent( src, evt );
end