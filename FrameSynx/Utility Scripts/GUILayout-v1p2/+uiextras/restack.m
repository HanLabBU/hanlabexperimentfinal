function restack( obj, position )
%restack  raise or lower a user-interface element with respect to its peers
%
%   restack(obj,'top') raises the specified object to the top of the stack.
%
%   restack(obj,'bottom') lowers the specified object to the bottom of the
%   stack.
%
%   restack(obj,'raise') raises the specified object one position.
%
%   restack(obj,'lower') lowers the specified object one position.

%  Copyright 2009 The MathWorks, Inc.
%  $Revision: 199 $ $Date: 2010-06-18 15:55:16 +0100 (Fri, 18 Jun 2010) $


parent = get( obj, 'Parent' );
ch = get( parent, 'Children' );
if numel(ch)>1
    switch upper( position )
        case 'TOP'
            ch = [obj;ch(ch~=obj)];
            
        case 'BOTTOM'
            ch = [ch(ch~=obj);obj];
            
        otherwise
            error( 'restack:UnknownPosition', 'Position must be one of: ''top'', ''bottom'', ''raise'', ''lower''' );
    end
    set( parent, 'Children', ch );
end
