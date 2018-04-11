function minimizeexample()
%MINIMIZEEXAMPLE: An example of using the panelbox minimize/maximize

%   Copyright 2007-2009 The MathWorks Ltd.
%   $Revision: 113 $    $Date: 2010-01-05 17:48:39 +0000 (Tue, 05 Jan 2010) $

width = 200;
pheightmin = 20;
pheightmax = 100;

% Create the window and main layout
f = figure( 'Name', 'Collapsable GUI', ...'
    'NumberTitle', 'off', ...
    'Toolbar', 'none', ...
    'MenuBar', 'none' );
b = uiextras.VBox( 'Parent', f );

p{1} = uiextras.BoxPanel( 'Title', 'Panel 1', 'Parent', b );
p{2} = uiextras.BoxPanel( 'Title', 'Panel 2', 'Parent', b );
p{3} = uiextras.BoxPanel( 'Title', 'Panel 3', 'Parent', b );
set( b, 'Sizes', pheightmax*ones(1,3) );

% Add some contents
uicontrol( 'Style', 'PushButton', 'String', 'Button 1', 'Parent', p{1} );
uicontrol( 'Style', 'PushButton', 'String', 'Button 2', 'Parent', p{2} );
uicontrol( 'Style', 'PushButton', 'String', 'Button 3', 'Parent', p{3} );

% Resize the window
pos = get( f, 'Position' );
set( f, 'Position', [pos(1,1:2),width,sum(b.Sizes)] );

% Hook up the minimize callback
set( p{1}, 'MinimizeFcn', {@nMinimize, 1} );
set( p{2}, 'MinimizeFcn', {@nMinimize, 2} );
set( p{3}, 'MinimizeFcn', {@nMinimize, 3} );

%-------------------------------------------------------------------------%
    function nMinimize( src, evt, whichpanel ) %#ok<INUSL>
        % A panel has been maximized/minimized
        s = get(b,'Sizes');
        pos = get( f, 'Position' );
        p{whichpanel}.IsMinimized = ~p{whichpanel}.IsMinimized;
        if p{whichpanel}.IsMinimized
            s(whichpanel) = pheightmin;
        else
            s(whichpanel) = pheightmax;
        end
        set(b,'Sizes',s);
        
        % Resize the figure, keeping the top stationary
        delta_height = pos(1,4) - sum(b.Sizes);
        set( f, 'Position', pos(1,:) + [0 delta_height 0 -delta_height] );
    end % nMinimize

end % EOF
