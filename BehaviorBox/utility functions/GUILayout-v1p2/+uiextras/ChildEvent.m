classdef ChildEvent < event.EventData
    %ChildEvent  Event data for a container child change
    %
    %   uiextras.ChildEvent(child,childindex) creates some new
    %   eventdata indicating which child was changed.
    
    %   Copyright 2009 The MathWorks, Inc.
    %   $Revision: 199 $  $Date: 2010-06-18 15:55:16 +0100 (Fri, 18 Jun 2010) $
    
    properties (SetAccess='private')
        Child
        ChildIndex
    end
    
    methods
        function data = ChildEvent(child,childindex)
            error( nargchk( 2, 2, nargin ) );
            data.Child = child;
            data.ChildIndex = childindex;
        end
    end
end
