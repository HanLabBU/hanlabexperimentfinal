classdef TabPanel < uiextras.CardPanel & uiextras.DecoratedPanel
    %TabPanel  Show one element inside a tabbed panel
    %
    %   obj = uiextras.TabPanel() creates a panel with tabs along one edge
    %   to allow selection between the different child objects contained.
    %
    %   obj = uiextras.TabPanel(param,value,...) also sets one or more
    %   property values.
    %
    %   See the <a href="matlab:doc uiextras.TabPanel">documentation</a> for more detail and the list of properties.
    %
    %   Examples:
    %   >> f = figure();
    %   >> p = uiextras.TabPanel( 'Parent', f, 'Padding', 5 );
    %   >> uicontrol( 'Style', 'frame', 'Parent', p, 'Background', 'r' );
    %   >> uicontrol( 'Style', 'frame', 'Parent', p, 'Background', 'b' );
    %   >> uicontrol( 'Style', 'frame', 'Parent', p, 'Background', 'g' );
    %   >> p.TabNames = {'Red', 'Blue', 'Green'};
    %   >> p.SelectedChild = 2;
    %
    %   See also: uiextras.Panel
    %             uiextras.BoxPanel
    
    %   Copyright 2005-2009 The MathWorks Ltd.
    %   $Revision: 199 $    $Date: 2010-06-18 15:55:16 +0100 (Fri, 18 Jun 2010) $
    
    
    %% Public properties
    properties
        TabSize = 50
        TabPosition = 'Top' % Which side of the contents to put the tabs [ top | bottom ]
    end % Public properties
    
    %% Calculated properties
    properties ( Dependent = true )
        TabNames          % The title string for each tab
    end % Calculated properties
    
    %% Private properties
    properties ( SetAccess = 'private', GetAccess = 'private', Hidden = true )
        Images_ = struct()
        TabImage_ = []
        PageLabels = []
    end % Private properties
    
    
    %% Public methods
    methods
        function obj = TabPanel(varargin)
            % First step is to extract the parent (if any) to pass to the
            % superclass
            parent = uiextras.findArg( 'Parent', varargin{:} );
            obj = obj@uiextras.CardPanel( 'Parent', parent );
            
            % Load all of the necessary tab images (changing the colours
            % causes a reload)
            bgcol = obj.BackgroundColor;
            obj.HighlightColor  = ( 2*[1 1 1] + bgcol )/3;
            obj.ShadowColor  = 0.5*bgcol;
            
            % Add a UIControl for drawing the tabs
            obj.TabImage_ = uicontrol( ...
                'Visible', 'on', ...
                'units', 'pixels', ...
                'Parent', obj.UIContainer, ...
                'HandleVisibility', 'off', ...
                'Position', [1 1 1 1], ...
                'style', 'checkbox', ...
                'Tag', 'uiextras.TabPanel:TabImage');
            
            % Make sure the images are loaded
            obj.reloadImages();
            
            % Parse any input arguments
            if nargin>0
                set( obj, varargin{:} );
            end
            obj.redraw();
        end % TabPanel
        
    end % Public methods
    
    %% Data access methods
    methods
        
        function set.TabSize(obj,value)
            obj.TabSize = value;
            obj.redraw();
        end % set.TabSize
        
        function set.TabPosition(obj,value)
            if ~ischar( value ) || ~ismember( lower( value ), {'top','bottom'} )
                error( 'UIExtras:TabPanel:BadValue', 'Property ''TabPosition'' must be ''Top'' or ''Bottom''' );
            end
            obj.TabPosition = [upper( value(1) ),lower( value(2:end) )];
            obj.redraw();
        end % set.TabPosition
        
        function value = get.TabNames( obj )
            if isempty( obj.PageLabels )
                value = {};
            elseif numel( obj.PageLabels ) == 1
                value = {get( obj.PageLabels, 'String' )};
            else
                value = get( obj.PageLabels, 'String' )';
            end
        end % get.Titles
        
        function set.TabNames(obj,value)
            if ~iscell( value ) || numel( value )~=numel( obj.Children )
                error( 'Layout:TabPanel:InvalidArgument', ...
                    'TabNames must be a cell array of strings the same length as the number of children' )
            end
            for ii=1:numel( obj.Children )
                set( obj.PageLabels(ii), 'String', value{ii} );
            end
        end % set.Titles
        
    end % Data access methods
    
    %% Protected methods
    methods ( Access = protected )
        function redraw(obj)
            %REDRAW redraw the tabs and contents
            
            % Check the object exists (may be being deleted!)
            if isempty(obj.TabImage_) || ~ishandle(obj.TabImage_)
                return;
            end
            
            C = obj.Children;
            T = obj.TabNames;
            
            % Make sure label array is right size
            nC = numel(C);
            nT = numel(T);
            
            if nC==0 || nT~=nC
                return
            end
            pos = getpixelposition( obj.UIContainer );
            
            pad = obj.Padding;
            
            % Calculate the required height from the font size
            oldFontUnits = get( obj.PageLabels(1), 'FontUnits' );
            set( obj.PageLabels(1), 'FontUnits', 'Pixels' );
            fontHeightPix = get( obj.PageLabels(1), 'FontSize' );
            set( obj.PageLabels(1), 'FontUnits', oldFontUnits );
            tabHeight = ceil( 1.5*fontHeightPix + 4 );
            
            % Work out where the tabs labels and contents go
            if strcmpi( obj.TabPosition, 'Top' )
                tabPos = [1 1+pos(4)-tabHeight, pos(3), tabHeight+2];
                contentPos = [pad+1 pad+1 pos(3)-2*pad pos(4)-2*pad-tabHeight];
            else
                tabPos = [1 1, pos(3), tabHeight+2];
                contentPos = [pad+1 tabHeight+pad+1 pos(3)-2*pad pos(4)-2*pad-tabHeight];
            end
            
            % Shorthand for colouring things in
            fgCol = obj.BackgroundColor;
            bgCol = obj.BackgroundColor;
            shCol = 0.9*obj.BackgroundColor;
            
            totalWidth = round( tabPos(3)-1 );
            divWidth = 8;
            textWidth = obj.TabSize;
            if textWidth<0
                % This means we should fill the space
                textWidth = floor( (totalWidth - (nC+1)*divWidth) / nC );
            end
            textPos = [tabPos(1:2), textWidth, tabHeight - 4];
            
            if ~isempty( obj.SelectedChild )
                % The tabs are drawn as a single image
                tabCData(:,:,1) = bgCol(1)*ones(20,totalWidth);
                tabCData(:,:,2) = bgCol(2)*ones(20,totalWidth);
                tabCData(:,:,3) = bgCol(3)*ones(20,totalWidth);
                set( obj.TabImage_, 'Position', [tabPos(1:2),totalWidth,tabHeight] );
                
                % Use the CardLayout function to put the right child onscreen
                obj.showSelectedChild( contentPos )
                
                % Now update the tab image
                tabCData(:,1:divWidth,:) = obj.Images_.NonNot;
                for i=1:nC
                    x = divWidth+(divWidth+textWidth)*(i-1)+1;
                    set( obj.PageLabels(i), ...
                        'Position', textPos+[x,0,0,0] );
                    
                    if i==obj.SelectedChild,
                        set( obj.PageLabels(i), ...
                            'ForegroundColor', obj.ForegroundColor, ...
                            'BackgroundColor', fgCol);
                        % Set the dividers to show the right image
                        tabCData(:,x:x+textWidth-1,:) = repmat(obj.Images_.SelBack,1,textWidth);
                        if i==1
                            tabCData(:,x-divWidth:x-1,:) = obj.Images_.NonSel;
                        else
                            tabCData(:,x-divWidth:x-1,:) = obj.Images_.NotSel;
                        end
                        if i==nC
                            tabCData(:,x+textWidth:x+textWidth+divWidth-1,:) = obj.Images_.SelNon;
                        else
                            tabCData(:,x+textWidth:x+textWidth+divWidth-1,:) = obj.Images_.SelNot;
                        end
                    else
                        set( obj.PageLabels(i), ...
                            'ForegroundColor', 0.6*obj.ForegroundColor + 0.4*shCol, ...
                            'BackgroundColor', shCol );
                        tabCData(:,x:x+textWidth-1,:) = repmat(obj.Images_.NotBack,1,textWidth);
                        if i==nC
                            tabCData(:,x+textWidth:x+textWidth+divWidth-1,:) = obj.Images_.NotNon;
                        else
                            tabCData(:,x+textWidth:x+textWidth+divWidth-1,:) = obj.Images_.NotNot;
                        end
                    end
                end % For
                
                % Stretch the CData to match the fontsize
                if tabHeight ~= 20
                    topbot = min( round( tabHeight/2 ), 5 );
                    midsz = tabHeight - 2*topbot;
                    topData = tabCData(1:topbot,:,:);
                    bottomData = tabCData(end-topbot+1:end,:,:);
                    midData = repmat( tabCData(10,:,:), [midsz,1,1] );
                    tabCData = [ topData ; midData ; bottomData ];
                end
                
                if strcmpi( obj.TabPosition, 'Top' )
                    set( obj.TabImage_, 'CData', tabCData );
                else
                    set( obj.TabImage_, 'CData', flipdim( tabCData, 1 ) );
                end
            end
            
            
            % Make sure the text labels are top of the stack
            %             ch = get( obj.TabContainer_, 'Children' );
            %             if numel( ch ) > 1
            %                 labs = ismember( get(ch,'Style'), 'text' );
            %             else
            %                 labs = strcmpi( get(ch,'Style'), 'text' );
            %             end
            %             set( obj.TabContainer_, 'Children', [flipud(ch(labs));ch(~labs)] ); % Note the flip is needed so that the text always redraws
        end % redraw
        
        function onChildAdded( obj, source, eventData ) %#ok<INUSD>
            %onChildAdded: Callback that fires when a child is added to a container.
            % Select the new addition
            C = obj.Children;
            N = numel( C );
            visible = obj.Visible;
            title = sprintf( 'Page %d', N );
            
            obj.PageLabels(end+1,1) = uicontrol( ...
                'Visible', visible, ...
                'style', 'text', ...
                'enable', 'inactive', ...
                'string', title, ...
                'FontName', obj.FontName, ...
                'FontUnits', obj.FontUnits, ...
                'FontSize', obj.FontSize, ...
                'FontAngle', obj.FontAngle, ...
                'FontWeight', obj.FontWeight, ...
                'ForegroundColor', obj.ForegroundColor, ...
                'parent', obj.UIContainer, ...
                'HandleVisibility', 'off', ...
                'ButtonDownFcn', {@iTabClicked, obj, N});
            if strcmpi( obj.Enable, 'off' )
                set( obj.PageLabels(end), 'Enable', 'off' );
            end
            obj.SelectedChild = N;
        end % onChildAdded
        
        function onChildRemoved( obj, source, eventData ) %#ok<INUSL>
            %onChildAdded: Callback that fires when a container child is destroyed or reparented.
            % If the missing child is the selected one, select something else
            obj.Titles( eventData.ChildIndex ) = [];
            delete( obj.PageLabels(end) );
            obj.PageLabels(end) = [];
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
        
        function onBackgroundColorChanged( obj, source, eventData ) %#ok<INUSD>
            %onBackgroundColorChanged  Callback that fires when the container background color is changed
            %
            % We need to make the panel match the container background
            obj.reloadImages();
            obj.redraw();
        end % onChildRemoved
        
        function onPanelColorChanged( obj, source, eventData ) %#ok<INUSD>
            % Colors have changed. This requires the images to be reset and
            % redrawn.
            obj.reloadImages();
            obj.redraw();
        end % onPanelColorChanged
        
        function onPanelFontChanged( obj, source, eventData ) %#ok<INUSL>
            % Font has changed. Since the font size and shape affects the
            % space available for the contents, we need to redraw.
            for ii=1:numel( obj.PageLabels )
                set( obj.PageLabels(ii), eventData.Property, eventData.Value );
            end
            obj.redraw();
        end % onPanelFontChanged
        
        function onEnable( obj, source, eventData ) %#ok<INUSD>
            % We use "inactive" to be the "on" state
            if strcmpi( obj.Enable, 'on' )
                enable = 'inactive';
            else
                enable = 'off';
            end
            
            for jj=1:numel( obj.PageLabels )
                set( obj.PageLabels(jj), 'Enable', enable, 'HitTest', obj.Enable );
            end
        end % onEnable
        
        function reloadImages( obj )
            % Reload tab images
            
            % If any of the colours are not yet constructed, stop now
            if isempty( obj.TabImage_ ) ...
                    || isempty( obj.HighlightColor ) ...
                    || isempty( obj.ShadowColor )
                return;
            end
            
            % First part of the name says which type of right-hand edge is needed
            % (non = no edge, not = not selected, sel = selected), second gives
            % left-hand
            obj.Images_.NonSel = iLoadIcon( 'tab_NoEdge_Selected.png', ...
                obj.BackgroundColor, obj.HighlightColor, obj.ShadowColor );
            obj.Images_.SelNon = iLoadIcon( 'tab_Selected_NoEdge.png', ...
                obj.BackgroundColor, obj.HighlightColor, obj.ShadowColor );
            obj.Images_.NonNot = iLoadIcon( 'tab_NoEdge_NotSelected.png', ...
                obj.BackgroundColor, obj.HighlightColor, obj.ShadowColor );
            obj.Images_.NotNon = iLoadIcon( 'tab_NotSelected_NoEdge.png', ...
                obj.BackgroundColor, obj.HighlightColor, obj.ShadowColor );
            obj.Images_.NotSel = iLoadIcon( 'tab_NotSelected_Selected.png', ...
                obj.BackgroundColor, obj.HighlightColor, obj.ShadowColor );
            obj.Images_.SelNot = iLoadIcon( 'tab_Selected_NotSelected.png', ...
                obj.BackgroundColor, obj.HighlightColor, obj.ShadowColor );
            obj.Images_.NotNot = iLoadIcon( 'tab_NotSelected_NotSelected.png', ...
                obj.BackgroundColor, obj.HighlightColor, obj.ShadowColor );
            obj.Images_.SelBack = iLoadIcon( 'tab_Background_Selected.png', ...
                obj.BackgroundColor, obj.HighlightColor, obj.ShadowColor );
            obj.Images_.NotBack = iLoadIcon( 'tab_Background_NotSelected.png', ...
                obj.BackgroundColor, obj.HighlightColor, obj.ShadowColor );
            
        end % reloadImages
        
    end % Protected methods
    
end % classdef





%-------------------------------------------------------------------------%
function im = iLoadIcon(imagefilename, backgroundcolor, highlightcolor, shadowcolor )
% Special image loader that turns various primary colours into background
% colours.

error( nargchk( 4, 4, nargin ) );

% Load an icon and set the transparent color
this_dir = fileparts( mfilename( 'fullpath' ) );
icon_dir = fullfile( this_dir, 'Resources' );
im8 = imread( fullfile( icon_dir, imagefilename ) );
im = double(im8)/255;
rows = size(im,1);
cols = size(im,2);

% Anything that's pure green goes to transparent
f=find((im8(:,:,1)==0) & (im8(:,:,2)==255) & (im8(:,:,3)==0));
im(f) = nan;
im(f + rows*cols) = nan;
im(f + 2*rows*cols) = nan;

% Anything pure red goes to selected background
f=find((im8(:,:,1)==255) & (im8(:,:,2)==0) & (im8(:,:,3)==0));
im(f) = backgroundcolor(1);
im(f + rows*cols) = backgroundcolor(2);
im(f + 2*rows*cols) = backgroundcolor(3);

% Anything pure blue goes to background background
f=find((im8(:,:,1)==0) & (im8(:,:,2)==0) & (im8(:,:,3)==255));
im(f) = backgroundcolor(1);
im(f + rows*cols) = backgroundcolor(2);
im(f + 2*rows*cols) = backgroundcolor(3);

% Anything pure yellow goes to deselected background
f=find((im8(:,:,1)==255) & (im8(:,:,2)==255) & (im8(:,:,3)==0));
im(f) = 0.9*backgroundcolor(1);
im(f + rows*cols) = 0.9*backgroundcolor(2);
im(f + 2*rows*cols) = 0.9*backgroundcolor(3);

% Anything pure white goes to highlight
f=find((im8(:,:,1)==255) & (im8(:,:,2)==255) & (im8(:,:,3)==255));
im(f) = highlightcolor(1);
im(f + rows*cols) = highlightcolor(2);
im(f + 2*rows*cols) = highlightcolor(3);

% Anything pure black goes to shadow
f=find((im8(:,:,1)==0) & (im8(:,:,2)==0) & (im8(:,:,3)==0));
im(f) = shadowcolor(1);
im(f + rows*cols) = shadowcolor(2);
im(f + 2*rows*cols) = shadowcolor(3);

end % iLoadIcon


%-------------------------------------------------------------------------%
function iTabClicked( src, evt, obj, idx ) %#ok<INUSL>

% Call the user callback before selecting the tab
evt = struct( ...
    'Source', obj, ...
    'SelectedChild', idx );
uiextras.callCallback( obj.Callback, obj, evt );
obj.SelectedChild = idx;

end % iTabClicked