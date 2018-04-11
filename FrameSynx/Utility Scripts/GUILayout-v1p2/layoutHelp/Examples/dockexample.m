function dockexample()
%DOCKEXAMPLE: An example of using the panelbox dock/undock functionality

%   Copyright 2009 The MathWorks Ltd.
%   $Revision: 113 $    $Date: 2010-01-05 17:48:39 +0000 (Tue, 05 Jan 2010) $

% Create the window and main layout
f = figure( 'Name', 'Dockable GUI example', ...'
    'NumberTitle', 'off', ...
    'Toolbar', 'none', ...
    'MenuBar', 'none' );
b = uiextras.HBox( 'Parent', f );

% Add three panels to the box
p{1} = uiextras.BoxPanel( 'Title', 'Panel 1', ...
    'DockFcn', {@nDock, 1}, ...
    'Parent', b );
p{2} = uiextras.BoxPanel( 'Title', 'Panel 2', ...
    'DockFcn', {@nDock, 2}, ...
    'Parent', b );
p{3} = uiextras.BoxPanel( 'Title', 'Panel 3', ...
    'DockFcn', {@nDock, 3}, ...
    'Parent', b );

% Add some contents
uicontrol( 'Style', 'PushButton', 'String', 'Button 1', 'Parent', p{1} );
uicontrol( 'Style', 'PushButton', 'String', 'Button 2', 'Parent', p{2} );
uicontrol( 'Style', 'PushButton', 'String', 'Button 3', 'Parent', p{3} );

% Set the dock/undock callback
set( p{1}, 'DockFcn', {@nDock, 1} );
set( p{2}, 'DockFcn', {@nDock, 2} );
set( p{3}, 'DockFcn', {@nDock, 3} );

%-------------------------------------------------------------------------%
    function nDock( src, evt, whichpanel ) %#ok<INUSL>
        % Set the flag
        p{whichpanel}.IsDocked = ~p{whichpanel}.IsDocked;
        if p{whichpanel}.IsDocked
            % Put it back into the layout
            newfig = get( p{whichpanel}, 'Parent' );
            set( p{whichpanel}, 'Parent', b );
            delete( newfig );
        else
            % Take it out of the layout
            pos = getpixelposition( p{whichpanel} );
            newfig = figure( ...
                'Name', get( p{whichpanel}, 'Title' ), ...
                'NumberTitle', 'off', ...
                'MenuBar', 'none', ...
                'Toolbar', 'none', ...
                'CloseRequestFcn', {@nDock, whichpanel} );
            figpos = get( newfig, 'Position' );
            set( newfig, 'Position', [figpos(1,1:2), pos(1,3:4)] );
            set( p{whichpanel}, 'Parent', newfig, ...
                'Units', 'Normalized', ...
                'Position', [0 0 1 1] );
        end
    end % nDock

end % Main function
